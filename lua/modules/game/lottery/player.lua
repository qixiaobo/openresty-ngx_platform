
--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:/lua/modules/game/lottery/player.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  彩票玩家基础类
--  
--]]
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local bit_help = require "common.bit_help" 
local uuid_help = require "common.uuid_help"
local online_union_help = require "common.online_union_help"
local timer_help = require "common.timer_help"
local resty_lock = require "resty.lock"

local BasePlayer = require "game.player" 
local lot_protocol = require "game.lottery.lot_protocol"

-- 协议定义参数
local LOT_PROTOCOL = lot_protocol.LOT_PROTOCOL
local SUB_PROTOCOL = lot_protocol.SUB_PROTOCOL 
local PROTOCOL_FUNC_MAP = lot_protocol.PROTOCOL_FUNC_MAP 



local LOTPlayer = { 
    --用户id
    player_no = -1,
    --昵称
    nick_name = "",
    --1男2女，默认男
    sex  = 1,
    --头像
    head_img = "", 
    
    -- 余额
    balance = 1000,
    
    -- 游戏类型
    game_type = nil,
    -- 游戏局编号 
    innings_no = nil,
    -- 游戏盘局的标题 类似 第 xxx 期
    innings_no_title = nil,

    -- 玩家监听的游戏频道 用于通知玩家信息
    game_channel_name = nil, 
    -- 当前押注列表记录 新开一局 清空
    bet_list = {
            -- {
            --             innings_no = xxx, -- 局编号
            --             game_no=xxx,        -- 游戏编号
            --             game_way_no=xxx,        -- 游戏玩法编号
            --             bet_details = {2,3,5,7}, -- 类似此种
            --             bet_numbers = 1, -- 空也表示1注 前端与服务器都要进行一次金额处理
            --             is_win = xx, -- 是否中奖
            --         },
            --         {
            --             innings_no = xxx, -- 局编号
            --             game_no=xxx,        -- 游戏编号
            --             game_way_no=xxx,        -- 游戏玩法编号
            --             bet_details = {2,3,5,7}, -- 类似此种
            --             bet_numbers = 1, -- 空也表示1注 前端与服务器都要进行一次金额处理
            --             is_win = xx, -- 是否中奖
            --         }
    },
    
    
}

-- 继承
LOTPlayer.__index = LOTPlayer
setmetatable(LOTPlayer,BasePlayer)

local create_redis_cli = BasePlayer.create_redis_cli 

-- local function redis_publish(_redis_cli,_channel_name,_msg_data)
local redis_publish = BasePlayer.redis_publish  

LOTPlayer._VERSION = '0.01'            
LOTPlayer._CLAZZ = "game.lottery.player"  



--[[
    用户初始化,主要包括用户状态,用户的状态数据修改
-- @param _innings_no  新的一局 的游戏编号  
]]
function LOTPlayer:reset(_innings_no)
    -- 发送事件给客户端用户 由房间统一发送？ 可优化
    
end

--[[
    用户初始化,主要包括用户状态,用户的状态数据修改
-- @param _game_no_ex 游戏编号形成的分散服务器编号 防止玩家过多 造成redis等消息队列性能问题 
]]
function LOTPlayer:init(_game_no_ex) 
    self.game_channel_name = _game_no_ex
    self.player_index = _player_index
    self.player_state = PLAYER_STATE.SIDELINES
end

--[[
    押注扣费相关操作 
-- @param _bet_money 房间编号
-- @param _player_index 玩家在房间的index位置
]]
function LOTPlayer:bet(_bet_money)
   if self.player_state == PLAYER_STATE.ALL_IN then
        return true
   end

   local _tm = self.balance - _bet_money
   if _tm < 0 then 
        self.bet_money = self.bet_money + self.balance
        self.balance = 0 
        self.player_state = PLAYER_STATE.ALL_IN 

         -- 写入数据库
        _tm = self.balance
 
   else
        -- 用户需要执行allin 操作
        self.bet_money = self.bet_money + _bet_money
        if _tm == 0 then
            -- 此时玩家状态应该为allin状态
            self.player_state = PLAYER_STATE.ALL_IN 
        end

        self.balance =  self.balance - _bet_money

        _tm = _bet_money

        
   end 
    -- 写入数据库
    self:bet_mysql(_tm)
    
    return true
end


--[[
    
-- @param _protocol 协议 
]]
function LOTPlayer:on_heartbeat_c2s(_protocol) 
    local _protocol.protocol_type = LOT_PROTOCOL.HEARTBEAT_S2C

end

--[[ 
-- @param _protocol 协议  
]]
function LOTPlayer:on_heartbeat_s2c(_protocol)
    
end


--[[
    
-- @param _protocol 协议 
]]
function LOTPlayer:on_select_game_c2s(_protocol)
    



end

--[[ 
-- @param _protocol 协议  
]]
function LOTPlayer:on_select_game_s2c(_protocol)
    
end  

--[[
    
-- @param _protocol 协议 
]]
function LOTPlayer:on_game_notice_s2c(_protocol)
    
end

--[[ 
-- @param _protocol 协议  
]]
function LOTPlayer:on_bet_c2s(_protocol)
    
end  

--[[
    
-- @param _protocol 协议 
]]
function LOTPlayer:on_bet_s2c(_protocol)
    
end

--[[ 
-- @param _protocol 协议  
]]
function LOTPlayer:on_run_lot_c2s(_protocol)
    
end  

--[[
    
-- @param _protocol 协议 
]]
function LOTPlayer:on_run_lot_s2c(_protocol)
    
end
   

--[[ 
-- example 
 
-- @param  _self 对象本身
-- @param _protocol 协议格式
--]]
function LOTPlayer:dispatch_protocol( _protocol )
    -- body
    if not _protocol then return nil end
    if _protocol.protocol_type ~= 0x01 then
        ngx.log(ngx.ERR,string.format("--player -- %s, function:%s , protocol_type:%s ",
            self.player_no    ,PROTOCOL_FUNC_MAP[_protocol.protocol_type],cjson.encode(_protocol)))
    end   
    if not _protocol.msgid then
        _protocol.msgid = uuid_help:get64()  
    end
 

    local lock, err = resty_lock:new("ngx_locks")
    if not lock then
        ngx.log(ngx.ERR,"failed to create lock: ", err)
        -- 消息未执行 如何处理???

        -- 
    else 
        local elapsed, err = lock:lock(self.player_no)
        
        local redis_cli = create_redis_cli(); 
        self.redis_cli = redis_cli
        local res = self[PROCESS_FUNC_MAP[_protocol.protocol_type]](self, _protocol) 


        local ok, err = lock:unlock()
        if not ok then
            ngx.log(ngx.ERR,"failed to unlock: ", err)
        end
        return res
    end  
    
    -- ngx.log(ngx.ERR,"  player dispatch_protocol  ",cjson.encode(_protocol)," ",res)
    -- local ok,res = pcall( _self[PROCESS_FUNC_MAP[_protocol.protocol_type]],_self,_protocol) 
    -- _protocol.msgid = uuid_help:get64()  
    -- local ok, err = ngx.timer.at(1, _self.timer_func,_self,_protocol,_self.ws)
    -- if not ok then
    --     ngx.log(ngx.ERR, "failed to create the timer: ", err)
    -- end
    
end
 

--[[ 
-- example 
    用户押注的金额写入数据库 记录至少包含 包括变化金额,房间号,牌局号,时间
    同时生成备注与说明
-- @param  _bet_money 用户押注金额
-- @param _protocol 协议格式
--]]
function LOTPlayer:bet_mysql( _bet_money )


end

--[[ 
-- example 
    用户赢得了牌局 或平分 记录包括变化金额,房间号,牌局号,时间
    同时生成备注与说明
-- @param  _bet_money 用户押注金额 
--]]
function LOTPlayer:rewards_mysql( _rewards_money )


end
  

return LOTPlayer
