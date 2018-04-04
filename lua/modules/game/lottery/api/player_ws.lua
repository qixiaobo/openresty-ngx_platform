--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:machine.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  游戏房间,对于房间分为固定房间,用户/主播房间,直播类游戏机为房间,该服务器端由机器客户端激活,并保持在
--  玩家websocket服务器端,接收用户数据
--]]


-- simple chat with redis
local cjson = require "cjson" 
local redis = require "resty.redis"
local redis_help = require "common.db.redis_help"
local ws_server = require "common.ws.ws_server"  
local WS_EVENT = require "common.event" .WS_EVENT 
local uuid_help = require "common.uuid_help"
local Player = require "game.texasholdem.player"
-- local ngx_thread_help = require "common.ngx_thread_help"
-- 读取玩家的信息包括主播名称,用户id,接入前需要提前判断一次,
-- 这里做一次判断,会比较多余 
local args = ngx.req.get_uri_args()
-- 查询当前的请求

-- user_no 系统唯一用户编号,  
-- 防治恶意用户
local user_no = args["user_no"];  
local user_token = args["user_token"];
 
-- 游客身份 1表示游客, 0 表示非游客
local is_visitor = args["visitor"] and args["visitor"] or 0;

--没有用户编号 退出 游客身份
if not user_no or not user_token or user_no=="" then
-- 游客身份
    user_no = uuid_help:get64()
    user_token= "xxxxx"
    is_visitor = 1
end


-- token需要验证!!!!!!!!

--[[
-----------------
	本地未来要添加用户是否付费情况,如果符合条件的用户才可以进行通信
	当前版本免费
-----------------
]]
ngx.log(ngx.ERR, "user_no :", user_no)

-- 初始化 ws_server 对象
local ws = ws_server:new({max_payload_len=40*1024*1024})
if not ws then return ngx.exit(444) end

--[[ 
    创建用户连接,连接用户需要判断当前是否在线,每10秒钟发送一次性心跳
]]
local player = Player:new() 
player.ws = ws 
 
local res = player:player_init(user_no, user_token)

if not res then
    ws:sendMsg(cjson.encode({process_type=0x1c,sub_type=1,code=400,msg='登录错误,请检查密码或token是否正确!'}))
    ngx.sleep(1)
    player.ws:clear()
    return ngx.exit(400)
end
-- redis订阅,订阅返回
local channel_name = GAME_PLAYER_NOTICE_PRE..user_no

-- 获取上一次登录的状态信息,用于用户掉线之后的重连 
-- 用户如果没有主动退出,或者机器没有主动退出,则用户将保留用户的上一次房间资格
--[[
    查询用户状态,是否掉线问题
--]]


 -- --create redis 
local red = redis:new()
red:set_timeout(5000) -- 1 sec
local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
    ngx.log(ngx.ERR, "failed to connect redis: ", err)
    player.ws:clear()
    return ngx.exit(444) 
end 

player.redis_cli_msg = red 
_self.subscript_map[channel_name] = channel_name
_self.subscript_map[GAME_SYSTEM_NOTICE_PRE] = GAME_SYSTEM_NOTICE_PRE


--sub
local res, err = red:subscribe(channel_name, GAME_SYSTEM_NOTICE_PRE)
if not res then
    ngx.log(ngx.ERR, "failed to sub redis: ", err)
    ws:exit(444)
    return
end


if not res then
    ngx.log(ngx.ERR, "failed to sub redis: ", err,test_channel_name) 
    return
end 
--[[
-- push 函数默认使用 redis订阅功能进行数据管理
--  也可以采用信号量+信息队列进行数据推送和发送
-- 
--]]  
local push = function( ) 

    -- loop : read from redis
    while not ws.closeFlag  do 
        local res, err = red:read_reply() -- ["message","gameroom1","3333"] ["subscribe","111",2] 
        if res then   
            local typ = res[1]
            local from = res[2]
            local item = res[3]  
            -- ngx.log(ngx.ERR,'-----------------------',cjson.encode(res))
            if typ == "message" then
            	-- 解析协议 结构为json格式, 当前
                local res, process =  pcall(cjson.decode,item)
                if res then 
                    -- a 方案通过加锁,对两个协程进行加锁处理
                    -- local lock, err = resty_lock:new("ngx_locks")
                    -- if not lock then
                    --     ngx.log(ngx.ERR,"failed to create lock: ", err)
                    -- else
                    --     player:dispatch_process(process)  
                    --     local ok, err = lock:unlock()
                    --     if not ok then
                    --        ngx.log(ngx.ERR,"failed to unlock: ", err)
                    --     end
                    -- end 

                    -- b 方案 用户端发起的消息通过redis路由到订阅消息中处理
                    --[[
                        player:dispatch_process(process)  
                    ]]
                    -- c 方案 在程序内部进行锁处理
                    player:dispatch_process(process)  

                end 
            end 
        end 
    end 
end

    -- FATAL_EVENT = 1,    -- ws 异常失败的事件类型
    -- NODATE_EVENT = 2,   -- ws 没有数据错误事件通知
    -- PING_ERR_EVENT = 3, -- ws ping事件
    -- CLOSE_EVENT = 4,    -- ws 客户端连接关闭事件
    -- PONG_EVENT = 5,     -- ws pong事件
    -- TEXT_EVENT = 6,     -- 通信到来事件到来
    -- SEND_ERR_EVENT = 7, -- 发送错误事件
local msgDispath = function( event, data )
    -- body
    if event == WS_EVENT.FATAL_EVENT
        or event == WS_EVENT.NODATE_EVENT
        or event == WS_EVENT.PING_ERR_EVENT
        or event == WS_EVENT.CLOSE_EVENT
        or event == WS_EVENT.SEND_ERR_EVENT
    then
    -- ws离线消息,将用户当前状态设置为false 
    
    elseif event == WS_EVENT.TEXT_EVENT then 
        local process =  cjson.decode(data)
        process.user_no = player.user_no
        player:dispatch_process(process)   

    else

    end

end 
  
ws:init({push_loop=push, dispatch = msgDispath})
-- 进行loop操作,当loop结束,则返回数据
ws:loop()
-- 用户断开 通知机器
-- 清理用户信息
if player.room_code and  player.room_code ~= "" then

    local redis_cli = redis_help:new();
    if redis_cli then
        redis_cli:decr(SYSTEM_ON_LINE_USERS..player.room_code)
    end 
    ngx.log(ngx.ERR,"-0-===---- ",redis_cli:get(SYSTEM_ON_LINE_USERS..player.room_code))
end

ws:clear()
red:decr(SYSTEM_ON_LINE_USERS..machine_on_line_users)
ngx.log(ngx.ERR,"退出")
