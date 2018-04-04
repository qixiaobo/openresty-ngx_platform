--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:wechat_pay.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  微信支付调用接口,用户访问该页面,系统通过微信回调产生二维码数据,订单等各种数据

--]]

local lub    = require 'lub'
local lut    = require 'lut'
local xml    = require 'xml'
local cjson = require "cjson"
local incr_help = require "common.incr_help"   
local uuid_help = require "common.uuid_help"
local rapidxml_help = require "common.rapidxml_help"
local sign_help = require "common.crypto.sign_help"
local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help"
local redis_help = require "common.db.redis_help" 


local wx_pay = require "pay.wx.wx_pay"

local log = ngx.log
local ERR = ngx.ERR
local ngx_time = ngx.time
local ngx_md5 = ngx.md5
local string_upper = string.upper



local args = request_help.get_all_args()
	-- 参数查询与判断
local amount = args["amount"]
local subject = args["subject"]
local return_url = args["return_url"]
local user_code = args["user_code"]
local auth_token = args["auth_token"]
local trade_type = args["trade_type"]  -- JSAPI NATIVE APP MWEB

	
 

if not user_code or not amount or not subject or not return_url then 
	return api_data_help.new_failed("one of [user_code amount subject return_url] is nil!!!")
end
local res, amount_temp = pcall(tonumber,amount) 
if not res then 
	return api_data_help.new_failed("amount type is error!!!")
end

 	-- app id
local	appid = "wx63e89f7c5e560d67" 

-- 商家 id
local	mch_id = "1496204352" 
   
local private_key = "n4psYrKRVyK5R25Yvyf0OG6ozPXS32wB"


-- 通知地址
local	notify_url = "http://goodtime.vip/pay/wx/wechat_pay_cb.do" 

-- 商户订单号
local	out_trade_no = incr_help.get_uuid() 

-- 标价金额
local	total_fee = tostring(amount_temp)
   
local	scene_info = nil
if trade_type == "MWEB" or trade_type == "WEB" then
	scene_info = string.format('{"h5_info":{"type":"Wap","wap_url":"http://goodtime.vip","wap_name":"充值"}}')
end

local wechat_pay = wx_pay:new(appid,mch_id,private_key,
							subject,out_trade_no,total_fee,
							notify_url,trade_type,scene_info)

local wap_res = wechat_pay:make_undefine_order()




local pay_data = { 
	    -- sign = "	",   
	    out_trade_no = out_trade_no, 
	    amount = total_fee, 
	    trade_type = trade_type,
	    
	}   

local redis_cli = redis_help:new();
if not redis_cli then
    ngx.log(ngx.ERR,"------ redis new error",PRE_PAY_CODE..out_trade_no,cjson.encode(pay_data));
	return nil
else
	local res,err = redis_cli:hmset(PRE_PAY_CODE..out_trade_no, "USER_CODE", user_code, "DETAILS",cjson.encode(pay_data) )
    if not res then
    	 ngx.log(ngx.ERR,"------ redis set error",PRE_PAY_CODE..out_trade_no, cjson.encode(pay_data));
    	return nil
    end
end 
ngx.log(ngx.ERR,"-----------",wap_res)
ngx.say(wap_res)


-- local sign = require "admin.auth.sign_in"
-- 	local cjson  = require "cjson"  
-- 	local template = require "resty.template"
-- 	template.render("demo/wechat_pay.html", {  mweb_url = wap_res })

-- ngx.say(wap_res)

-- -- 数据写入数据库,支付成功进行数据处理
-- --[[
-- 	为了减少数据库被攻击或者数据库压力, 
-- 		用户发起充值,系统生成充值订单,写入redis缓存或其他缓存服务器
-- 		在系统收到回调之后, 为用户添加金额,同时将记录写入数据库
-- 		获取订单系
-- ]]
-- 订单功能

	-- ngx.log(ngx.ERR,"------进入充值重定向--------------- ", cjson.encode(pay_data));
 