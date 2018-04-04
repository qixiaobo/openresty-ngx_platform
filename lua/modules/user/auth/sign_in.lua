--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:sign_in.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  系统的初始化脚本,该脚本用作nginx的 init_by_lua_file 的引用,
--  登陆相关的session函数封装,用户登录时记录该用户的状态
--  
--]]


local _M = {
	
}

_M.signIn = function( _userName,_userToken )

	local session = require "resty.session".start()  
		session.data.name = _userName
		session.data.token = _userToken
		-- session.data.date = 
		-- 登录时间自定义写入redis 或者其他的区域
		session:save()   

	return session;
end


_M.signOut = function(...)
	local session = require "resty.session".start()  
		session.data.user_name =  nil;
		session.data.user_token = nil;
 
		session:destroy(); 
	return session;
end


_M.isSignIn = function(...)
	local session = require "resty.session".open() 
	if not session.data.user_name or not session.data.user_token then
		return false;
	end 
	return true;
end
 
--[[
-- _M.getFiled 获取session登录对象存储的内容,例如用户id,扩展字段等
--  
-- example

-- @param  _key  查询的key对象名称 
-- @return 返回指定返回值
--]]
_M.getFiled = function ( _key)
	-- body
	if not _key then return nil end;

	local session = require "resty.session".open()   
	return session.data["".._key];
end

--[[
-- _M.setFiled 设置session 值对象,例如用户id,扩展字段等
--  
-- example

-- @param  _key  需要设置的key对象名称 
-- @param  _value  对象值
-- @return 无
--]]
_M.setFiled = function ( _key,_value)
	-- body
	if not _key then return nil end;
	local session = require "resty.session".start()   
	session.data["".._key] = _value;

	session:save()
end

 
return _M