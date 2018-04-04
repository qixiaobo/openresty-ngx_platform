--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:get_email_code.lua
--	version: 0.1 程序结构初始化实现
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  获得获得验证码,使用邮箱获取验证码
--]]

local cjson = require "cjson"
local uuid_help = require "common.uuid_help"
local api_help = require "common.api_data_help"
local random_help = require "common.random_help"
local redis_help = require("common.db.redis_help")
local api_data_help = require "common.api_data_help"

local messages_dao = require "messages.model.messages_dao"
local messages_temp = require "messages.model.messages_temp"
--[[
	https://www.zhengsutec.com/messages/api/get_message.do?mobile_number=13851737717&area_code=+86&msg_token=testtoken
	curl 127.0.0.1/messages/api/get_message.do?mobile_number=13851737717&area_code=+86&msg_token=testtoken
-- ]]

local token = uuid_help:get64()

local CHECK_AUTH_PRE = "check_auth_code_"

--[[
	@brief：
			删除唯一token值
	@param：	
			[_email:string] 邮箱账号
	@return：
			nil 删除失败  true 删除成功
]]
local function delete_auth_code( _email)
	if not _email or _email == "" then
		return nil
	end

	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        -- 返回失败
        return nil; 
    end

    local email_key  = CHECK_AUTH_PRE.._email

	redis_cli:del(email_key)

	return true
end

--[[
	@brief：
			保存唯一token值，用于确保操作唯一性
	@param：	
			[_email:string]  邮箱号
			[_auth_code:string] 系统唯一token值
	@return：
			nil 保存失败  true 保存成功
]]
local function save_auth_code( _email, _auth_code )
	if not _auth_code or _auth_code == "" then
		return nil
	end

	if not _email or _email == "" then
		return nil
	end

	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        -- 返回失败
        return nil; 
    end

    local email_key  = CHECK_AUTH_PRE.._email   

    local res = redis_cli:setnx(email_key, _auth_code)
   
    if not res then
        ngx.log(ngx.ERR,"------- error failed to set email_code: ", err)
        return nil
    end 

    if res == 0 then
        local res = redis_cli:get(email_key)  
        return res, true
    end
      -- 系统验证码有效期30秒,到期自动清理
    redis_cli:expire(email_key, 60*5)

    return _auth_code, nil
end

--[[
	@url:	
			messages/api/get_email_code.do
			&email=xx@qq.com
	@example: 
			curl 127.0.0.1/messages/api/get_email_code.do?email=xx@qq.com
	@brief:	获取邮箱验证码
	@param:	
			[email] 邮箱账号
	@return:
			json格式的消息
			example:
			{
				"code" : 200, --状态码
				"msg" : "请求邮箱验证码成功: 567812", --成功、错误对应的消息
				"data" : -- json数据
						{
							"auth_code" : "asdsadasd[asdasd_sa" --auth_code，验证接口需要检测该参数 
						}
			}		
]]
local args = ngx.req.get_uri_args()
local email = args["email"] 
if not email then 
	ngx.say(api_help.new_failed("邮箱不能为空"))
	return
end

-- 验证是否符合email规则
local regex_help = require "common.regex_help"
local res = regex_help.isEmail(email) 
if not res then 
	ngx.say(api_help.new_failed("格式不正确"))
	return 
end

-- 生成32位的唯一token, 所有的用户将进行以下数据处理
local user_identity_token = random_help.randomchar_by_len(32);

-- 头信息中不可以使用下划线,否则html端无法获取头信息
ngx.header["User-Identity-Token"] = user_identity_token

--保存token，确保操作唯一性
local auth_code, isSaved = save_auth_code(email, token)
if isSaved then
	ngx.log(ngx.ERR, "save_auth_code  auth_code: ", auth_code)
	ngx.say(api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "请求邮箱验证码失败,验证码已经发送，请查收邮件"))
	return
end

-- 生成邮箱6位唯一验证码
local msg_code, isHaved = messages_dao.get_email_msg(email, 6)
local msg_temp = messages_temp.get_email_message_temp('EMAIL_CHECK_CODE') 

-- 失败 通知客户端,日志上传客户端
if not msg_code then
	delete_auth_code(email)
	ngx.say(api_help.new(ZS_ERROR_CODE.RE_FAILED, '系统错误,验证码生成失败,请稍后再试'))
else
	--发送邮件
	local msg_context = string.gsub(msg_temp, "#000000", msg_code)
	local res, msg = messages_dao.send_email_msg(email, msg_context)
	if not res then
		delete_auth_code(email)
		ngx.log(ngx.ERR,"发送邮件失败, code: ", msg_code)
		ngx.say(api_help.new(ZS_ERROR_CODE.RE_FAILED, '发送验证码失败,请稍后再试. '..msg))
	else
		ngx.say(api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "请求邮箱验证码成功:" .. msg_code, {auth_code = tostring(token)}))
		ngx.log(ngx.ERR,"请求邮箱验证码成功, code: ", msg_code)
		-- 记录写入数据库 
		if not isHaved then -- 系统是否发送过邮件,没有发送过写入数据库等待发送
			-- 调用发送指令进行发送 
			messages_dao.record_email_msg(email, msg_context)
		end
	end
end
 

