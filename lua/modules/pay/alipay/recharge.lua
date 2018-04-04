--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名: recharge.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  充值接口封装,充值包括支付宝,微信,银联等各种支付方式
--]]
local cjson = require "cjson"
local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help"
local incr_help = require "common.incr_help"
local uuid_help = require "common.uuid_help"
local time_help = require "common.time_help"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help" 
local db_json_help = require "common.db.db_json_help"


local alipay_conf = require "pay.alipay.alipay_conf"
local alipay = require "pay.alipay.alipay"

 
--[[
    用户端发起的支付宝的pc端支付,该支付主要包括
    example: 必须携带的信息包括包括充值主题,充值内容,购买金额
    http://127.0.0.1/pay/recharge/recharge_ali_pc.action?amount=0.01&subject=test&return_url=&user_code=xxxx&auth_token=xxxx

]]
	local args = request_help.get_all_args()
	-- 参数查询与判断
	local amount = args["amount"]
	local subject = args["subject"]
	local return_url = args["return_url"]
	local user_code = args["user_code"]
	local auth_token = args["auth_token"]
	local pay_type = args["pay_type"]
	
	if not user_code then 
		ngx.say("user_code is nil")
		return 
	end

	if not amount or not subject or not return_url then 
		return api_data_help.new_failed("one of [amount subject return_url] is nil!!!")
	end
	local res, amount_temp = pcall(tonumber,amount) 
	if not res then 

		return api_data_help.new_failed("amount type is error!!!")
	end

	local biz_content = { 
	    subject=subject,
	    out_trade_no = incr_help.get_time_union_id(), -- "416778275344486400", 交易订单号,
	    total_amount = amount_temp,  
	}

 	local domain_url = request_help.get_domain_url() 

	local pay_data = { 
	    -- sign = "",   
	    biz_content = biz_content, 
	    app_id = alipay_conf.APPID, 
	    notify_url = domain_url..alipay_conf.NOTIFY_URL, -- 异步通知地址
	    return_url = return_url,						 -- 返回地址
	}   
 
	-- 生成用户支付信息 记录
	local alipay1 = alipay:new(pay_data,pay_type,alipay_conf.RSA_PRIVATE_KEY)  

	--[[
	为了减少数据库被攻击或者数据库压力, 
		用户发起充值,系统生成充值订单,写入redis缓存或其他缓存服务器
		在系统收到回调之后, 为用户添加金额,同时将记录写入数据库
		获取订单系
	]]
	-- 订单功能
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,"------ redis new error",PRE_PAY_CODE..pay_data.biz_content.out_trade_no,cjson.encode(pay_data));
    else
    	local res,err = redis_cli:hmset(PRE_PAY_CODE..pay_data.biz_content.out_trade_no,"USER_CODE",user_code,"DETAILS",cjson.encode(pay_data) )
	    if not res then
	    	 ngx.log(ngx.ERR,"------ redis set error",PRE_PAY_CODE..pay_data.biz_content.out_trade_no,cjson.encode(pay_data));
	    end
	   	
    end 
 
    if pay_type == "ALIPAY_PC" or pay_type == "ALIPAY_WAP" then
    	alipay1:redirect2alipay()
	else

	end


	-- -- 生成用户支付信息 记录
	-- local alipay = alipay_wap:new(pay_data,alipay_conf.RSA_PRIVATE_KEY)  

	-- --[[
	-- 为了减少数据库被攻击或者数据库压力, 
	-- 	用户发起充值,系统生成充值订单,写入redis缓存或其他缓存服务器
	-- 	在系统收到回调之后, 为用户添加金额,同时将记录写入数据库
	-- 	获取订单系
	-- ]]
	-- -- 订单功能
	-- local redis_cli = redis_help:new();
 --    if not redis_cli then
 --        ngx.log(ngx.ERR,"------ redis new error",PRE_PAY_CODE..pay_data.biz_content.out_trade_no,cjson.encode(pay_data));
 --    else
 --    	local res,err = redis_cli:hmset(PRE_PAY_CODE..pay_data.biz_content.out_trade_no,"USER_CODE",user_code,"DETAILS",cjson.encode(pay_data) )
	--     if not res then
	--     	 ngx.log(ngx.ERR,"------ redis set error",PRE_PAY_CODE..pay_data.biz_content.out_trade_no,cjson.encode(pay_data));
	--     end
	   	
 --    end 
 

 --    alipay:redirect2alipay()
  
