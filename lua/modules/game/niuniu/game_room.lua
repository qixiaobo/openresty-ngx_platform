
--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:/lua/modules/game/texasholdem/game_room.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  德州扑克房间对象,继承于普通游戏房间
--]]
local cjson = require "cjson"
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
local GameRoom = require "game.game_room"
local THPlayer = require "game.texasholdem.player"

local texas_holdem = require "game.texasholdem.texas_holdem"

local th_protocol = require "game.texasholdem.th_protocol"
-- 协议定义参数
local PROTOCOL_TH   = th_protocol.PROTOCOL_TH
local SUB_PROTOCOL  = th_protocol.SUB_PROTOCOL
local TH_ERROR      = th_protocol.TH_ERROR
local THGAME_STATE  = th_protocol.THGAME_STATE
local PLAYER_STATE  =  th_protocol.PLAYER_STATE 
local PROTOCOL_FUNC_MAP = th_protocol.PROTOCOL_FUNC_MAP
local CARDS_TYPE    = texas_holdem.CARDS_TYPE
 

local TFGameRoom = {
    
    -- 玩家列表
    player_list = nil,
    -- 以玩家code为key的map对象
    player_map = nil,
    -- 玩家座位列表
    player_index_list = nil,
    -- 房间玩家数量
    player_numbers = 0,
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
    innings_no = uuid_help:get64(),

    -- 盲注额度
    blind_bet = 10,
    -- 公共牌
    public_cards = nil,
    -- 当前游戏对局状态
    game_state = THGAME_STATE.ON_GAME_RESET , 
    
    -- 该位置 用来在当前有效玩家数组中的顺序
    dealer_index = 0,
    small_blind_index = 1,
    big_blind_index = 2,
    utg_index = 3,

    -- 该位置说明 牌桌的位置
    table_dealer_index = 0,
    table_small_blind_index = 1,
    table_big_blind_index = 2,
    table_utg_index = 3,

    raise_index = 1, -- 当局raise 的玩家 位置

    cur_player = nil, -- 当前等待操作的玩家

    game_timer = nil, -- 等待用户超时操作的对象,如果玩家超时,或者网络异常则判定玩家盖牌, 如果是最后一圈则进行比较
    
    game_msg_thread = nil,   -- 游戏开消息主循环线程, 当玩家低于2人
    
    texas_holdem_cards = nil, -- 德州扑克牌业务对象
   
    raise_player = nil,  -- 当前raise玩家

    channel_for_player_room_no = nil,

    channel_room_no =  nil, -- GAME_ROOM_NOTICE_FORPLAYER_PRE..self.room_no


}
-- 继承
TFGameRoom.__index = TFGameRoom
setmetatable(TFGameRoom,GameRoom)  

TFGameRoom._VERSION = '0.01'      


--[[
    消息主循环函数,主要用redis进行消息服务
]]
function TFGameRoom:main_push() 

    -- loop : read from redis
    local red = self.redis_cli_msg
    while not self.closeFlag  do 
        local res, err = red:read_reply() -- ["message","gameroom1","3333"] ["subscribe","111",2] 
        if res then   
            local typ = res[1]
            local from = res[2]
            local item = res[3]  
            -- ngx.log(ngx.ERR,'-----------------------',cjson.encode(res))
            if typ == "message" then
            	-- 解析协议 结构为json格式, 当前
                local res, protocol =  pcall(cjson.decode,item)
                if res then 
                    -- a 方案通过加锁,对两个协程进行加锁处理
                    -- local lock, err = resty_lock:new("ngx_locks")
                    -- if not lock then
                    --     ngx.log(ngx.ERR,"failed to create lock: ", err)
                    -- else
                    --     player:dispatch_protocol(protocol)  
                    --     local ok, err = lock:unlock()
                    --     if not ok then
                    --        ngx.log(ngx.ERR,"failed to unlock: ", err)
                    --     end
                    -- end 

                    -- b 方案 用户端发起的消息通过redis路由到订阅消息中处理
                    --[[
                        player:dispatch_protocol(protocol)  
                    ]]
                    -- c 方案 在程序内部进行锁处理
                    self:dispatch_protocol(protocol)  

                end 
            end 
        end 
    end 
end


--[[
    -- 1, 房间初始化进行处理,主要随机确定bank位置等
    -- 默认bank 6点钟第一个位置 即发牌官左手第一个位置的玩家以此往下递推
]]
function TFGameRoom:init()
    -- 开启房间消息循环队列
    self.game_msg_thread = ngx_thread_help:new(self.main_push, self) 
    -- --create redis 
    local red = redis:new()
    -- red:set_timeout(5000) -- 1 sec
    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect redis: ", err) 
        return nil 
    end

    -- 房间监听消息
    self.channel_room_no = GAME_ROOM_NOTICE_PRE..self.room_no

    -- 用于发送给该房间所有玩家的 频道
    self.channel_for_player_room_no = GAME_ROOM_NOTICE_FORPLAYER_PRE..self.room_no

    -- 房间需要订阅该两个频道
    red:subscribe(self.channel_room_no, GAME_SYSTEM_NOTICE_PRE)

    self.redis_cli_msg = red 

    -- 玩家列表
    self.player_list = {} 
    -- 以玩家code为key的map对象
    self.player_map = {} 
    -- 玩家座位列表
    self.player_index_list = {} 

    self.dealer_index = 0


    -- 开启房间事件监听
    self.game_msg_thread:start()
end

--[[
-- 2, 加入游戏 当玩家新进入房间之后按照顺序加入位置,如果位置有人往下进行位置定位
-- 加入房间协议
-- _protocol = {protocol_type = PROTOCOL_TH.JOIN_GAME_U2S,  
            data = {
                player_no=xxx,
                nick_name=xxx,
                sex=xx,
                head_img=xxx,
                balance=xxx,
                player_level = xxx,
                room_no="xxxx", 
                seat_index = xx, -- 如果没有传递该信息,则随机一个有效位置返回给用户
                room_pwd = xxx,  -- 房间密码 需要密码的房间用户必须输入密码才能登陆
            }
        } 

]]
function TFGameRoom:on_join_game(_protocol)
    local redis_cli = self.redis_cli
    local _data = _protocol.data
    if self.player_numbers >= 10  then
        -- 房间人数达到上限
        local ret_protocol = {
            protocol_type = PROTOCOL_TH.JOIN_GAME_S2U,
            code = TH_ERROR.TH_ERROR_ROOM_ALL_SEATS_TAKEN,
            data = {
                player_no = _data.player_no,
                room_no = _data.room_no,
            }
        }
        
        local res,err = redis_cli:publish(GAME_PLAYER_NOTICE_PRE.._data.player_no, cjson.encode(ret_protocol))
        -- if not res or res == 0 then
           
        -- end
        return 
    end

    if not _data.seat_index then
        -- 随机位置
        _data.seat_index = 1
    elseif tonumber(_data.seat_index) > 10 or tonumber(_data.seat_index) < 0 then
        -- 参数错误
        local ret_protocol = {
            protocol_type = PROTOCOL_TH.JOIN_GAME_S2U,
            code = TH_ERROR.TH_ERROR_PARAM_NIL,
            data = {
                player_no = _data.player_no,
                room_no = _data.room_no,
            }
        }
        local res,err = redis_cli:publish(GAME_PLAYER_NOTICE_PRE.._data.player_no, cjson.encode(ret_protocol))

        return 
    end

    -- 创建德州扑克玩家, 并且分配位置
    local player = THPlayer:new2(_data)
    if not self.player_index_list[tonumber(_data.seat_index)] then
        self.player_index_list[tonumber(_data.seat_index)] = player
        player.player_index = _data.seat_index
    else
        for i = 1,self.max_players do
            if not self.player_index_list[i] then
                self.player_index_list[i] = player
                player.player_index = _data.seat_index
                break;
            end
        end
    end

    -- 如果房间状态为未开始,人数大于2,则执行游戏主循环
    if self.room_state == THGAME_STATE.ON_GAME_WAITING then
        if #player_list >=2 then 
            self.game_reset()
        end
    end

end


--[[
离开游戏
-- 离开房间协议
-- _protocol = {
                protocol_type = PROTOCOL_TH.LEFT_GAME_U2S,  
                data = {    
                    player_no=xxx, 
                    room_no="xxxx", 
                    player_index = xxx, 
                }
        } 

]]
function TFGameRoom:on_left_game(_protocol)
    local _data = _protocol.data





end
 

--[[
    当前游戏开始时用户状态进行初始化
    local THPlayer = { 
    --用户id
    player_no = -1,
    --昵称
    nick_name = "",
    --1男2女，默认男
    sex  = 1,
    --头像
    icon = "", 
    --手牌
    handCards = {},
    --组合最大牌
    maxCards = {}, 
    --牌型
    cardType = nil,
    player_state = nil,
    --是否是虚拟玩家
    is_virtual_player = false,
    -- 是否 为庄家
    is_bank = false,
    -- 是否为小盲注
    is_small_blind = false,
    -- 是否为大盲注,大小盲注不可能是一个人 庄家/大盲注/
    is_big_blind = false,
    
    player_index = 1, -- 玩家所在排座的位置 由进入房间确定 
}
]]

function TFGameRoom:game_reset()
    self.innings_no = uuid_help:get64()
    -- 清除玩家基础状态
    local player_list = {}
    
--    local plen = table.len(self.player_index_list)
--    if self.dealer_index == 0 then
--         
--    end
    -- 初始化当局玩家
    for i=1,self.max_players do   
        if self.player_index_list[i] then 
           self.player_index_list[i]:reset()
           self.player_index_list[i].innings_no = self.innings_no
           table.insert(player_list,self.player_index_list[i])
        end
    end
    self.player_list = player_list
    self.texas_holdem_cards = texas_holdem:new()
    self.public_cards = {}


    -- 计算bank 大小盲注的位置 
    local dealer_index = 1
    local small_blind_index = 1
    local big_blind_index = 1
    local utg_index = 1
      
    local player_len = #player_list

    -- 如果当前人数少于2人,游戏提醒等待玩家进入状态
    if player_len < 2 then
        ----------------------------- 
        return 
    end

    if self.table_dealer_index == 0 then
--        dealer_index = self.player_list[1].player_index 
        dealer_index = 1
    else 
        for i=1,player_len do
            if player_list[i].player_index == self.table_dealer_index then
                if i < player_len then
--                    dealer_index = self.player_list[i+1].player_index
                    dealer_index = i+1
                else -- 说明在当前顺时针 排列中 下一个bank的位置为最后一个变为第一个
                    dealer_index = 1
                end 
                break;
            end 
        end 
    end


    self.dealer_index = dealer_index 
    self.table_dealer_index = player_list[dealer_index].player_index 
    player_list[dealer_index].is_dealer = true
    if dealer_index < player_len then
         small_blind_index = dealer_index + 1
    else
         small_blind_index = 1
    end
    player_list[small_blind_index].is_small_blind = true
    self.small_blind_index = small_blind_index
    self.table_small_blind_index = player_list[small_blind_index].player_index


    if small_blind_index < player_len then
         big_blind_index = small_blind_index + 1
    else
         big_blind_index = 1
    end

    player_list[big_blind_index].is_big_blind = true
    self.big_blind_index = big_blind_index
    self.table_big_blind_index = player_list[big_blind_index].player_index


    if big_blind_index < player_len then
         utg_index = big_blind_index + 1
    else
         utg_index = 1
    end
    player_list[utg_index].is_utg = true 

    self.utg_index = utg_index
    self.table_utg_index = player_list[utg_index].player_index 

    self.raise_player = player_list[big_blind_index]
    self.raise_player.is_default_raise = true

    self:on_perflop()
end




--[[
    第一轮的押注过程循环
    第一轮押注, 发完牌从 utg玩家开始,该玩家拥有fold, call, raise 三种权限
]]
function TFGameRoom:per_bet_loop()
    -- 如果是休息状态,则通知用户准备开始, 发送通知,准备进行第一轮操作 
    -- 从第一个位置开始玩家如果是all状态/fold则自动往后一位

    local raise_player = self.raise_player
    local player_list = self.player_list
    local player_len = #player_list
 
    for i=1,player_len do
        local first_person_index = self.auth_person_index 
        local curl_player = self.player_list[first_person_index] 
        -- 判断当前是否有 raiser 没有raiser 则属于玩家拥有call bet raise folden 权限 
        if raise_player.player_index == curl_player.player_index and not raise_player.is_default_raise then
            -- 执行到下一个业务
            self:on_flop()
            return false
        elseif raise_player.player_index == curl_player.player_index and raise_player.is_default_raise then
            -- 说明当前需要进行大盲注, 大盲注拥有raise 或者 check的权限
            if raise_player.player_state == PLAYER_STATE.ALL_IN then
                 -- 执行到下一个业务
                self:on_flop()  
                return false
            end
       end 

       if curl_player.player_state == PLAYER_STATE.ALL_IN 
                or curl_player.player_state == PLAYER_STATE.FOLDED  
                or curl_player.player_state == PLAYER_STATE.LEAVE 
            then
            if self.auth_person_index + 1 == player_len then
                self.auth_person_index = 1 
            else
                self.auth_person_index = self.auth_person_index + 1 
            end
        else 
            -- 执行通知
            local redis_cli = create_redis_cli()
            local _protocol = {
                protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
                sub_type =  SUB_PROTOCOL.ON_PER_FLOP_BET,
                data = { 
                    room_no = self.room_no,
                    innings_no = self.innings_no,
                    game_state = self.game_state,
                    player_no = player.player_no, 
                }
            }




        end


        return false
    end
end



--[[
    牌局押注主循环函数,用该函数进行押注轮训操作和状态衔接逻辑处理
]]
function TFGameRoom:bet_loop()
    -- 如果是休息状态,则通知用户准备开始, 发送通知,准备进行第一轮操作 
    local first_person_index = self.auth_person_index
    
    local player_list = self.player_list
    local player_len = #player_list

    local is_waiting = false

 

    local player = player_list[first_person_index]
    -- 玩家all 则不用循环操作 否则需要进行处理
    if player.player_state == PLAYER_STATE.ALL_IN 
        or player.player_state == PLAYER_STATE.FOLDED  
        or player.player_state == PLAYER_STATE.LEAVE 
    then
        


    end
        -- 执行通知
        local redis_cli = create_redis_cli()
        local _protocol = {
            protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
            sub_type =  SUB_PROTOCOL.ON_PER_FLOP_BET,
            data = { 
                room_no = self.room_no,
                innings_no = self.innings_no,
                game_state = self.game_state,
                player_no = player.player_no, 
            }
        }  
        redis_publish(redis_cli, self.channel_for_player_room_no, cjson.encode(_protocol))  
end

local create_redis_cli = THPlayer.create_redis_cli 

-- local function redis_publish(_redis_cli,_channel_name,_msg_data)
local redis_publish = THPlayer.redis_publish  

--[[
    get_game_pot 获得当前游戏的池底
]]
function TFGameRoom:get_game_pot()
    local player_list = self.player_list
    local game_pot = 0
    for i=1,#player_list do
        game_pot = game_pot + player_list[i].bet_money
    end

    return game_pot
end


--[[
    deal_hand_cards 发手牌

]]
function TFGameRoom:deal_hand_cards()
    local player_list = self.player_list 
    for i=1,#player_list do
        player_list[i].hand_cards = self.texas_holdem_cards:getMutiCards(2) 
    end
 
end


--[[
    get_game_pot 发公共牌

]]
function TFGameRoom:deal_public_cards(_cards_num)
      self.public_cards = self.texas_holdem_cards:getMutiCards(5) 
end


--[[
    get_player_info 获得玩家的状态

]]
function TFGameRoom:get_player_info(_player_index)
        local player_list = self.player_list

       local _player = {
            --用户id
            player_no = player_list[_player_index].player_no,  
            -- 余额
            balance = player_list[_player_index].balance,
            
            --手牌
            hand_cards = player_list[_player_index].hand_cards,
            --组合最大牌
            max_cards = player_list[_player_index].max_cards, 
            --牌型
            card_type = player_list[_player_index].card_type,
            
            player_state = player_list[_player_index].player_state,
            
            -- 是否 为庄家
            is_dealer = player_list[_player_index].is_dealer,
            -- 是否为小盲注
            is_small_blind = player_list[_player_index].is_small_blind,
            -- 是否为大盲注,大小盲注不可能是一个人 庄家/大盲注/
            is_big_blind = player_list[_player_index].is_big_blind,
            is_utg = player_list[_player_index].is_utg,
            -- 房间编号
            room_no = self.room_no,
            -- 游戏对局 编号
            innings_no = self.innings_no, 
            
            bet_money = player_list[_player_index].bet_money, -- 玩家押注额度 

            -- 玩家 操作 列表

        }



       return _player
end



--[[
    德州扑克 perflop ,该函数将根据当前状态进行循环处理
    发牌手牌阶段
]]
function TFGameRoom:on_perflop()
    -- 如果是休息状态,则通知用户准备开始, 发送通知,准备进行第一轮操作 
    -- preflop 
    
    self.game_state = THGAME_STATE.ON_PERFLOP 

    -- 大小盲注扣费
    self.player_list[self.small_blind_index]:bet()
    self.player_list[self.big_blind_index]:bet()

    -- 通知玩家 消息类型为 perflop 通知客户端执行动画过程 
    local redis_cli = create_redis_cli()

    local _protocol = {
            protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
            sub_type =  SUB_PROTOCOL.ON_PER_FLOP,
            data = { 
                room_no = self.room_no,
                innings_no = self.innings_no
                game_state = self.game_state,
                game_pot = self:get_game_pot(),  -- 池底
                player_list = {}, 
            }

    }
    -- 初始化玩家信息,玩家收到room_state_s2u的时候需要进行一次转换,即将非自己的扑克牌变成假牌
    for i=1,#self.player_list do 
        local _player =  self:get_player_info()
        table.insert( _protocol.data.player_list,_player)
    end
    -- 通知所有的当局玩家进行更新
    redis_publish(self.channel_for_player_room_no ,cjson.encode(_protocol))

    -- 执行玩家进行押注循环
    -- 通知 utg 玩家 开启倒计时
    -- 创建一个定时器对象进行loop循环 如果用户执行操作 则关闭该线程 执行下一个循环
    local auth_person_index = 1
    if self.game_state = THGAME_STATE.ON_PERFLOP then
        auth_person_index = self.utg_index
    else
        auth_person_index = self.small_blind_index
    end
 

    self.auth_person_index = auth_person_index
    -- !!!!! 等待客户端发牌结束, 发完之后  ,进行押注相关操作
    -- 开启线程对象
    self.game_timer = timer_help:new(,self.bet_loop,self)
    -- ngx.sleep(2+#self.player_list / 2)
    -- 指定事件之后进行押注的循环处理
    self.game_timer:timer_at(2+#self.player_list / 2,1) 
    
end
 

--[[
    德州扑克 flop ,该函数将根据当前状态进行循环处理
    准备发前三张公共牌
]]
function TFGameRoom:on_flop()
    -- 如果是休息状态,则通知用户准备开始, 发送通知,准备进行第一轮操作 
    -- preflop 
    
    self.game_state = THGAME_STATE.ON_FLOP 
      -- 执行玩家进行押注循环 
    -- 创建一个定时器对象进行loop循环 如果用户执行操作 则关闭该线程 执行下一个循环
    local auth_person_index = 1
    if self.game_state = THGAME_STATE.ON_PERFLOP then
        auth_person_index = self.utg_index
    else
        auth_person_index = self.small_blind_index
    end
    self.auth_person_index = auth_person_index

    self.raise_player = nil
    self.cur_player = nil


    self:bet_loop()

 
end


--[[
    德州扑克 turn ,该函数将根据当前状态进行循环处理
    发第四张公共牌
]]
function TFGameRoom:on_turn()
    -- 如果是休息状态,则通知用户准备开始, 发送通知,准备进行第一轮操作 
    -- preflop 
    
    self.game_state = THGAME_STATE.ON_FLOP 
      -- 执行玩家进行押注循环
    
    -- 创建一个定时器对象进行loop循环 如果用户执行操作 则关闭该线程 执行下一个循环
        local auth_person_index = 1
    if self.game_state = THGAME_STATE.ON_PERFLOP then
        auth_person_index = self.utg_index
    else
        auth_person_index = self.small_blind_index
    end
    self.auth_person_index = auth_person_index

    self.raise_player = nil
    self.cur_player = nil 

    self:bet_loop()
 
end

--[[
    德州扑克 turn ,该函数将根据当前状态进行循环处理
    发第五张公共牌
]]
function TFGameRoom:on_river()
    -- 如果是休息状态,则通知用户准备开始, 发送通知,准备进行第一轮操作 
    -- preflop 
    
    self.game_state = THGAME_STATE.ON_RIVER
      -- 执行玩家进行押注循环
    -- 通知 utg 玩家 开启倒计时
    -- 创建一个定时器对象进行loop循环 如果用户执行操作 则关闭该线程 执行下一个循环
    self:bet_loop()

 
end




--[[
    德州扑克 clear  ,该函数将根据当前状态进行循环处理
]]
function TFGameRoom:on_clear()
    -- 如果是休息状态,则通知用户准备开始, 发送通知,准备进行第一轮操作 
    -- preflop 
    
    self.game_state = THGAME_STATE.ON_RIVER
      -- 执行玩家进行押注循环
    -- 通知 utg 玩家 开启倒计时
    -- 创建一个定时器对象进行loop循环 如果用户执行操作 则关闭该线程 执行下一个循环
    self:bet_loop()

 
end



-------------------------------------------------协议----------------------------------------------------

--[[
    用户加入游戏
-- @param _protocol 协议  
]]
function TFGameRoom:on_join_game_u2s(_protocol)
    
end

--[[
    用户退出游戏
-- @param _protocol 协议 
]]
function THPlayer:on_left_game_u2s(_protocol)
    
end

--[[ 
    用户fold 操作
-- @param _protocol 协议  
]]
function THPlayer:on_player_fold_u2s(_protocol)
    
end  

--[[
    用户跟牌操作
-- @param _protocol 协议 
]]
function THPlayer:on_player_call_u2s(_protocol)
    
end

--[[ 
   用户raise 操作
-- @param _protocol 协议  
]]
function THPlayer:on_player_raise_u2s(_protocol)
    
end  

--[[ 
    用户check操作
-- @param _protocol 协议  
]]
function THPlayer:on_player_check_u2s(_protocol)
    
end  





--[[
-- dispatch_protocol 机器 系统网络消息通信解析功能函数 
-- example 
 	
-- @param _protocol_str 消息字符串,系统进行一次 转换为lua系统数据结构进行处理
--]]
function TFGameRoom:dispatch_protocol( _protocol )
    -- body 
    if not _protocol then return nil end
	if _protocol.protocol_type ~= 0x01 then
        ngx.log(ngx.ERR,string.format("--room_no -- %s, function:%s , protocol:%s",
        self.room_no,PROCESS_FUNC_MAP[_protocol.protocol_type],cjson.encode(_protocol)))
       

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
	 

	
end



return _M
