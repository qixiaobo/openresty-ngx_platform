local cjson = require "cjson"
local req = require "common.request"
local redis = require "redis.zs_redis"
local red = redis:new()
local respone = require"common.api_data_help"

local currentRequest = req.new();
local args = currentRequest:getArgs()
 --[[

	首先判断有无token,没有直接退出

 --]]     
if not args.token  then

		   local  result = respone.new_failed({},zhCn_bundles.login_no_token_error)
		   ngx.say(cjson.encode(result))
       ngx.exit(ngx.HTTP_FORBIDDEN)
       return
end


local ret = red:get(args.token)
   
if not ret then
      
local  result = respone.new_failed({},zhCn_bundles.login_token_outtime_error)
		   ngx.say(cjson.encode(result))
       ngx.exit(ngx.HTTP_FORBIDDEN)
      return
end

local _user_session = require "auth.sign_in"


if not _user_session.isSignIn() then
	-- 退出函数 -- 或者相对于目录
	return ngx.redirect('http://www.baidu.com');
end 
 



