
-- local api_data_help = require "common.api_data_help"
-- local mysql_help = require "common.db.mysql_help"

-- local uuid_help = require "common.uuid_help":new(ZS_USER_NAME_SPACE)

-- local _M = {}

-- function _M.run() 
--     local p1 = uuid_help:get94('123456')
-- 	local p2 = uuid_help:get94('123456')
-- 	ngx.log(ngx.ERR, "=====>>> p1=" .. p1 .. ", p2=" .. p2)
-- end


-- function _M.unregister() 
-- 	local args = ngx.req.get_uri_args()
-- 	local code = args['user_code']

-- 	local sql = string.format("DELETE FROM t_user WHERE user_code='%s';", code)
-- 	mysql_help:exec_once(sql)

-- 	sql = string.format("DELETE FROM t_user_ext_info WHERE user_code_fk='%s';", code)
-- 	mysql_help:exec_once(sql)

-- 	sql = string.format("DELETE FROM t_game_account WHERE user_code_fk='%s';", code)
-- 	mysql_help:exec_once(sql)

-- 	return api_data_help.new(0, "END")
-- end

-- return _M
ngx.header["Set-Cookie"] = { 
    "FMYL_GAME_CM_TOKEN=xyz;Path=/; Expires=" .. ngx.cookie_time(ngx.time() + 10),
    "FMYL_GAME_CM_USER=xyz;Path=/; Expires=" .. ngx.cookie_time(ngx.time() + 10)
}
-- ngx.header["Set-Cookie"] = "lxy=abc; Path=/; Expires=" .. ngx.cookie_time(ngx.time() + 20)