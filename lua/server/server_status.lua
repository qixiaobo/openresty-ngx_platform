--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名: system_status.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  系统状态管理,系统信息输出
--]]

local SystemStatus = {
	isDebug = false,	-- 系统是否debug标志,用户输出调试信息
}

SystemStatus.setDebug = function ( _debug )
	-- body
	SystemStatus.isDebug = _debug
end
SystemStatus.isDebug = true
return SystemStatus