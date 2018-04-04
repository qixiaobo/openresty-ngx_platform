--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:alipay_game_notify.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  支付宝调用回调信息
--]]
 
local request_help = require "common.request_help"
local cjson = require "cjson"
local aes = require "common.crypto.aes"
local rsa = require "common.crypto.rsa"
local sign_help = require "common.crypto.sign_help"
local alipay_conf = require "pay.alipay.alipay_conf"
local redis_help = require "common.db.redis_help" 
local game_account_tf_dao = require "game.model.game_account_tf_dao"
local mail_dao = require "messages.model.mail_dao"


local args = request_help.get_all_args()
ngx.log(ngx.ERR,'--------充值回调-开始-------',cjson.encode(args))

--[[
WAIT_BUYER_PAY	交易创建，等待买家付款
TRADE_CLOSED	未付款交易超时关闭，或支付完成后全额退款
TRADE_SUCCESS	交易支付成功
TRADE_FINISHED	交易结束，不可退款
]]
-- 根据交易状态进行数据库操作
if args.trade_status == "TRADE_SUCCESS" then
	--[[
1	id_pk	bigint	20	0	0			1	0	0
0	trade_no	varchar	32	0	0					0
0	trade_from_type	varchar	32	0	0		账号 类型, 主要包括 WXPAY, ALIPAY, UNIONPAY, ZSACCOUNT			0
0	trade_from_id	varchar	256	0	0					0
0	trade_to_type	varchar	32	0	0		账号 类型, 主要包括 WXPAY, ALIPAY, UNIONPAY, ZSACCOUNT		0
0	trade_to_id	varchar	256	0	0					0
0	trade_time	timestamp	0	0	0	CURRENT_TIMESTAMP	交易时间	1
0	balance	double	0	0	0			0	0
0	integral	double	0	0	0			0	0
0	order_no	varchar	256	0	0		订单信息,可能是系统的订单,也可能是用户第三方的订单记录,未来优化			0
0	initiate_time	datetime	0	0	1		发起时间
0	pay_time	datetime	0	0	1		支付时间
0	finish_time	datetime	0	0	1		结束时间 失败或成功等都可以
0	trade_status	varchar	32	0	0		交易状态,  交易等待付款 WAIT_BUYER_PAY , 交易关闭 TRADE_CLOSED,  交易成功 TRADE_SUCCESS, 交易结束 TRADE_FINISHED 等不同状态码			0
]]

	-- 数据写入redis 缓冲池或者写入数据库 本版本,写入redis


	-- 
	-- 订单功能
	local out_trade_no = args.out_trade_no

	local redis_cli = redis_help:new();  
    if not redis_cli then 
 		ngx.log(ngx.ERR,cjson.encode(args))
    	return 
    end

	local res,err = redis_cli:hset(PRE_PAY_CODE, args.trade_no, cjson.encode(args))
	if not res then
    	 ngx.log(ngx.ERR,"------ redis hset error, PRE_PAY_CODE ",PRE_PAY_CODE ,", mapkey:",args.trade_no, " ", cjson.encode(args)); 
    	 return 
    end

	local res,err = redis_cli:hget(PRE_PAY_CODE..out_trade_no,"USER_CODE")
    if not res then
    	 ngx.log(ngx.ERR,"------ redis hget error",PRE_PAY_CODE..out_trade_no," ",cjson.encode(args)); 
    end
   	local trade_to_id = res

	-- 生成交易流水 
	local trade_tf = {
		trade_no = args.out_trade_no,
		-- WXPAY, ALIPAY, UNIONPAY, ZSACCOUNT	
		trade_from_type = "ALIPAY",
		trade_from_id = args.buyer_id,
		trade_from_amount = args.receipt_amount,
		-- trade_to_amount_type = "ZSB",

		trade_to_type = "ZSACCOUNT" ,
		trade_to_id = trade_to_id,		-- 用户端id
		trade_to_amount = args.receipt_amount*10,
		trade_to_amount_type = "ZSB",
		
		order_no = args.trade_no,
		pay_time = args.gmt_payment,
		trade_status = "TRADE_SUCCESS", 
	}


	local res = game_account_tf_dao.recharge_user_account_tf(trade_tf)

	local _mail = {
			user_code_fk = trade_to_id,
			mail_time = os.date("%Y-%m-%d %H:%M:%S", os.time()),
			 
			content = string.format("充值成功,充值金额:%d, 获得砖石: 个.",args.receipt_amount, args.receipt_amount*10),
			is_readed = 0,
		}
		
	-- local res_mail = mail_dao.add_mail(_mail)
	ngx.log(ngx.ERR,'--------充值回调--------',cjson.encode(trade_tf),cjson.encode(_mail))
	if res then
		-- 通知用户价格修改了
		local _process = {process_type=0x1e,sub_type=0x08,data=_mail}
		_process.data.balance_changed = args.receipt_amount 
		redis_cli:publish(ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR..trade_to_id,
			cjson.encode(_process))
		ngx.log(ngx.ERR,'--------充值回调--------写入成功!!!!!')
		ngx.say("success")
		ngx.eof()


		local res,err = redis_cli:hdel(PRE_PAY_CODE, args.trade_no)
		if not res then
	    	 ngx.log(ngx.ERR,"------ redis del error, PRE_PAY_CODE ",PRE_PAY_CODE ,", mapkey:",args.trade_no, " ", cjson.encode(args)); 
	    	 return 
	    end
	end

end

-- ngx.say("success")
-- ngx.eof()

-- 后续继续执行业务处理 

-- 需要获得当前调用的信息属于什么产品应用,pc, 手机, 或app支付的发起
--[[
{"gmt_create":"2017-12-17 10:58:16",
"sign":"A9Q3ksDbzir+VKPZuieagODQr\/uuC3EuCswAiS1b3oBVUfDYTjm7Uu93Q9IWhf0VboujR09c9fpIS\/wc4DVWrYgCaj2+EQqdhoE1yaiYz+HWtKJ2vqAnSzqbIOQ5604birc\/SJ7yljEhrmj17B8LBqcTqsrs9we1XSDNTBlep1EtI0vgY\/vifuSVmn3Yc5yzB+hCglGqQt4p76JzuzyhSRfIspQM8OsZZbU7hddTYc5X7RLN+Uz7DJvb6PRKr8UJQ1S9CCguG+iyPHjmhaO8mz\/WRvzxMCKZqG1MLZILukaMX5bA\/9gzGoT2yR3+g6xcSyW\/1XJArpMpMHKba9a1wA==",
"trade_status":"TRADE_SUCCESS",
"trade_no":"2017121721001004970265915559",
			201712171058105990541800008
"fund_bill_list":"[{\"amount\":\"0.10\",\"fundChannel\":\"ALIPAYACCOUNT\"}]",
"charset":"utf-8",
"auth_app_id":"2017121100557906",
"receipt_amount":"0.10",
"notify_id":"205a7ab0a9c43166092b760465958b9nhi",
"app_id":"2017121100557906",
"buyer_pay_amount":"0.10",
"buyer_id":"2088202872271975",
"out_trade_no":"201712171058105990541800008",
				201712171058105990541800008
"invoice_amount":"0.10",
"version":"1.0",
"sign_type":"RSA2",
"subject":"test",
"notify_time":"2017-12-17 10:58:21",
"gmt_payment":"2017-12-17 10:58:20",
"seller_id":"2088821127488751",
"total_amount":"0.10",
"notify_type":"trade_status_sync",
"point_amount":"0.00"
}

]]

-----------------------------------------测试---------------------------------
-- local args = [[
-- 	{"gmt_create":"2017-12-17 10:58:16",
-- "sign":"A9Q3ksDbzir+VKPZuieagODQr\/uuC3EuCswAiS1b3oBVUfDYTjm7Uu93Q9IWhf0VboujR09c9fpIS\/wc4DVWrYgCaj2+EQqdhoE1yaiYz+HWtKJ2vqAnSzqbIOQ5604birc\/SJ7yljEhrmj17B8LBqcTqsrs9we1XSDNTBlep1EtI0vgY\/vifuSVmn3Yc5yzB+hCglGqQt4p76JzuzyhSRfIspQM8OsZZbU7hddTYc5X7RLN+Uz7DJvb6PRKr8UJQ1S9CCguG+iyPHjmhaO8mz\/WRvzxMCKZqG1MLZILukaMX5bA\/9gzGoT2yR3+g6xcSyW\/1XJArpMpMHKba9a1wA==",
-- "trade_status":"TRADE_SUCCESS",
-- "trade_no":"2017121721001004970265915559", 
-- "fund_bill_list":"[{\"amount\":\"0.10\",\"fundChannel\":\"ALIPAYACCOUNT\"}]",
-- "charset":"utf-8",
-- "auth_app_id":"2017121100557906",
-- "receipt_amount":"0.10",
-- "notify_id":"205a7ab0a9c43166092b760465958b9nhi",
-- "app_id":"2017121100557906",
-- "buyer_pay_amount":"0.10",
-- "buyer_id":"2088202872271975",
-- "out_trade_no":"201712171058105990541800008", 
-- "invoice_amount":"0.10",
-- "version":"1.0",
-- "sign_type":"RSA2",
-- "subject":"test",
-- "notify_time":"2017-12-17 10:58:21",
-- "gmt_payment":"2017-12-17 10:58:20",
-- "seller_id":"2088821127488751",
-- "total_amount":"0.10",
-- "notify_type":"trade_status_sync",
-- "point_amount":"0.00"}
-- ]]
-- local args = cjson.decode(args)
ngx.log(ngx.ERR,'--------充值回调-验证开始-------',cjson.encode(args))
local signed_str_ali = ngx.decode_base64(args.sign)
-- ngx.say(signed_str_ali)
args.sign = nil
args.sign_type = nil
-- 生成充值记录写入数据库
-- 验证是否正确 
local sort_str = sign_help.make_sign_str_sort(args)  
local algorithm = "SHA256" 
-- local public_cli =  rsa:new_rsa_public(alipay_conf.ALIPAY_PUBLIC_KEY, algorithm)
local res = sign_help.rsa_verify(sort_str, signed_str_ali, alipay_conf.ALIPAY_PUBLIC_KEY, algorithm)
if not res then
	ngx.log(ngx.ERR,'--------充值回调-验证失败-------',sort_str )
	return
end



ngx.log(ngx.ERR,'--------充值回调-结束-------')








