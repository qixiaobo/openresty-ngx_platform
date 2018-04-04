--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:get_phone_code.lua
--	version: 0.1 程序结构初始化实现
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  获得获得验证码,获得短信验证码,以及其他相关判断,验证码相关存尽量存放于共享内存中
--  短信获取需要获取当前请求的msgtoken信息,该信息由系统生成携带,客户端需要将该信息返回给服务器
--  phone_number,area_code,msg_token,msg_temp
--]]

-- TEST

local cjson = require "cjson" 
local http = require "resty.http"
local uuid_help = require "common.uuid_help"
local random_help = require "common.random_help"
local redis_help = require("common.db.redis_help")
local api_data_help = require "common.api_data_help"

local messages_dao = require "messages.model.messages_dao"
local messages_temp = require "messages.model.messages_temp"

local CHECK_AUTH_PRE = "check_auth_code_"


--[[
	@brief：删除唯一token值
	@param：	_area_code 区号
			_mobile_number 手机号
	@return：nil 删除失败  true 删除成功
]]
local function delete_auth_code( _area_code, _mobile_number )
	if not _mobile_number or #_mobile_number ~= 11 then
		return nil
	end

	if not _area_code or _area_code == "" then _area_code = "0086" end

	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        -- 返回失败
        return nil; 
    end

    local phone_number_key  = CHECK_MSG_PRE.._area_code.._mobile_number

	redis_cli:del(phone_number_key)

	return true
end

--[[
	@brief：保存唯一token值，用于确保操作唯一性
	@param：	_area_code 区号
			_mobile_number 手机号
			_auth_code 唯一token值
	@return：nil 保存失败  true 保存成功
]]
local function save_auth_code( _area_code, _mobile_number, _auth_code )
	if not _auth_code or _auth_code == "" then
		return nil
	end

	if not _mobile_number or #_mobile_number ~= 11 then
		return nil
	end

	if not _area_code or _area_code == "" then _area_code = "0086" end

	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        -- 返回失败
        return nil; 
    end

    local phone_number_key  = CHECK_AUTH_PRE.._area_code.._mobile_number  

    -- local res = redis_cli:hmset(msg_token,"mobile_number",phone_number,"msg_code",_msg_code)
    
    local res = redis_cli:setnx(phone_number_key, _auth_code)
   	if not res then
        ngx.log(ngx.ERR,"------- error failed to set mobile_code: ", err)
        return nil
    end 

    if res == 0 then
        local res = redis_cli:get(phone_number_key)  
        return res, true
    end
      -- 系统验证码有效期30秒,到期自动清理
    redis_cli:expire(phone_number_key, 60*5)

    return _auth_code, nil
end

--[[
	https://www.zhengsutec.com/messages/api/get_phone_code.do?phone_number=13851737717&area_code=0086 
	curl 127.0.0.1/messages/api/get_phone_code.do?phone_number=13851737717&area_code=0086 
-- ]]

-- 获得当前是否包含指定的参数
-- 获得短信息包含一下几类信息
 -- 1 短信信息
 -- 2 随机验证码信息
--[[
	@url:	
			messages/api/get_phone_code.do
			&phone_number=19912345678
			&area_code=0086
	@example: 
			curl 127.0.0.1/messages/api/get_phone_code.do?phone_number=13851737717&area_code=0086
	@brief:	获取手机验证码
	@param:	
			[phone_number] 获取验证码的手机号
			[area_code]	区号
	@return:
			json格式的消息
			example:
			{
				"code" : 200, --状态码
				"msg" : "请求短信验证码成功: 567812", --成功、错误对应的消息
				"data" : -- json数据
						{
							"auth_code" : "asdsadasd[asdasd_sa" --auth_code，验证接口需要检测该参数 
						}
			}		
]]

local args = ngx.req.get_uri_args()
 
local phone_number = args["phone_number"]
local area_code = args["area_code"]
local auth_code = uuid_help:get64()

if not phone_number then
	ngx.say(api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "手机账号不能为空."))
	return
end

if not area_code then area_code = "0086" end

local auth_code, isSaved = save_auth_code(area_code, phone_number, tostring(auth_code))
if isSaved then
	ngx.say(api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "请求短信验证码失败,验证码已经发送，请查收短信."))
	return
end

local msg_code, isHaved = messages_dao.get_mobile_msg(area_code, phone_number, 6)


-- 失败 通知客户端,日志上传客户端
if not msg_code then
	ngx.say(api_data_help.new_failed())
	return
else

	local msg_temp =  messages_temp.get_phone_msg_temp() 
	local msg_context = string.gsub(msg_temp, "#000000", msg_code)
	ngx.log(ngx.ERR,msg_context)
--  发送短信接口调用 ----!!!!!!!!!!!!!!-----begin
--  未来需要注意短信发送问题, 短信只能发送100条,超过一百条,系统对账号进行封停

	-- local httpc = http.new()  
	
	-- local url = string.format("http://47.96.153.251:8080/com_zhengsu_manager/SendSms.tz?phone=%s&code=%s",  phone_number, msg_code)
	-- local resStr --响应结果  
	-- local res, err = httpc:request_uri(url, {  
	-- 	method = "GET",  
	-- 	-- body = str,  
	-- 	headers = { ["Content-Type"] = "application/json", }  
	-- })  

	-- if not res then  
	-- 	ngx.log(ngx.ERR,"请求短信验证码失败：", err)  
	-- 	ngx.say(api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "请求短信验证码失败："..err))
	-- 	--删除token
	-- 	delete_auth_code(area_code, phone_number)
	-- 	return  
	-- end  
	
	-- if res.status ~= 200 then  
	-- 	ngx.log(ngx.ERR,"请求返回状态异常，status="..res.status)  
	-- 	--删除token
	-- 	delete_auth_code(area_code, phone_number)

	-- 	ngx.say(api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "请求返回状态异常，status="..res.status))
	-- 	return  
	-- end  

	ngx.say(api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "请求短信验证码成功:" .. msg_code, {auth_code = tostring(auth_code)}))

 	-- 记录写入数据库 
	if not isHaved then -- 系统是否发送过短信,没有发送过写入数据库等待发送
		-- 调用发送指令进行发送 
		messages_dao.record_mobile_msg(area_code, phone_number, msg_context)
	end
	ngx.say(api_data_help.new_success(msg_context))
end
 

