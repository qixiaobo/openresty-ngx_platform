local cjson = require "cjson"
local redis_help = require "common.db.redis_help"

local _M = {}

local ZS_USER_PRE_SESSION = "USER_SESSION_"

local function delete_session( _key )
	ngx.log(ngx.ERR, "_key: ", _key)
	if not _key or _key == '' then
		return false
	end

	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,"redis err: ", ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return false
    end

    local key = ZS_USER_PRE_SESSION.._key
    ngx.log(ngx.ERR, "key: ", key)
    redis_cli:del(key)

    return true
end

local function save_session(_key, _value)
	if not _key or _key == '' 
		or not _value or _value == '' 
	then
		return false
	end

	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return false
    end

    local key = ZS_USER_PRE_SESSION.._key
    local res, err = redis_cli:set(key, _value)
    if not res then
        ngx.log(ngx.ERR,cjson.encode(res),'   ',err)
        return false
    end

    return true
end

local function get_session(_key)
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return false, "系统错误."
    end

    local key = ZS_USER_PRE_SESSION.._key
    local res, err = redis_cli:get(key)
    if not res then
        return false, err
    end

    return true, res
end

function _M.get_user_session_info(_session_id)
	local res, err = get_session(_session_id)
	if res then
		return true, cjson.decode(err)
	else
		return false, err
	end
end

function _M.get_user_session_id(_user_id)
	return get_session(_user_id)
end

function _M.save_user_session_id(_user_id, _session_id)
	if not _user_id or _user_id == '' 
		or not _session_id or _session_id == '' 
	then
		return false, "参数错误, [_user_id] [_session_id] 错误 "
	end

	local res, err = _M.get_user_session_id(_user_id)
	if res then
		local res = delete_session(err)
		if not res then
			ngx.log(ngx.ERR, "---------------delete_session fail.--------------")
		end
	else
		if err then
			return false, "delete_session fail。"
		end
	end

	return save_session(_user_id, _session_id)
end

function _M.save_user_session_info(_user_id)
	if not _user_id or _user_id == '' then
		return false, "参数错误, [_user_id] 错误."
	end

	local res, err = _M.get_user_session_id(_user_id)
	if not res then
		return false, err
	end

	local session_id = err
	local session_info = {}
	session_info.session_id = session_id
	session_info.remote_ip = ngx.var.remote_addr
	session_info.login_time = ngx.time()
	return save_session(session_id, cjson.encode(session_info))
end

function _M.delete_user_session(_user_id)
	if not _user_id or _user_id == '' then
		return false, "参数错误, [_user_id] 错误."
	end

	local res, err = _M.get_user_session_id(_user_id)
	if not res then
		return false, err
	end

	local res = delete_session(err)
	if not res then
		ngx.log(ngx.ERR, "---------------delete_user_session delete session info fail.--------------")
	end

	local res = delete_session(_user_id)
	if not res then
		ngx.log(ngx.ERR, "---------------delete_user_session delete session id fail.--------------")
	end

	return true, "删除成功."
end


return _M

