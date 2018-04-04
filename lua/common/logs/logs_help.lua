--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:logs_help.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  log 日志收集功能,用于上下文上的日志引入,该模块采用ngx 本次链接的共享上下文作为传输通道
--]]
local cjson = require "cjson"

local _M = {} 

_M.log = function(_msg)
	if not ngx.ctx.logsArray then ngx.ctx.logsArray = {} end 
 	-- 未来可以增加消息的样式,本次业务使用json字符串格式进行保存


	ngx.ctx.logsArray[#ngx.ctx.logsArray+1] = _msg
end
 

_M.getMsg = function()
	-- body
	-- 未来可以增加消息的样式,本次业务使用json字符串格式进行保存
	return ngx.ctx.logsArray
end 

_M.getJsonMsg = function()
	-- body
	-- 未来可以增加消息的样式,本次业务使用json字符串格式进行保存
	return cjson.encode(ngx.ctx.logsArray)
end 

return _M