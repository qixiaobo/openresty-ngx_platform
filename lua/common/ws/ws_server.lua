--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:web_socket_server.lua
--	version:0.01
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  websocket 服务器端封装,主要用于websocket服务器端的数据结构业务处理

--	使用方式
	local webSocket = require "common.ws_server"
	
	local wsImpl = webSocket:newServer(pushFCB, msgFCB)

	local res = wsImpl.loop()
 
	function msgFCB(msgType,msgData)
		
	end
-- ]]
local redis = require "resty.redis"
local cjson = require "cjson"
local msg = require "common.message"
local event = require "common.event"
local server = require "resty.websocket.server"

local WS_EVENT = event.WS_EVENT



local clazz = require "common.clazz.clazz"
local _M = {
	-- _properties = {}
}
_M.__index = _M
  
local _M  = {
	wb = nil,	-- wb 对象
	co = nil,	-- push 系统的回调,当系统
	closeFlag = false, -- 退出标志,设置为 true,各个循环函数将退出
	callback = {
		dispatch = nil,
		push_loop = nil,
	},

	-- 用户消息列表, 该主要用于消息管理, 未来实现类似redis系统,支持离线推送的能力
	-- 0.01版本使用redis模式代替
	subscribe_list = nil,
}

_M.__index = _M
 
--[[
-- 	_M:clazz_init() 创建一个服务器端 websocket 对象, 同时默认定义约定的websocket
--	对象的依赖参数包括loop函数以及其他回调函数 
--   pushFCB, msgFCB
-- 	@param  
--]]
_M.clazz_init = function (_self, _opts )
	-- body 
	if not _opts then _opts={} end
	local wb, err = server:new{
		  timeout = 100000,
		  max_payload_len = _opts.max_payload_len and  _opts.max_payload_len or 65535
	} 
	if not wb then
		ngx.log(ngx.ERR,"websocket new error, err is ",err)
		return nil
	end 
	-- 
	_self.wb = wb  
	return true
end


--[[
-- push_loop 系统的循环推送函数,主要是用redis订阅系统完成事件的发送与管理
-- 未来可自定义合适的loop系统, redis的系统性能压力

]]
_M.push_loop = function ( _self )
	-- body
	if not _self.subscribe_list then
		return nil
	end
    -- --create redis
    local red = redis:new()
    red:set_timeout(5000) -- 1 sec
    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect redis: ", err)
        _self:exit(404)
        return
    end

    --sub
    -- local res, err = red:subscribe(subscribe_list[1],subscribe_list[2])
    for i=1,#_self.subscribe_list do
    	 local res, err = red:subscribe(_self.subscribe_list[i])
	    if not res then
	        ngx.log(ngx.ERR, "failed to sub redis: ", err)
	        _self:exit(444)
	        return
	    end
    end
   

    -- loop : read from redis 发起订阅
    while _self.closeFlag == false do
        local res, err = red:read_reply() -- ["message","gameroom1","3333"] ["subscribe","111",2]
        if res then
            local typ = res[1]
            local item = res[3]
            ngx.log(ngx.ERR,"------",cjson.encode(res))
            if typ == "message" then
                local bytes, err = _self:sendMsg(item) 
                if not bytes then
                    -- better error handling
                    ngx.log(ngx.ERR, "failed to send text: ", err)
                    -- return ws:exit(444)
                end  
            end
            
        end
    end
 
 
end

--[[
	系统初始化,主要初始化客户端消息循环以及,跨应用或者进程之间的消息传递,
	如果不涉及自定义的 跨应用或跨进程, 则不需要传递回调推送函数.
-- @param  _callback 用户自定义消息推送结构对象,该对象为一个table,其中包含两个函数,
				msg_dispatch push_loop 
				msg_dispatch :函数为必需函数 
				push_loop	:该对象为函数,或者nil 当该函数为nil时,使用系统自带的loop函数进行消息推送服务

-- @param  _subscribe_list,订阅列表 系统开启之后自动进行该消息的订阅服务,同时将系统历史订阅消息进行用户推送				
]]
function _M:init( _callback, _subscribe_list )
	-- body 
	self.callback = _callback;
	self.subscribe_list = _subscribe_list;
end

--[[
-- _M:exit() 退出函数,将系统标志设置为true  ,循环函数进退出阻塞
-- 同时清理和释放资源
-- @param  httpErr http 错误信息,如444错误 ,403错误
--]]
function _M:exit( httpErr, code, reason )
	-- body
	if httpErr == 404 then return end
	self.closeFlag = true  
	self.exit_code = code 
	self.exit_reason = reason
end


--[[
-- _M:clear() 退之后进行资源释放，释放内存
-- @param  
--]]
function _M:clear(code, reason)  
	self.exit_code = code or 0
	self.exit_reason = reason or "Websocket end"
	local code = self.exit_code
	local msg = self.exit_reason

	if self.wb then
		if not self.wb.fatal then
			self.wb:send_close(code, msg)
		end
	end

	if self.co then
		ngx.thread.wait(self.co)
	end

end

--[[
-- _M:spawn( _callback ) 设置轻线程回调
-- @param  _callback 回调函数对象,该对象需要支持回调函数
--]]
function  _M:spawn( )
	-- body
	local push_loop = self.callback.push_loop
	if not push_loop then 
		-- push_loop = self.push_loop 
		return  
	else 
		self.co = ngx.thread.spawn(push_loop, self)  
	end  
end

--[[
-- _M:sendMsg( _msg ) 设置轻线程回调
-- @param  _callback 回调函数对象,该对象需要支持回调函数
--]]
function  _M:sendMsg( _msg,_msgType )
	-- body
	if not _msg then 
		local msgData = api_data.new({},"数据格式出错")
		return self.wb.send_text(cjson.encode(msgData)) 
	end 

	if type(_msg) == "string" then  
		if not _msgType then 	-- 文本
			 -- ngx.log(ngx.ERR,"sendmsg ",'string')
			return self.wb:send_text(_msg) 
		else
			 -- ngx.log(ngx.ERR,"sendmsg ",'binary')
			return self.wb:send_binary(_msg)
		end
	end
end


--[[
-- _M:loop() 阻塞状态的接收函数
 
--]]
function  _M:loop()
	-- body
	-- if not self.pushFCB or not self.msgFCB  then
		 
	-- 	return self:exit(444)
	-- end 
-- 开启轻线程,进行数据订阅的数据管理
	self:spawn();  
-- 回调消息函数,各个回调函数,自行进行数据组装和管理
	local dispatch = self.callback.dispatch
	if not dispatch then 
		ngx.log(ngx.ERR,"websocket dipatch is nill!!!!!")
		return
 	end
	while self.closeFlag == false do
	    -- 获取数据
	    local data, typ, err = self.wb:recv_frame()

	    -- 如果连接损坏 退出
	    if self.wb.fatal then
	        -- ngx.log(ngx.ERR, "failed to receive frame: ", err)
	        -- 通知业务引擎进行状态提醒和修改
	        dispatch(WS_EVENT.FATAL_EVENT)
	         
	        return ngx.exit(444)
	    end

	    if not data then
	        local bytes, err = self.wb:send_ping()
	        if not bytes then
	        	-- ngx.log(ngx.ERR, "failed to send ping: ", err)
	          
	            -- 通知业务引擎进行状态提醒和修改
		        dispatch(WS_EVENT.NODATE_EVENT)
	          
	          	return ngx.exit(444)
	        end
	        -- ngx.log(ngx.ERR, "send ping: ", data)
	    elseif typ == "close" then
	        -- 通知业务引擎进行状态提醒和修改
	        -- msgFCB() 
	        dispatch(WS_EVENT.CLOSE_EVENT)
	        self.closeFlag = true;
	        break
	    elseif typ == "ping" then
	        local bytes, err = self.wb:send_pong()
	        if not bytes then
	            -- ngx.log(ngx.ERR, "failed to send pong: ", err)

	            -- 通知业务引擎进行状态提醒和修改
	        	 dispatch(WS_EVENT.PING_ERR_EVENT)    
	             return ngx.exit(444)
	        end
	    elseif typ == "pong" then
	        -- ngx.log(ngx.ERR, "client ponged")
	        -- self.msgFCB(WS_EVENT.PONG_EVENT)   
	    elseif typ == "text" then 
			-- 通知业务引擎进行状态提醒和修改  返回值需要进行一次json 或者 直接返回string
			dispatch(WS_EVENT.TEXT_EVENT,data,self)   
			-- self.wb:send_text("11111")
			
	    elseif typ == "binary" then 
	    	dispatch(WS_EVENT.BINARY_EVENT,data,self)   
	    end
	end
end



-- setmetatable(_M,clazz)  -- _M 继承于 clazz

-- --[[
--     用来定义类似c++ 中 通过构筑函数 构造新类 类  Clazz  local clazz = Clazz()
--     相似的方式通过 new 创建
-- ]]
-- _M.__call = function(_self, ...)
--     -- body
--      -- ngx.log(ngx.ERR,'2222')
--     local impl = _self:new(...)  -- new(_self, ...)  --
--     return impl
-- end
-- 创建一个新类,使之支持 __call 元表操作即 CTest("zhang",'1.12')


function _M:new(_opt)
	local ws = setmetatable({},_M) -- 创建一个新类 继承于原 _M
	local res = ws:clazz_init(_opt)
	if not res then
		
		return nil
	end
 	return ws
end

function _M:publish(channel, data)
	local red = redis:new()
    red:set_timeout(1000) -- 1 sec
    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.log(ngx.ERR, "=====>>> Failed to connect redis: " .. err)
        return nil, "Failed to connect redis: " .. err
    end
    local res, err = red:publish(channel, data)
    if not res then
		ngx.log(ngx.ERR, "=====>>> Failed to publish redis: " .. err)
		return nil, "Failed to publish redis: " .. err
    end
	return true
end

return _M
 