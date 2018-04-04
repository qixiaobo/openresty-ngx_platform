--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:event.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  事件类型,定义,通常用于各种操作或者其他状态下的类型处理
--	比如web socket 通信操作的类型包括接入事件类型,连接丢失事件类型,消息到来事件类型,ping事件类型等
--  
--]]


-- web socket 操作类型定义
local WS_EVENT = {
	FATAL_EVENT = 1,	-- ws 异常失败的事件类型
	NODATE_EVENT = 2,	-- ws 没有数据错误事件通知
	PING_ERR_EVENT = 3,	-- ws ping事件
	CLOSE_EVENT = 4,	-- ws 客户端连接关闭事件
	PONG_EVENT = 5,		-- ws pong事件
	TEXT_EVENT = 6,		-- 通信到来事件到来
	BINARY_EVENT = 7,	-- 二进制事件格式
	SEND_ERR_EVENT = 8,	-- 发送错误事件
}

WS_EVENT.__index = WS_EVENT


--  系统级别的事件集合包
local _M = {}
_M.WS_EVENT = WS_EVENT
 

return _M


