local cjson = require "cjson"
local session = require "resty.session".start()

local user_dao = require "user.model.user_dao" 
local user_redis = require "user.model.user_redis"

local args = ngx.req.get_uri_args()
local user_id = args['user_id']

local function session_auth(_user_id)
	local clazz = ngx.var.clazz
	local action = ngx.var.action

	--默认session的失效时间和cookie的失效时间一样
	--session.expires = time() + session.cookie.lifetime
	--登录成功后会存在redis中
	ngx.ctx.session_id = session.id
	ngx.log(ngx.ERR,"session_id: ", ngx.ctx.session_id)
	ngx.log(ngx.ERR,"expires: ", session.expires)
	ngx.log(ngx.ERR,"lifetime: ", session.cookie.lifetime)
	ngx.log(ngx.ERR, "clazz: ", clazz and clazz or "nil")
	ngx.log(ngx.ERR, "action: ", action and action or "nil")
	ngx.log(ngx.ERR, "ip: ", ngx.var.remote_addr)

	
	if clazz and clazz == 'statistical_info' or clazz == 'channel' then
		return true
	end
	
	if clazz and clazz == 'user_auth' and action then
		if action == 'register' or action == 'login'then
			return true
		end
	end

	ngx.log(ngx.ERR, "[token_auth] request auth.")
	if not user_id or user_id == '' then
		return false, "参数错误, [user_id] 空."
	end
	ngx.log(ngx.ERR, "user_id: ", user_id)
	local res, err = user_redis.get_user_session_id(user_id)
	if not res then
		local err_str = ''
		if err then
			ngx.log(ngx.ERR, "err: ", err)
			err_str = "系统错误."
		else
			--重定向到登录页面
			err_str = "请先登录."
		end
		return false, err_str
	end

	local session_id = err
	local remote_ip = ""
	local res, err = user_redis.get_user_session_info(session_id)
	if res then
		remote_ip = err.remote_ip
	end

	ngx.log(ngx.ERR, "session_id: ", session.id)
	ngx.log(ngx.ERR, "redis session_id: ", session_id)
	if session.id ~= session_id then
		return false, ("您的账号在其他地方登录,"..(remote_ip ~= '' and " 登录IP["..remote_ip.."]," or "").." 您已经被强制下线.")
	end

	return true
end

--session auth
local res, err = session_auth(user_id)
if not res then
	local ret_tbl = {code = 400}
	ret_tbl.msg = err
	return ngx.say(cjson.encode(ret_tbl))
end
