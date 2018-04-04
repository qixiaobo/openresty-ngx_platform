--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:nginx_init.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  系统的初始化脚本,该脚本用作nginx的 init_by_lua_file 的引用,
--	模块的自定义信息初始化,用于系统自动管理,比如资源初始化,文件加载初始化等
--  
--]]

local _M = {}

_M.init = function ()
	-- body
	ngx.log(ngx.ERR,"organization init ")
end

return _M



