--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:get_identifying_code.lua
--	version: 0.1 程序结构初始化实现
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  用于验证用户的验证码, 随机验证码生成,验证
--  系统验证验证码, 该验证码验证需要上传 user_identity_token user_identity_code 两个字段
-- 	其中 user_identity_token 来源于系统get_identifying_code.do 头信息中所携带的对应token
--]]
	
local cjson = require "cjson"
local messages = require "messages.model.messages_dao"
local messages_temp = require "messages.model.messages_temp"
local random_help = require "common.random_help"
local api_help = require "common.api_data_help"
local redis_help = require "common.db.redis_help"
local uuid_help = require "common.uuid_help"

--[[
	
]]

local args = ngx.req.get_uri_args()

local user_identity_token = ngx.req.get_headers()['User-Identity-Token']
user_identity_token = args["User-Identity-Token"]
local user_identity_code = args["user_identity_code"]

ngx.log(ngx.ERR, "=====> 检查验证码:[", user_identity_code, "], User-Identity-Token:", user_identity_token)
 
-- 包含头信息并且包含验证码,平台进行判断响应
if  not user_identity_code and not user_identity_token then
	--  ngx.say(api_help.new(ZS_ERROR_CODE. '参数不正确,请检查参数'))
	ngx.say(api_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "参数[user_identity_code]或[User-Identity-Token]未设置"))
	return nil
end


-- 用户随机验证码存放在 redis 缓存中
local redis_cli = redis_help:new();
if not redis_cli then
	-- ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
	-- 返回失败
	-- ngx.say(api_help.new_failed())
	-- ngx.log(ngx.ERR, "=====> REDIS 异常")
	ngx.say(api_data_help.new(ZS_ERROR_CODE.REDIS_NEW_ERR, "连接REDIS异常"));
	return nil; 
end

local identity_code = redis_cli:get(user_identity_token)

if not identity_code then
	ngx.say(api_help.new(ZS_ERROR_CODE.PARAM_PATTERN_ERR, "验证码错误：系统不存在该验证"))
elseif string.upper(identity_code)   == string.upper(user_identity_code) then
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


	ngx.say(api_help.new(ZS_ERROR_CODE.RE_SUCCESS, "验证码正确"))
else
	ngx.say(api_help.new(ZS_ERROR_CODE.PARAM_PATTERN_ERR, "验证码不匹配"))
end 
