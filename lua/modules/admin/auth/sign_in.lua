--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:token_auth.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  系统的初始化脚本,该脚本用作nginx的 init_by_lua_file 的引用,
--  登陆相关的session函数封装,用户登录时记录该用户的状态
--  权限相关的  网页登录相关采用传统session的方式服务, 
-- 	权限相关的  移动端采用token管理
--]]

local cjson = require "cjson"
local uuid_help = require "common.uuid_help"
local admin_dao = require "admin.model.admin_dao"


local _M = {
	
}

_M.signIn = function( _userName,_password,_extData)

		local session = require "resty.session".start()   
		-- -- 访问数据库 
		local admin_user,menu_list,auths_map = admin_dao.login(_userName,_password);

		-- 如果为空则表示登陆失败
		if not admin_user then  
			session:destroy()
			ngx.log(ngx.ERR,"--------sign in error")
		 	return nil;
		end 
		 
		session.data.admin_name = _userName  
		session.data.admin_auth = uuid_help:get64()..uuid_help:get64()
		session.data.menu_list = menu_list
		session.data.auths_map = cjson.encode(auths_map) 
		session:save()    
	return admin_user;
end


_M.signOut = function(...)
	local session = require "resty.session".start()   
	session:destroy();  
end


_M.isSignIn = function(...)
	local session = require "resty.session".open()  
	-- ngx.log(ngx.ERR,"session time",ngx.var.session_cookie_lifetime)

	if not session.data.admin_name or not session.data.admin_auth then
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