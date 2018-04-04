--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_account.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  查询用户账户信息, 
--]]
local lub    = require 'lub'
local lut    = require 'lut'
local xml    = require 'xml'
local cjson = require "cjson"
local request_help = require "common.request_help" 
local rapidxml_help = require "common.rapidxml_help"
local redis_help = require "common.db.redis_help" 
local game_account_tf_dao = require "game.model.game_account_tf_dao"
local mail_dao = require "messages.model.mail_dao"


  ngx.req.read_body() 
local post_data = ngx.req.get_body_data()

ngx.log(ngx.ERR,"wechat pay result:",post_data)
-- 获得xml解析

-- <xml><appid><![CDATA[wx63e89f7c5e560d67]]></appid>
-- <bank_type><![CDATA[BOC_DEBIT]]></bank_type>
-- <cash_fee><![CDATA[1]]></cash_fee>
-- <fee_type><![CDATA[CNY]]></fee_type>
-- <is_subscribe><![CDATA[N]]></is_subscribe>
-- <mch_id><![CDATA[1496204352]]></mch_id>
-- <nonce_str><![CDATA[HwEsfrCQfhnKQZMy5u8eO2]]></nonce_str>
-- <openid><![CDATA[odm5G1Lc5Lc9d2HVo14YANJ0-sNc]]></openid>
-- <out_trade_no><![CDATA[434065722457460736]]></out_trade_no>
-- <result_code><![CDATA[SUCCESS]]></result_code>
-- <return_code><![CDATA[SUCCESS]]></return_code>
-- <sign><![CDATA[A08C9B57D19B6759A6E895A82ED6099F]]></sign>
-- <time_end><![CDATA[20180130180230]]></time_end>
-- <total_fee>1</total_fee>
-- <trade_type><![CDATA[MWEB]]></trade_type>
-- <transaction_id><![CDATA[4200000095201801303765308493]]></transaction_id>
-- </xml>

local xmlimpl = rapidxml_help:new(post_data)  
local result_code = xmlimpl:get_key("result_code")

if result_code ~= "SUCCESS"  then
	return 
end
local return_code = xmlimpl:get_key("return_code")

if return_code ~= "SUCCESS"  then
	return 
end

local appid = xmlimpl:get_key("appid")
local fee_type = xmlimpl:get_key("fee_type")
local mch_id = xmlimpl:get_key("mch_id")
local openid = xmlimpl:get_key("openid")
local trade_type = xmlimpl:get_key("trade_type")
local bank_type = xmlimpl:get_key("bank_type")
local total_fee = tonumber(xmlimpl:get_key("total_fee"))
local out_trade_no = xmlimpl:get_key("out_trade_no")
local nonce_str = xmlimpl:get_key("nonce_str")
local transaction_id = xmlimpl:get_key("transaction_id")
-- transaction_id
 

	local redis_cli = redis_help:new();  
    if not redis_cli then 
 		ngx.log(ngx.ERR, post_data)
    	return 
    end  

	local res,err = redis_cli:hget(PRE_PAY_CODE..out_trade_no,"USER_CODE")
    if not res then
    	 ngx.log(ngx.ERR,"------ redis hget error",PRE_PAY_CODE..out_trade_no," 金额",total_fee/100); 
    end
   	local trade_to_id = res

	-- 生成交易流水 
	local trade_tf = {
		trade_no = out_trade_no,
		-- WXPAY, ALIPAY, UNIONPAY, ZSACCOUNT	
		order_type="微信充值",
		trade_from_type = "WXPAY",
		trade_from_id = openid,
		trade_from_amount = total_fee/100,

		trade_to_type = "ZSACCOUNT" ,
		trade_to_id = trade_to_id,		-- 用户端id
		trade_to_amount = total_fee/10,
		trade_to_amount_type = "ZSB", 

		order_no = transaction_id,
		pay_time = ngx.localtime(),
		trade_status = "TRADE_SUCCESS", 
	}

	local res = game_account_tf_dao.recharge_user_account_tf(trade_tf)

	local _mail = {
			user_code_fk = trade_to_id,
			mail_time = os.date("%Y-%m-%d %H:%M:%S", os.time()),
			 
			content = string.format("充值成功,充值金额:%d, 获得砖石: 个.",total_fee/100, total_fee/10),
			is_readed = 0
		}
		
	local res_mail = mail_dao.add_mail(_mail)

	if res then
		-- 通知用户价格修改了
		local _process = {process_type=0x1e,sub_type=0x08,data=_mail}
		_process.data.amount = total_fee/10,
		redis_cli:publish(ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR..trade_to_id,
			cjson.encode(_process))

	
		ngx.say("<xml><return_code><![CDATA[SUCCESS]]></return_code><return_msg><![CDATA[OK]]></return_msg></xml>") 
		ngx.eof()

		local res,err = redis_cli:hdel(PRE_PAY_CODE, out_trade_no)
		if not res then
	    	 ngx.log(ngx.ERR,"------ redis del error, PRE_PAY_CODE ",PRE_PAY_CODE ,", mapkey:",out_trade_no, " ", cjson.encode(_process)); 
	    	 return 
	    end
	end