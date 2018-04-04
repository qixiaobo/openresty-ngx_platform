--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:code_check.lua
--	version: 0.1 程序结构初始化实现
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  用于验证用户的验证码,主要包括手机验证码, 随机验证码
--]]

local cjson = require "cjson"
local uuid_help = require "common.uuid_help"
local api_help = require "common.api_data_help"
local random_help = require "common.random_help"
local redis_help = require "common.db.redis_help"
local redis_help = require("common.db.redis_help")
local messages_dao = require "messages.model.messages_dao"

local CHECK_AUTH_PRE = "check_auth_code_"
--[[
	https://www.zhengsutec.com/messages/api/code_check.do?phone_number=13851737717&area_code=0086&check_code=888888
	curl 127.0.0.1/messages/api/get_message.do?phone_number=13851737717&area_code=0086&check_code=888888 
-- ]]

--[[
	@brief：获取唯一auth_code
	@param：	[_key_] redis键
	@return：false 获取失败  true 获取成功,同时返回对应key的值
]]
local function get_user_auth_code( _key_ )
	if not _key_ or _key_ == "" then 
		return false
	end

	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        -- 返回失败
        return false; 
    end

    local key  = CHECK_AUTH_PRE.._key_

	local res = redis_cli:get(key)
	if not res then
		return false
	end

	return true, res

end

--[[
	@url:	
			http://ip:port/messages/api/code_check.do
	@example: 
			curl -H "Content-Type:application/json" -X POST -d '{"auth_code":"FSgUHkrz6BqHNLai69xBN2", "email" : "652493771@qq.com", "check_code" : "435370"}'  http://localhost/messages/api/code_check.do?email=652493771@qq.com
	@brief:	验证码验证
	@param:	
			[email] 邮箱账号
			[phone_number] 手机号
			[area_code]	区号
			[check_code] 验证码
			[auth_code] 认证码，有验证码获取接口返回
	@return:
			json格式的消息
			example:
			{
				"code" : 200, 
				"data" ："xxxxx", 
				"msg" : "验证成功"
			}	
]]
if ngx.var.request_method == "POST" then
	--读取post参数
	ngx.req.read_body()
	local json_data = ngx.req.get_body_data()
	local data_tbl = cjson.decode(json_data)

	-- 邮箱验证
	local email = data_tbl["email"] 
	local check_code = data_tbl["check_code"]
	local phone_number = data_tbl["phone_number"]
	local area_code = data_tbl["area_code"]
	if not area_code then area_code = "0086" end

	local auth_code = data_tbl["auth_code"]
	if not auth_code or auth_code == "" then
		ngx.say(api_help.new_failed("[auth_code]:认证码不能为空."))
		return
	end

	if not check_code then 
		ngx.say(api_help.new_failed("验证码,不能为空."))
		return
	end

	if not phone_number and not email then 
		ngx.say(api_help.new_failed("手机号和邮箱不能都为空."))
		return
	end

	if email then 
	  	local ok, user_auth_code = get_user_auth_code(email)
	  	if not ok then
	  		return ngx.say(api_help.new(ZS_ERROR_CODE.RE_FAILED, "验证码已经失效,请重新获取验证码."))
	  	else
	  		if user_auth_code ~= auth_code then
	  			return ngx.say(api_help.new(ZS_ERROR_CODE.RE_FAILED, "auth_code is wrong!"))
	  		end
	  	end

		local result = messages_dao.check_msg_code(email, check_code)
		if result then
			ngx.say(api_help.new_success("邮箱验证码正确."))
		else
			ngx.say(api_help.new_failed("邮箱验证码错误."))
		end

		return  
	end

	-- 获得短信息包含一下几类信息
	-- 1 短信信息
	-- 2 随机验证码信息
	local ok, user_auth_code = get_user_auth_code(area_code..phone_number)
	if not ok then
		return ngx.say(api_help.new(ZS_ERROR_CODE.RE_FAILED, "验证码已经失效,请重新获取验证码."))
	else
		if user_auth_code ~= auth_code then
			return ngx.say(api_help.new(ZS_ERROR_CODE.RE_FAILED, "认证码错误,请检查认证码."))
		end
	end
	
	local result = messages_dao.check_msg_code(area_code..phone_number, check_code)
	if result then
		local token = uuid_help:get64()
		ngx.header["Token"] = token
	
		local redis_cli = redis_help:new()
		if not redis_cli then
			ngx.say(api_help.new(ZS_ERROR_CODE.RE_FAILED, "系统错误", "redis new failed"))
			return nil; 
		end
		redis_cli:set(token, "verification-code")
		ngx.log(ngx.ERR, "\n\n=====>>> " .. token)
		
		redis_cli:expire(token, 30)
		ngx.log(ngx.ERR, "=====> 手机短信码正确.")
		ngx.say(api_help.new_success("手机短信码正确."))
	else
		ngx.log(ngx.ERR, "=====> 手机短信码错误.")
		ngx.say(api_help.new_failed("手机短信码错误."))
	end
else
	ngx.say(api_help.new_failed())
	return 
end
 