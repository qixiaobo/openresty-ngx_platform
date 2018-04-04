--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:pre_config.lua
--  version:1.0.0.1
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  各个模块拥有自己的预定义对象,由于多个功能模块的程序放入一个文件中容易出现问题,故系统在初始化的时候,
--  自动扫描各个模块的pre_config对象, 预定义内部,用户自行处理,包括国际化等
--  
--]]

local _M = {} 
  
-- 系统默认的uuid 注意 uuid 设定为全局,其他地方不可以修改,否则会造成其他异常问题
-- 文件uuid namespace
_G.GAME_PLAYER_NOTICE_PRE = "PLAYER_REDIS_NOTICE"

-- 房间监听字段, 房间对象监听该字段的channel, 用于玩家向房间发送通知事件
_G.GAME_ROOM_NOTICE_PRE = "GAMEROOM_REDIS_NOTICE"

-- 玩家监听该消息 获得房间各种提醒消息信息
_G.GAME_ROOM_NOTICE_FORPLAYER_PRE = "GAMEROOM_FORPLAYER_REDIS_NOTICE"


_G.GAME_SYSTEM_NOTICE_PRE = "SYSTEM_REDIS_NOTICE"

_G.SYSTEM_ON_LINE_PRE = "SYSTEM_ON_LINE_"
 

return _M