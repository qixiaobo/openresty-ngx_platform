--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:token_auth.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  普通模块实现的方式, 当前界面主要用于管理
--  
--]]

local base_auth = require "auth.base_auth"
local api_data_help = require "common.api_data_help"

local _M = {}
_M.__index = _M
setmetatable(_M, base_auth)

-- 当前模块要求权限的模块列表,不需要权限要求不需要写入
local ACTION_MAP = {
	gen_code = {""},
	use_invite_code = {""},
	get_user_info = {""},
	get_points_detail = {""},
	get_balance_detail = {""},
	set_user_head_img = {""},
	set_user_nick = {""},
	set_user_location = {""},
	set_user_sex = {""},
	sign_in = {""},
	get_sign_info = {""},
	feedback = {""},
	get_feedback = {""},
	get_exchange_recode = {""},
	get_public_recode = {""},
	register = {""},
	login = {""},
	is_login_keep = {""},
	logout = {""},
	change_password = {""},
	bind_phone = {""},
	update_user_ex = {""},
	is_registered_user = {""},
	check_login = {""},
}
local user_auth_map = ngx.shared.ngx_cache
--[[
-- auth_check() 权限验证,继承类默认进行一次该类接口调用,各个模块对于自身接口的权限调用判断需要进行一次有效性判断
--				对于pc/wap 通过session判断,
				对于没有session判断失败用户,直接定向到登录界面
				对于ios/安卓/其他终端 用户auth进行登录, 系统对于每个用户登录成功之后 	
-- example   
	该函数有系统主动发起调用, 普通业务逻辑不会进行该函数调用
	对于 性能要求高的页面, 通过单独配置location 进行单独定向
 
-- @param  _action_name
-- @return  true or nil, default is true.
--]]
_M.auth_check = function(_action_name)
	-- 普通调用登录用户默认进行判断是否拥有权限
	--[[
		1, 首先获取用户token token信息存放在头信息里面
	]]
	if not ACTION_MAP[_action_name] then return true end
	local headers = ngx.req.get_headers(10)
	local auth_token = ngx.header["Token"]
	if not auth_token then 
		return nil  
	end
	-- 判断token是否有效
 	-- 一般调用用户账号管理判断token是否有效
 	
 	local is_exited = user_auth_map:get(auth_token)

 	if is_exited then 
 		return true
 	end

	-- 复杂调用需要注释 本行返回语句
	return nil

	--[[
	-- 复杂调用为:用户登录之后一般确定了电脑所在位置,用户在登录验证的时候将权限数据写入nginx的共享内存
			-- 本地进入共享内存进行调用权限字段是否存在
			如果用户的token没有写入共享内存, 用户需要从redis读取然后写入共享内存
			
			写入字段包含 token为主键对象 内容为当前token的有效公钥
			同时写入 token+authstr 内容为空字符串即可
			
			用户使用高级判断的时候将进行处理进行读取
	-- 调用方式如下:
	-- local user_auth_map = ngx.shared.ngx_cache
       local res = nil       
		-- for i=0,#ACTION_MAP[_action_name] do
		-- 		if user_auth_map:get[auth..ACTION_MAP[ _action_name][i] ] then
					return true
				end
		-- end
		return res
	-- ]]

end


--[[
    创建一个新的对象,继承函数可以直接使用当前函数
    即 xxx.__index = xxx
]]
_M.new = function( _self, ...)   
    local impl = setmetatable({}, _self) 
    return impl
end

return _M
 



-- local cjson = require "cjson"
-- local req = require "common.request"
-- local redis = require "redis.zs_redis"
-- local red = redis:new()
-- local respone = require"common.api_data_help"

-- local currentRequest = req.new();
-- local args = currentRequest:getArgs()
--  --[[

-- 	首先判断有无token,没有直接退出

--  --]]     
--  if not args.token  then

-- 	   local  result = respone.new_failed({},zhCn_bundles.login_no_token_error)
-- 	   ngx.say(cjson.encode(result))
--    ngx.exit(ngx.HTTP_FORBIDDEN)
--    return
--  end



 
-- local ret = red:get(args.token)
   
-- if not ret then
      
-- local  result = respone.new_failed({},zhCn_bundles.login_token_outtime_error)
-- 		   ngx.say(cjson.encode(result))
--        ngx.exit(ngx.HTTP_FORBIDDEN)
--       return
-- end




