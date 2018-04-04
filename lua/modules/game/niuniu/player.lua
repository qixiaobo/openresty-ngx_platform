
--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:/lua/modules/game/texasholdem/player.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  德州扑克玩家对象,该对象继承系统玩家用户,共用其部分功能函数----
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
local texas_holdem = require "game.texasholdem.texas_holdem"

local th_protocol = require "game.texasholdem.th_protocol"

-- 协议定义参数
local PROTOCOL_TH = th_protocol.PROTOCOL_TH
local SUB_PROTOCOL = th_protocol.SUB_PROTOCOL
local TH_ERROR = th_protocol.TH_ERROR
local THGAME_STATE = th_protocol.THGAME_STATE  
local PLAYER_STATE =  th_protocol.PLAYER_STATE 
local PROTOCOL_FUNC_MAP = th_protocol.PROTOCOL_FUNC_MAP
local CARDS_TYPE = texas_holdem.CARDS_TYPE



local NNPlayer = { 
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
    
    --手牌
    hand_cards = nil,
    --组合最大牌
    max_cards = nil, 
    --牌型
    card_type = nil,

    -- 玩家状态
    player_state = PLAYER_STATE.SIDELINES,

    -- 游戏房间编号
    room_no = nil,

    -- 玩家所在排座的位置 由进入房间确定
    player_index = 1,  
  
    -- 当前局玩家押注的总金额
    bet_money = 0,   

    -- 玩家所在游戏的状态
    game_state = THGAME_STATE.ON_GAME_RESET,

    -- 游戏房间渠道名称
    channel_room_no = nil,
}

-- 继承
NNPlayer.__index = NNPlayer
setmetatable(NNPlayer,BasePlayer)



local create_redis_cli = NNPlayer.create_redis_cli 

-- local function redis_publish(_redis_cli,_channel_name,_msg_data)
local redis_publish = NNPlayer.redis_publish  

NNPlayer._VERSION = '0.01'   

NNPlayer._CLAZZ = "game.texas_holdem.player"  
 

--[[
    用户初始化,主要包括用户状态,用户的状态数据修改
-- @param _innings_no  新的一局 的游戏编号
-- @param _is_dealer 是否为庄家
-- @param _is_small_blind 是否为小盲
-- @param _is_big_blind 是否为大盲
-- @param is_utg 是否 UTG
]]
function NNPlayer:reset(_innings_no,_is_dealer,_is_small_blind,_is_big_blind,_is_utg)
    self.innings_no = _innings_no
    self.player_state = PLAYER_STATE.ON_GAME
    
    self.is_dealer = _is_dealer
    self.is_small_blind = _is_small_blind
    self.is_big_blind = _is_big_blind
    self.is_utg = _is_utg

    self.hand_cards = {} 
    self.max_cards = {}
    self.card_type = CARDS_TYPE.HIGHT_CARD
    
    if self.is_small_blind then
        -- 执行扣费押注
        ngx.log(ngx.ERR,"-------",self.nick_name,"----small blind ")
        self.balance = self.balance - self.blind_bet/2
    elseif self.is_big_blind then 
        -- 执行扣费押注
        ngx.log(ngx.ERR,"-------",self.nick_name,"----big blind ")
        self.balance = self.balance - self.blind_bet
    end
    
    -- 发送事件给客户端用户 由房间统一发送？ 可优化
    
end

--[[
    用户初始化,主要包括用户状态,用户的状态数据修改
-- @param _room_no 房间编号
-- @param _player_index 玩家在房间的index位置
]]
function NNPlayer:init(_room_no,_player_index)
    self.room_no = _room_no
    self.player_index = _player_index
    self.player_state = PLAYER_STATE.SIDELINES
end

--[[
    押注扣费相关操作 
-- @param _bet_money 房间编号
-- @param _player_index 玩家在房间的index位置
]]
function NNPlayer:bet(_bet_money)
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
function NNPlayer:on_heartbeat_c2s(_protocol) 
    local _protocol.protocol_type = PROTOCOL_TH.HEARTBEAT_S2C

end

--[[ 
-- @param _protocol 协议  
]]
function NNPlayer:on_heartbeat_s2c(_protocol)
    
end


--[[
    
-- @param _protocol 协议 
]]
function NNPlayer:on_room_sidelines_u2s(_protocol)
    



end

--[[ 
-- @param _protocol 协议  
]]
function NNPlayer:on_room_sidelines_s2u(_protocol)
    
end  

--[[
    
-- @param _protocol 协议 
]]
function NNPlayer:on_room_outsidelines_u2s(_protocol)
    
end

--[[ 
-- @param _protocol 协议  
]]
function NNPlayer:on_room_outsidelines_s2u(_protocol)
    
end  

--[[
    
-- @param _protocol 协议 
]]
function NNPlayer:on_wechat_msg_u2s(_protocol)
    
end

--[[ 
-- @param _protocol 协议  
]]
function NNPlayer:on_wechat_msg_s2u(_protocol)
    
end  

--[[
    
-- @param _protocol 协议 
]]
function NNPlayer:on_join_game_u2s(_protocol)
    local _data = _protocol.data 
    _data.player_no = self.player_no

    local channel_room_no =  GAME_ROOM_NOTICE_PRE.._data.room_no

    local redis_cli = self.redis_cli
    local res,err = redis_cli:publish(channel_room_no , cjson.encode(_protocol))

    if not res then
        local res_protocol = {
            protocol_type = PROTOCOL_TH.JOIN_GAME_S2U,
            code = TH_ERROR.TH_ERROR_SYSTEM_ERROR,  
        }
        self.ws:sendMsg(cjson.encode(res_protocol))
        return false
    elseif res == 0 then
        local res_protocol = {
            protocol_type = PROTOCOL_TH.JOIN_GAME_S2U,
            code = TH_ERROR.TH_ERROR_ROOM_OFFLINE,  
        }
        self.ws:sendMsg(cjson.encode(res_protocol))
        return false
    end

    return true
end

--[[ 
-- @param _protocol 协议  
]]
function NNPlayer:on_join_game_s2u(_protocol)
    local _data = _protocol.data

    if _protocol.code == 200 then
        self.player_state = PLAYER_STATE.ON_WAITING
        self.player_index = _data.player_index
        self.room_no = _data.room_no
        self.channel_room_no =  GAME_ROOM_NOTICE_PRE..self.room_no
    
        self.ws:sendMsg(cjson.encode(_protocol))
    else
        self.ws:sendMsg(cjson.encode(_protocol))
    end

    return nil

end  

--[[
    
-- @param _protocol 协议 
]]
function NNPlayer:on_left_game_u2s(_protocol)
    local _data = _protocol.data 
    _data.player_no = self.player_no  
    local redis_cli = self.redis_cli
    local res,err = redis_cli:publish(self.channel_room_no , cjson.encode(_protocol))

    if not res then
        local res_protocol = {
            protocol_type = PROTOCOL_TH.LEFT_GAME_S2U, 
            code = TH_ERROR.TH_ERROR_SYSTEM_ERROR, 
        }
        self.ws:sendMsg(cjson.encode(res_protocol))
        return false
    elseif res == 0 then
        local res_protocol = {
            protocol_type = PROTOCOL_TH.LEFT_GAME_S2U, 
            code = TH_ERROR.TH_ERROR_ROOM_OFFLINE, 
        }
        self.ws:sendMsg(cjson.encode(res_protocol))
        return false
    end

    return true



end

--[[
    
-- @param _protocol 协议 
]]
function NNPlayer:on_left_game_s2u(_protocol)
    local _data = _protocol.data

    if _protocol.code == 200 then
        self.player_state = PLAYER_STATE.LEAVE
        self.player_index = _data.player_index
        self.room_no = _data.room_no
        self.channel_room_no =  GAME_ROOM_NOTICE_PRE..self.room_no
    
        self.ws:sendMsg(cjson.encode(_protocol))
    else
        self.ws:sendMsg(cjson.encode(_protocol))
    end

    return nil

end

--[[
    
-- @param _protocol 协议 
]]
function NNPlayer:on_game_state_s2u(_protocol)
    
    -- 游戏过程进行清空当前押注
    if _protocol.sub_type >= SUB_PROTOCOL.GAME_REST and _protocol.sub_type <= SUB_PROTOCOL.ON_GAME_CLEARING then
       self.cur_flop_betmeney = 0  
    end
    self.game_state = _protocol.data.game_state

    

end

--[[ 
-- @param _protocol 协议  
]]
function NNPlayer:on_player_fold_u2s(_protocol)
    



end  

--[[
    
-- @param _protocol 协议 
]]
function NNPlayer:on_player_call_u2s(_protocol)
    

end

--[[ 
-- @param _protocol 协议  
]]
function NNPlayer:on_player_raise_u2s(_protocol)
    

end  

--[[ 
-- @param _protocol 协议  
]]
function NNPlayer:on_player_check_u2s(_protocol)
    

end  

--[[ 
-- @param _protocol 协议  
]]
function NNPlayer:on_player_cz_s2u(_protocol)
    

end 




--[[ 
-- example 
 
-- @param  _self 对象本身
-- @param _protocol 协议格式
--]]
function NNPlayer:dispatch_protocol( _protocol )
    -- body
    if not _protocol then return nil end
    if _protocol.protocol_type ~= 0x01 then
        ngx.log(ngx.ERR,string.format("--player -- %s,uuid:%s function:%s , protocol_type:%s, player state %d",
            self.user_no ,self.online_uuion ,PROTOCOL_FUNC_MAP[_protocol.protocol_type],cjson.encode(_protocol),self.player_state))
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
        local elapsed, err = lock:lock(self.online_uuion)
        
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
function NNPlayer:bet_mysql( _bet_money )


end

--[[ 
-- example 
    用户赢得了牌局 或平分 记录包括变化金额,房间号,牌局号,时间
    同时生成备注与说明
-- @param  _bet_money 用户押注金额 
--]]
function NNPlayer:rewards_mysql( _rewards_money )


end

--[[ 
reset   重置用户状态的函数
-- example 
    用户赢得了牌局 或平分 记录包括变化金额,房间号,牌局号,时间
    同时生成备注与说明
-- @param  _bet_money 用户押注金额 
--]]
function NNPlayer:reset( )
    self.hand_cards = {}
    self.card_type = CARDS_TYPE.HIGHT_CARD
    self.bet_money = 0

       -- 是否 为庄家
    self.is_dealer = false
    -- 是否为小盲注
    self.is_small_blind = false
    -- 是否为大盲注,大小盲注不可能是一个人 庄家/大盲注/
    self.is_big_blind = false
    self.is_utg = false


end


return NNPlayer
