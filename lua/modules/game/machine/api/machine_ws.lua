--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:machine.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  游戏房间,对于房间分为固定房间,用户/主播房间,直播类游戏机为房间,该服务器端由机器客户端激活,并保持在
--  机器websocket客户端主动向系统连接,连接成功之后,主动上传机器状态信息,接收用户指令,短线后自动连接
--]]
 

-- simple chat with redis
local cjson = require "cjson"
local redis = require "resty.redis"
local redis_help = require "common.db.redis_help"
local ws_server = require "common.ws.ws_server"  
local WS_EVENT = require "common.event" .WS_EVENT
local machine_process = require "game.machine.machine_process"
local machine = require "game.machine.machine"

-- 读取玩家的信息包括主播名称,用户id,接入前需要提前判断一次,
-- 这里做一次判断,会比较多余 
local args = ngx.req.get_uri_args()
-- 查询当前的请求 
-- local h = ngx.req.get_headers()
-- for k, v in pairs(h) do
--  ngx.say(k)
-- end


-- machine_code 系统唯一用户编号, 
-- machine_auth 系统采用双向认证,该字段由机器编号+机器mac地址通过私密加密
-- 防治恶意用户
local machine_code = args["machine_code"];  
local machine_token = args["machine_token"];
local stream_addr = args["stream_addr"]
local stream_slave_addr = args["stream_slave_addr"]

--	没有机器编号 退出 
if not machine_code or not machine_token then
    ngx.log(ngx.ERR,"machine_code or machine_auth is ",machine_code,machine_token)
	return ngx.exit(444) 
end
 
--------
--  判断账户和密码是否正确,未来需要采用双向认证
--------


--[[
-----------------
	本地未来要添加用户是否付费情况,如果符合条件的用户才可以进行通信
	当前版本免费
-----------------
]]


-- 初始化 ws_server 对象
local ws = ws_server:new({max_payload_len=40*1024*1024})
if not ws then return ngx.exit(444) end
 
-- redis订阅,订阅返回
local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR..machine_code
local machine_impl = machine:new()
machine_impl.stream_addr = stream_addr
machine_impl.stream_slave_addr = stream_slave_addr

ngx.log(ngx.ERR,"1-------",machine_impl.stream_addr)

machine_impl.ws = ws;
local res = machine_impl:machine_init(machine_code,machine_token)


if not res then  
    ngx.log(ngx.ERR,"machine_init error !!!!")
    return ngx.exit(444) 
end

    -- --create redis 
local red = redis:new()
red:set_timeout(5000) -- 1 sec
local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
    ngx.log(ngx.ERR, "failed to connect redis: ", err)
    ws:exit(444)
    return
end

machine_impl.redis_cli = red

--sub
local res, err = red:subscribe(channel_name,ZS_REDIS_CHENNEL_SNOTICE)
if not res then
    ngx.log(ngx.ERR, "failed to sub redis: ", err)
    ws:exit(444)
    return
end
ngx.log(ngx.ERR,"machine code:",machine_code," ,machine_token ",machine_token)
--[[
-- push 函数默认使用 redis订阅功能进行数据管理
--  也可以采用信号量+信息队列进行数据推送和发送
-- 
--]]  
  

local push = function( )
    -- body  

    -- loop : read from redis
    while not ws.closeFlag  do
        local res, err = red:read_reply() -- ["message","gameroom1","3333"] ["subscribe","111",2]
        if res then
            local typ = res[1]
            local item = res[3] 
            if typ == "message" then 
            	local process =  cjson.decode(item)
                local res = machine_impl:dispatch_process(process)
                if not res then
                    ngx.log(ngx.ERR, "machine_impl:dispatch_process return false!!: ")
                else
                   -- local bytes, err = ws:sendMsg(item) 
                   --  -- local bytes, err = ws:sendMsg(ngx.encode_base64(item)) 
                   --  if not bytes then
                   --      -- better error handling
                   --      ngx.log(ngx.ERR, "failed to send text: ", err)
                   --      return ws:exit(444)
                   --  end  

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
         machine_impl:machine_break()
    elseif event == WS_EVENT.TEXT_EVENT then

        -- 打印用户消息,如果场景是需要将数据处理完,返回通知用户,则进行数据回推
        -- 一般数据回推使用信号量或者其他方案进行数据回推 
        -- 接收机器端上传的数据信息,该信息主要反馈给系统 或者 将数据反馈给用户端
        -- local msg_t = cjson.decode(data)
        
        local process =  cjson.decode(data)
         machine_impl:dispatch_process(process)

    else

    end

end

ws:init({push_loop=push, dispatch = msgDispath})
-- 进行loop操作,当loop结束,则返回数据
ws:loop()
 


-- 清理用户信息
ws:clear()
ngx.log(ngx.ERR,"退出")
 
