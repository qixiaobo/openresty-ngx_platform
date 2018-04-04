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
local http = require("resty.http") 

local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help" 
local db_json_help = require "common.db.db_json_help"

local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help"
local incr_help = require "common.incr_help"   
local uuid_help = require "common.uuid_help"
local rapidxml_help = require "common.rapidxml_help"
local sign_help = require "common.crypto.sign_help"


local log = ngx.log
local ERR = ngx.ERR
local ngx_time = ngx.time
local ngx_md5 = ngx.md5
local string_upper = string.upper
 

-- 系统传递过来的数据结构为json格式

-- 微信统一下单接口
local WECHAT_UNION_URL = "https://api.mch.weixin.qq.com/pay/unifiedorder"
  


local _M = {
	
} 

_M.__index = _M

local headers=ngx.req.get_headers()
local cli_ip=headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"



--[[
-- new 创建一个创建新的微信支付, 支持app ,h5 扫码等多种环境
-- example 

-- @param  _appid 公众号id 微信支付需要绑定一个appid 一个商家账户可以绑定多个appid
-- @param  _mch_id 商户id
-- @param  _private_key  商家在后台设置的密钥 32 字节
-- @param  _body 主题内容
-- @param  _out_trade_no 交易订单号,充值的时候直接生成订单号
-- @param  _amount  对应 total_fee 字段 总额,系统默认按照主单位进行,总额与支付宝保持一致状态,故微信需要*100
-- @param  _notify_url 成功之后的回调地址
-- @param  _trade_type  交易类型  APP MWEB JSAPI 
-- @param  _scene_info  场景信息 用于h5支付   app 使用h5支付时需要
						{"h5_info": {"type":"IOS","app_name": "王者荣耀","bundle_id": "com.tencent.wzryIOS"}}
						{"h5_info": {"type":"Android","app_name": "王者荣耀","package_name": "com.tencent.tmgp.sgame"}}
						{"h5_info": {"type":"Wap","wap_url": "https://pay.qq.com","wap_name": "腾讯充值"}}
-- @param  _time_start  支付开始时间  非必需
-- @param  _time_expire  支付超时时间 费必需

-- @return 
--]] 
function _M:new( _appid, _mch_id, _private_key, _body, _out_trade_no , _amount, _notify_url, _trade_type, _scene_info, _time_start, _time_expire)
	local headers=ngx.req.get_headers()
	local cli_ip=headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"




	local post_data = {
		-- app id
		appid = _appid ,

	-- 商家 id
		mch_id = _mch_id ,

	-- 随机字符串
		nonce_str = uuid_help:get64() , 

	-- 商品描述
		body =  _body ,

	-- 商户订单号
		out_trade_no = _out_trade_no and _out_trade_no  or incr_help.get_uuid() ,

	-- 标价金额
		total_fee = tostring(tonumber(_amount)*100) ,

	-- 终端IP
		spbill_create_ip = cli_ip ,

	-- 通知地址
		notify_url = _notify_url ,
	   
	}
	-- 交易类型 JSAPI NATIVE APP MWEB
		
	if _trade_type == "NATIVE" then
		post_data.spbill_create_ip = "47.96.153.251"
	end

	if _trade_type == "MWEB" or _trade_type == "WEB" then
		if not _scene_info  then
			post_data.scene_info = '{"h5_info":{"type":"Wap","wap_url":"http://goodtime.vip","wap_name":"充值测试"}}'
		else 
			post_data.scene_info = _scene_info
		end
		post_data.trade_type = "MWEB"
	else
		post_data.trade_type = _trade_type
	end
	

	 local impl = setmetatable({ private_key = _private_key, post_data = post_data}, _M) 
	 impl.trade_type = _trade_type
	 return impl

end


--[[
	生成 xml对象函数,用于创建支付请求xml
]]
local function make_post_xml ( _lua_json )
	-- body
	local root = _lua_json
	local xmlimpl = rapidxml_help:new("<xml></xml>")  
	for k,v in pairs(root)  do 
		xmlimpl:set_key(k,tostring(v))
	end 
	return xmlimpl:save2str()
end 

--[[
-- make_undefine_order 创建预定义订单, 并且请求到微信支付服务器,根据不同的请求类型,将结果范围到客户端
-- example 


-- @return 创建xml
]]
_M.make_undefine_order = function(_self)
	_self.post_data.sign = nil


	ngx.log(ngx.ERR,"-------",cjson.encode(_self.post_data))

	local wx_pay_str = sign_help.make_sign_str_sort( _self.post_data )
	wx_pay_str = wx_pay_str.."&key=".._self.private_key
	
	local signed_str = string_upper(ngx_md5(wx_pay_str))
	_self.post_data.sign = signed_str 

	local xml_str = make_post_xml(_self.post_data) 


-- -- 获取用户的token授权信息

	local httpc = http.new() 
	local timeout = 30000

	httpc:set_timeout(timeout)  
	local res, err_ = httpc:request_uri(WECHAT_UNION_URL, {
		  method = "POST",
		  ssl_verify = false, -- 进行https访问
		  body=xml_str,
		  headers = {
		          ["Content-Type"] = "application/x-www-form-urlencoded",
		        }		
	})

	-- 返回失败, 通知前端 服务器业务块
	if not res or res.status ~= 200 then    
	    ngx.log(ngx.ERR, "wechat get code error! ", err) 
	    return   
	end
	

	ngx.log(ngx.ERR,"res.body is ",res.body)
	local xmlimpl = rapidxml_help:new(res.body)  
	local return_code = xmlimpl:get_key("return_code") 
	if not return_code or return_code ~= "SUCCESS" then
		-- 调用错误处理
		ngx.log(ngx.ERR,"return_code is error")
		return nil
	else
		local result_code =  xmlimpl:get_key("result_code")
		if not result_code or result_code ~= "SUCCESS" then
			-- 调用错误处理
			ngx.log(ngx.ERR,"result_code is error")
			return nil
		end
		local mweb_url = xmlimpl:get_key("mweb_url")
		-- 执行充值页面调用
		if _self.trade_type == "MWEB" then  -- 手机wap支付
			local redirect_url = "http://goodtime.vip/wap/index.html"
			mweb_url = mweb_url.."&redirect_url="..ngx.escape_uri(redirect_url)
		
			return mweb_url


		elseif _self.trade_type == "NATIVE" then  -- pc二维码
			return xmlimpl:get_key("code_url")
		elseif _self.trade_type == "APP" then  -- 手机支付

		elseif _self.trade_type == "JSAPI" then  -- 微信公众号小程序相关支付

		end
 
		-- Referer:http://goodtime.vip/pay/wx/wechat_pay.shtml 
	end 
 

end
  
--[[
-- check_wx_notify 测试
-- example 


-- @return 创建xml
]]
_M.check_wx_notify = function(_private_key)

end

 return _M