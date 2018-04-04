--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:lua/module/dispatch.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  系统api中转函数,通过该函数可以直接执行指定类的指定方法
--  
--]]

local path = ngx.var.mpath 
local clazz = ngx.var.clazz
local action = ngx.var.action

local system_manager = require "server.server_status" 

  
local modulePath = string.gsub(path, "/", ".") ..'.'.. clazz

if system_manager.isDebug then
	local app = requireExx(modulePath) 
	local res,code = xcallAction(app,action)
	 
else
	local app = requireEx(modulePath)
	local res,code = pcallAction(app,action) 
	 
end

 
-- local res,code = pcallAction(app,action)
-- -- 本地使用错误处理 可以在将本次执行的状态写入log,在本地获取一次log的业务处理
-- if not res then
-- 	ngx.log(ngx.ERR, "no debug???",code)
-- end  
-- ngx.log(ngx.ERR, "no debug???",code)
 

-- local version = function (  )
-- 	-- body
-- 	ngx.say(CTest._properties[1] )
-- 	local tes = {}
-- 	local test1 = tes[1].."123"
-- end
-- local ok ,err = pcall(version)
-- ngx.say(ok) 