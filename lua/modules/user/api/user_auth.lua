--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_auth.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  用户注册, 登录, 密码修改, 
--	用户
--  用户注册支持手机, 邮箱两类进行注册; 注册邮箱,注册手机使用验证码进行注册验证
--  其他字段包括用户名, 用户密码
--]]

local cjson = require "cjson"
local db_mysql = require "common.db.db_mysql" 
--local session = require "resty.session".open()
local redis_help = require "common.db.redis_help"
local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help" 
local uuid_help = require "common.uuid_help":new(ZS_USER_NAME_SPACE)

local User = require "user.model.user"
local user_dao = require "user.model.user_dao" 
local user_redis = require "user.model.user_redis"
--local token_auth = require "user.auth.token_auth"
local message_dao = require "messages.model.messages_dao"


local _API_FUNC = {}

--[[
	@url:	user/api/user_auth/unregister.action
			?user_id=100000012
			&token=asdsda_]d[sd_,asda]
	@brief:	
			用户账号注销
	@param:	
			[user_id] 用户唯一ID
			[token] token值，登录后返回信息中包含token
	@return: 	
				{
					"code" 	: 200,
					"data" 	: "",
					"msg"	: "注销成功"
				}
]]
_API_FUNC.unregister = function ( )
	local args = ngx.req.get_uri_args()
	local user_id = args['user_id']
	local token = args['token']

	if not user_id then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR,'参数错误: [user_id]未设置.')
	end

	--检查验证token值
	local res, err = user_dao.is_keep_alived_login(user_id, token)
	if not res then
		return	api_data_help.new_failed("请重新登录. "..err)
	end

	--尝试删除redis中session信息
    local res, err = user_redis.delete_user_session(user_id)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR,'注销用户失败', err)
    end

	local res, err = user_dao.unregister(user_id)
	if not res then
		return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR,'注销用户失败', err)
	end
	return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS,'注销用户成功')
end

--[[
	@url:	user/api/user_auth/register.action
			?user_name=U100
			&password=123454321
			&phone_number=189xxxx6664
			&area_code=0086
			&email=xx@qq.com
			&recommend_user_id=1000000011
	@brief:	
			用户注册
	@param:	
			[user_name:string] 用户名
			[phone_number:string] 手机号
			[password:string]	密码
			[area_code:string]	区号
			[email:string]	邮箱账号
			[recommend_user_id:string] 推荐人用户ID
	@return: 	
				{
					"code" 	: 200,
					"data" 	: "",
					"msg"	: "注册成功"
				}
]]
_API_FUNC.register = function ()
	local args = ngx.req.get_uri_args()
	local user_name = args['user_name']
	local phone_number = args['phone_number']
	local area_code = args['area_code']
	local email = args['email']
	local recommend_user_id = args['recommend_user_id']

	if not user_name or user_name == '' then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_PATTERN_ERR, "注册失败, 用户名为必要参数.")
	end

	if (not phone_number or #phone_number ~= 11)
		and (not email or email == '') then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_PATTERN_ERR, "注册失败, 手机号和邮箱参数至少有一个.")
	end

	--检查手机号是否合法
	if phone_number then
		
	end
	
	--检查邮箱是否合法
	if email then
		-- 验证是否符合email规则
		local regex_help = require "common.regex_help"
		local res = regex_help.isEmail(email) 
		if not res then 
			return api_data_help.new(ZS_ERROR_CODE.PARAM_PATTERN_ERR, "注册失败, 邮箱格式不正确.")
		end
	end

	--检查信息是否已经注册
	local is_exist, err_code = user_dao.is_user_name_exist(user_name) 
	if not is_exist then
		if err_code then
			return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "注册失败, 系统错误.")
		end
	else
		return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "注册失败, 用户名已经注册.")
	end

	if phone_number then
		local is_exist, err_code = user_dao.is_mobile_phone_exist(phone_number) 
		if not is_exist then
			if err_code then
				return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "注册失败, 系统错误.")
			end
		else
			return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "注册失败, 手机号已经注册.")
		end
	end

	if email then
		local is_exist, err_code = user_dao.is_email_exist(email) 
		if not is_exist then
			if err_code then
				return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "注册失败, 系统错误.")
			end
		else
			return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "注册失败, 邮箱已经注册.")
		end
	end

	local tbl = {}
	tbl.user_name = user_name
	tbl.phone_number = phone_number
	tbl.email = email
	if not area_code or area_code == '' then
		tbl.area_code = '0086'
	end

	--生成唯一用户ID
	local user_id = user_dao.make_user_id()
	if not user_id then
		return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "注册失败, 系统错误，用户ID生成失败.")
	end
	tbl.user_id = user_id

	--生成94进制密码
	local password = args['password']
	--扩展：密码复杂度判断
	if not password or type(password) ~= 'string' or #password < 8 then 
		return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "注册失败, 密码设置错误,密码要求为长度大于8的字符串.")
	end
	tbl.password = user_dao.make_password(password)
	if not tbl.password or tbl.password == '' then
		return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "注册失败, 系统错误.")
	end

	--生成默认信息
	tbl.user_state = ZS_USER_STATE.NORMAL
	tbl.recommend_user_id = recommend_user_id

	--存储信息
	local ok, code, err = user_dao.register(tbl)
	if ok then
		return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "注册成功.")
	else
		return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "注册失败, "..err)
	end
end

local function third_platform_login(_login_info)
	local user_name = _login_info.agent_no..":".._login_info.user_name
	local res, err = user_dao.is_user_name_exist(user_name)
	if res then
		ngx.log(ngx.ERR, "[third_platform_login] is_user_name_exist true.")
		local res, code, err = user_dao.get_user(user_name, nil, nil, nil)
		if not res then 
			return false
		end
		if res[1] then
			return true, res[1].user_id
		else
			return false
		end
		
	else
		if err then
			ngx.log(ngx.ERR, "[third_platform_login] is_user_name_exist err.")
			return false
		end
	end

	--生成唯一用户ID
	local user_id = user_dao.make_user_id()
	if not user_id then
		ngx.log(ngx.ERR, "[third_platform_login] make_user_id err.")
		return false
	end

	local tbl = {}
	tbl.user_name = user_name
	tbl.user_id = user_id

	--生成默认信息
	if not _login_info.area_code or _login_info.area_code == '' then 
		tbl.area_code = '0086' 
	else
		tbl.area_code = _login_info.area_code
	end
	tbl.user_state = ZS_USER_STATE.NORMAL
	tbl.nick_name = _login_info.user_name
	tbl.agent_no = _login_info.agent_no

	--存储信息
	local ok, code, err = user_dao.register(tbl)
	if not ok then
		ngx.log(ngx.ERR, "[third_platform_login] register err. err: ".. err)
		return false
	end
	
	return true, user_id

end

--[[
	@url:	user/api/user_auth/login.action
				?login_name=29912345678
				&password=123456
				&login_type=normal
				&agent_no=123100912
	@brief:	
			用户登录
	@param：
			[login_name] 登录名，可以是手机、邮箱、用户名任意一个
			[password]	登录密码
			[login_type] 登录方式
	@return:
			{ 
				"code" : 200, 
				"data" : "", 
				"msg" : "登录成功." 
			}
--]]
_API_FUNC.login = function ()
	local args = ngx.req.get_uri_args()
	local login_name = args['login_name']
	local password = args['password']
	local login_type = args['login_type']
	local user_info = nil
	local session_id = ngx.ctx.session_id

	if not login_type or login_type == '' then
		login_type = 'normal'
	end

	--普通登录方式 登录名+密码
	if login_type == 'normal' then
		--检查登录名+密码，必要参数
		if not login_name or login_name == '' or not password or #password < 8 then
			return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "用户登录失败, 参数[login_name]、[password]错误.")
		end

		--94进制密码转换
		password = user_dao.make_password(password)
		if not password then
			return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "用户登录失败, 系统错误，请稍后尝试.");
		end

		local res = user_dao.get_user(login_name, login_name, login_name)
		if not res then
			return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "用户登录失败, 数据库查询异常.")
		end
		
		if not res[1] then
			return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "用户登录失败, 用户不存在.");
		end

		if #res ~= 1 then
			ngx.log(ngx.ERR, "###########用户名、手机号、邮箱存在冲突.")
			for i = 1, #res do
				ngx.log(ngx.ERR, "用户名: ", res[1].user_name)
				ngx.log(ngx.ERR, "手机号: ", res[1].phone_number)
				ngx.log(ngx.ERR, "邮箱: ", res[1].email)
			end
		end

		if res[1].password ~= password then
			return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "用户登录失败, 密码错误.")
		end

		if res[1].user_state ~= ZS_USER_STATE.NORMAL then
			return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "用户登录失败, 用户状态异常: user_state=", res[1].user_state and res[1].user_state or "nil")
		end

		user_info = res[1]

	--手机验证码登录
	elseif login_type == 'identifying_code' then
		if not login_name or login_name == ''  then
			return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "用户登录失败, 参数[login_name]错误.")
		end

		local token = args['token']
		if not token then
			return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "用户登录失败, 参数错误", "参数[token] 没有设置.")
		end

		local redis_cli = redis_help:new()
		if not redis_cli then
			return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "用户登录失败, 系统错误", "redis错误.")
		end

		local ok = redis_cli:get(token)
		if (not ok) then
			return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "用户登录失败, token已经失效, 请重新尝试.")
		end

		local res = user_dao.get_user(nil, nil, login_name)
		if not res then
			return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "用户登录失败, 系统错误.", "数据库查询异常.")
		end

		if not res[1] then
			user_info = {}
			user_info.user_id = user_dao.make_user_id()
			user_info.user_name = user_info.user_id
			user_info.phone_number = login_name
		
			local res, code, err = user_dao.register(user_info)
			if not res then
				return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "用户登录失败, 系统错误.", "数据库异常.")
			end
		else 
			user_info = res[1]
		end
	elseif login_type == 'third_platform' then
		local agent_no = args['agent_no']
		local login_info_tbl = {}
		
		login_info_tbl.user_name = login_name
		login_info_tbl.agent_no = agent_no
		local res, user_id = third_platform_login(login_info_tbl)
		if not res then
			ngx.log(ngx.ERR, "third_platform_login 用户登录失败, 系统错误.")
			return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "用户登录失败, 系统错误.");
		end

		user_info = {}
		user_info.user_id = user_id
		user_info.user_name = agent_no..":"..login_name
		user_info.agent_no = agent_no
	else
		return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "未知登录方式: "..login_type);
	end	

	--保存session_id
	ngx.log(ngx.ERR, "login, user id: ", user_info.user_id)
	ngx.log(ngx.ERR, "login, session id: ", session_id)
	if session_id then
		local res, err = user_redis.save_user_session_id(user_info.user_id, session_id)
		if not res then
			return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "用户登录失败, 系统错误, redis错误. err: "..err)
		end

		--存储登录相关的相关信息，如：远程机器IP等
		local res, err = user_redis.save_user_session_info(user_info.user_id)
		if not res then
			return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "用户登录失败, 系统错误, redis错误. err: ".. err)
		end
	end

	local user_token = uuid_help:get64()
	local res = user_dao.keep_alived_login(user_info.user_id, user_token)
	if res then 
		-- ngx.header['Set-Cookie'] = {
		-- 	string.format("FMYL_GAME_CM_TOKEN=%s;Path=/; Expires=" .. ngx.cookie_time(ngx.time() + 60*60*24*3), user_token),
		-- 	string.format("FMYL_GAME_CM_USER=%s;Path=/; Expires=" .. ngx.cookie_time(ngx.time() + 60*60*24*3), user_info.user_id)
		-- }

		user_info.token = user_token
		return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "用户登录成功", user_info) 
	end
	
	-- 用户登录失败
	return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "用户登录失败，系统错误，请稍后尝试."); 
end

--[[
	@url:	
			user/api/user_auth/is_login_keep.action
			?user_id=10000037
			&token=laSHuanSAcbq82n@nsuNU
	@param:	
			[user_id] 用户唯一ID
			[token] 登录token
	@return:
			{
				"code" : 200, 
				"data" : {}
				"msg" : "用户保持登录状态."
			} 
]]
_API_FUNC.is_login_keep = function()
	local args = ngx.req.get_uri_args()
	local user_id = args['user_id']
	local token = args['token']

	local res, msg = user_dao.is_keep_alived_login(user_id, token)
	if res then
		return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, msg, {status=res})
	else
		return	api_data_help.new_failed("请重新登录.")
	end
end

--[[
	@url:	
			user/api/user_auth/logout.action
			?user_code=10000037
			&token=laSHuanSAcbq82n@nsuNU
	@brief:	
			退出登录
	@param:	
			[user_id] 用户唯一ID
			[token] 登录token
	@return:
			{
				"code" : 200, 
				"data" : {}
				"msg" : "退出登录成功."
			} 
]]
_API_FUNC.logout = function()
	local args = ngx.req.get_uri_args()
	local user_id = args['user_id']
	local token = args['token']

	local res, msg = user_dao.is_keep_alived_login(user_id, token)
	if not res then
		return api_data_help.new_failed(msg)
	end

	local res = user_dao.logout(user_id, token) 
	if res then
		return api_data_help.new_success("退出登录成功.")
	else
		return api_data_help.new_failed("退出登录失败. 系统错误,请重新尝试.")
	end   
end

--[[
	@url:	
			user/api/user_auth/is_registered_user.action
			?user_name=xxxxx
			&email=xx@qq.com
			&phone_number=1386543xxxx
	@brief:	
			判断用户是否已经注册,判断user_name、email、phone_number任意一个是否已经注册
	@param:	
			[user_name] 用户名
			[email]	邮件账号
			[phone_number] 手机号
	@return: 	
				{	
					"code" : 200, 
					"date" : 	
								{ 
									"is_registered" = true			 
								}
					"msg" : ""
				}
]]
_API_FUNC.is_registered_user = function (  )
	local args = ngx.req.get_uri_args()	 
	if not args['user_name'] and not args['email'] and not args['phone_number'] then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, '参数[user_name]或[email]或[phone_number]未设置')
	end
	
	local sql = string.format("SELECT * FROM t_user WHERE user_name='%s' or email='%s' or phone_number='%s';",args['user_name'], args['email'], args['phone_number'])
	local res, msg = db_mysql:exec_once(sql)
	if not res then
		return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, '数据库操作异常', msg)
	end
	
	if not res[1] then 
		return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, '获取信息成功', {is_registered=false})
	else 
		return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, '获取信息成功', {is_registered=true})
	end
end

--[[
	@url:	
			user/api/user_auth/is_registered.action
	@brief:	
			判断用户名、手机号、邮箱是否已经注册
	@param:	
			[user_name] 用户名
			[email]	邮箱
			[phone_number] 手机号
	@return:	
				{	"code" : 200, 
					"date" : { 
										"user_name" : true, 
										"phone_number" : false, 
										"email" : false, 
									}
					"msg" : ""
				}
]]
_API_FUNC.is_registered = function ( )
	local args = ngx.req.get_uri_args()	 
	if not args['user_name'] and not args['email'] and not args['phone_number'] then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, '参数未设置')
	end

	local result = {}

	local email = args['email'] 
	if  email and email ~= "" then
		local is_exist, err_code = user_dao.is_email_exist(email)
		if not is_exist then
			if err_code == nil then
				result.email = false
			else
				return api_data_help.system_error()
			end
		else
			result.email = true
		end
	end

	local phone_number = args['phone_number'] 
	if  phone_number and phone_number ~= "" then
		local is_exist, err_code = user_dao.is_mobile_phone_exist(phone_number) 
		if not is_exist then
			if err_code == nil then
				result.phone_number = false
			else
				return api_data_help.system_error()
			end
		else
			result.phone_number = true
		end
	end

	local user_name = args['user_name'] 
	if user_name and user_name ~= "" then
		local is_exist, err_code = user_dao.is_user_name_exist(user_name) 
		if not is_exist then
			if err_code == nil then
				result.user_name = false
			else
				return api_data_help.system_error()
			end
		else
			result.user_name = true
		end
	end

	if not result.phone_number and result.email and result.user_name then
		return api_data_help.system_error()
	else
		return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, '获取信息成功', result)
	end
end

return _API_FUNC
