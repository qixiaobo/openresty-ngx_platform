--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:online_union_help.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  系统唯一性登录判断,主要用websocket等长链接场合
--  
--]]

local redis_help = require "common.db.redis_help"
local clazz = require "common.clazz.clazz"

--[[

	local online_union_help = require "common.online_union_help"
	online_union_impl = online_union_help:new(_union_code,_timeout)

]]

local _M = {
	
}
-- _M.__index = _M

-- setmetatable(_M,clazz)  -- _M 继承于 clazz

-- _M.clazz_init = function(_self,_union_code,_timeout )
-- 	-- body
-- 	if not _union_code then
-- 		ngx.log(ngx.ERR,"online_union_help _union_code can not be nil")
-- 		ngx.exit(502)
-- 	end
-- 	if not _timeout then _timeout = 15 then
-- 	_self.union_code = _union_code
-- 	_self.time_out = _timeout

-- end

--[[
-- set_online_redis 通过redis唯一性登录判断
-- example 
-- @param  _union_code 唯一性code判断
-- @param	_value 有效值字段
-- @param _timeout  超时秒数
-- @return 1 表示成功;0 表示用户已经在线,此时可以强制将用户T下线; nil 表示系统错误,稍后再试;
--]] 
_M.set_online_redis = function (_union_code, _value, _timeout )
	-- body
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 

   	local res,err = redis_cli:setnx(_union_code,_value)
   	if not res then 
   		ngx.log(ngx.ERR,"setnx error:",err,".",_union_code," ",_value)
   		return nil
   	end
   	local vale = nil 
   	if res == 0 then
   		vale,err = redis_cli:get(_union_code)	
   		if not vale then
   			ngx.log(ngx.ERR,"get error:",err,".")
   			return nil
   		end
    else
       redis_cli:expire(_union_code,_timeout)  
  	end
	 
   	return res ,vale
end

--[[
-- keep_online_redis 刷新该对象的有效时间
-- example 
-- @param  _union_code 唯一性code判断
-- @param _timeout  更新超时时间
-- @return true 表示保持成功,-2表示已经超时,系统业务可以将该用户T下线
--]] 
_M.keep_online_redis = function ( _union_code,_timeout )
	-- body
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 

   	local res , err=  redis_cli:expire(_union_code,_timeout)
    if not res or res == 0 then
    	return nil
    end
 
   	return true 
end
 

--[[
-- is_online_redis 是否在线
-- example 
-- @param  _union_code 唯一性code判断
-- @return 返回时间 大于0 表示保持成功,-2表示已经超时,系统业务可以将该用户T下线 -1 表示没有设置超时时间
--]] 
_M.is_online_redis = function ( _union_code )
	-- body
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 

   	local res, err =  redis_cli:ttl(_union_code)
    if not res then
    	return nil
    end
    
 	if res == -2 then 
		 return nil 
 	end

 	if res == -1 then
 		redis_cli:expire(_union_code,15)
 		return 15
 	end
 	return res
end

--[[
-- update_online_redis 更新数据
-- example 
-- @param  _union_code 唯一性code判断
-- @return true 表示保持成功,-2表示已经超时,系统业务可以将该用户T下线
--]] 
_M.update_online_redis = function ( _union_code, _value, _timeout )
	-- body
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 
   	
    local res,err = redis_cli:set(_union_code, _value)
   	if not res then 
   		return nil
   	end 

  	if _timeout then
  		redis_cli:expire(_union_code,_timeout)
  	end

  	return true
end

--[[
-- delete_online_redis 删除数据
-- example 
-- @param  _union_code 唯一性code判断
-- @return true 表示保持成功,-2表示已经超时,系统业务可以将该用户T下线
--]] 
_M.delete_online_redis = function ( _union_code )
	-- body
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 
   	
    local res,err = redis_cli:del(_union_code)
   	if not res then 
   		return nil
   	end  

  	return true
end


--[[
-- get_online_redis 获得数据
-- example 
-- @param  _union_code 唯一性code判断
-- @return true 表示保持成功,-2表示已经超时,系统业务可以将该用户T下线
--]] 
_M.get_online_redis = function ( _union_code )
	-- body
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 
   	
    local res,err = redis_cli:get(_union_code)
   	if not res then 
   		return nil,err
   	end   
  	return res
end

--[[
-- get_left_time 获得剩余有效时间
-- example 
-- @param  _union_code 唯一性code判断
-- @return true 表示保持成功,-2表示已经超时,系统业务可以将该用户T下线
--]] 
_M.get_left_time = function ( _union_code )
  -- body
  local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 
    
    local res,err = redis_cli:ttl(_union_code)
    if not res then 
      return nil,err
    end   
    if res == -2 then 
        return 0
    elseif res == -1 then
        redis_cli:expire(_union_code,15)
        return 15
    end
    return res
end

return _M

