
--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:/lua/modules/game/texasholdem/game_room.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  对局游戏的 房间对象定义
--]]

local redis = require "resty.redis"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local bit_help = require "common.bit_help" 
local uuid_help = require "common.uuid_help"
local online_union_help = require "common.online_union_help"
local timer_help = require "common.timer_help"
local ngx_thread_help = require "common.ngx_thread_help"
local resty_lock = require "resty.lock"


local GameRoom = { 
    -- 玩家列表
    player_list = {},
    -- 房间名称
    room_name = "",
    -- 房间编号
    room_no = "",
    -- 房间最大人数
    max_players  = 10,
    -- 房间图片
    icon = "",
    -- 房间头像
    icon_css = "",
    -- 房间主人 系统房间 或者房卡模式的用户房间
    room_owner = "",
    -- 游戏对局 编号
    game_no = {}, 
    
}
--[[
    游戏房间状态
]]
local GAMEROOM_STATE = {
    GAME_UNSTART = 1, -- 游戏未开始
    GAME_ON = 2, -- 游戏中
    GAME_PAUSE = 3, --  暂停
    GAME_END = 4, -- 游戏结束
}

GameRoom.GAMEROOM_STATE = GAMEROOM_STATE

_M._VERSION = '0.01'            
local mt = { __index = _M }  


function _M:new(room_code, _room_token, is_virtual_player)
    
    -- 读取数据库  判断是否被开启
    player.online_uuion = uuid_help:get64() 

    player.is_virtual_player = is_virtual_player
    
    -- 权限与登录管理
    
    
    local  game_room = setmetatable({}, mt);
   
    
    return game_room
end


--[[
-- _M:init() 用户初始化,系统各个不同游戏角色 自行实现 进行游戏角色初始化
    
-- @param  
-- @param   
-- @return 
--]]
function _M:init()
     
     
end
