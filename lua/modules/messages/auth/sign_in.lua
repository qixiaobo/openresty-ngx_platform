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
		session.data.name =  "";
		session.data.token = "";
		session:destroy(); 
	return session;
end


_M.isSignIn = function(...)
	local session = require "resty.session".open() 
	if not session.data.name or not session.data.token then
		return false;
	end 
	return true;
end

return _M