--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:ws_client.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  lua websocket 客户端封装,用于websocket 服务端的初始化,对象新建以及其他操作
--  lua 回调函数主要包括

--	使用方式
	local webSocket = require "common.ws_server"
	
	local wsImpl = webSocket:newServer(pushFCB, msgFCB)

	local res = wsImpl.loop() 
	function msgFCB(msgType,msgData)
		
	end

	-- 故障或其他退出进行日志或者其他记录处理
--]]

local client = require "resty.websocket.client"
local msg = require "common.message"
local event = require "common.event"
local cjson = require "cjson"
local api_data = require "common.api_data_help"


local WS_EVENT = event.WS_EVENT


local _M  = {
	wb = nil,	-- wb 对象
	co = nil,	-- push 系统的回调,当系统
	closeFlag = false, -- 退出标志,设置为 true,各个循环函数将退出
	pushFCB = nil,	-- 推送的回调执行函数,	push回调函数为一个循环函数,
						-- 在循环函数中进行数据等待和推送!!!!!!!!
	msgFCB = nil, -- 循环消息到来的回调执行函数
}

_M.__index = _M
 
--[[
-- _M:new() 创建一个服务器端 websocket 对象, 同时默认定义约定的websocket
--	对象的依赖参数包括loop函数以及其他回调函数 

-- @param  
--]]
function _M:new( _url)

	-- body
	local webSocketImpl = setmetatable({},_M)

	local wb, err = client:new()
 	local ok, err = wb:connect(_url)
    if not ok then
        ngx.log(ngx.ERR,"failed to connect: " .. err,' _url is ', _url)
        return
    end
	--
	webSocketImpl.wb = wb 
	return webSocketImpl
end

function _M:init( pushFCB, msgFCB )
	-- body 
	self.pushFCB = pushFCB
	self.msgFCB = msgFCB
end

--[[
-- _M:exit() 退出函数,将系统标志设置为true  ,循环函数进退出阻塞
-- 同时清理和释放资源
-- @param  httpErr http 错误信息,如444错误 ,403错误
--]]
function _M:exit( httpErr )
	-- body
	self.closeFlag = true  
	ngx.log(ngx.ERR,"ws exit !!!!!!!")
end


--[[
-- _M:clear() 退之后进行资源释放，释放内存
-- @param  
--]]
function _M:clear( )
	ngx.log(ngx.ERR,"ws clear !!!!!!!")
	if self.wb then
		if not self.wb.fatal then
			self.wb:send_close()
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
	if self.pushFCB then 
		self.co = ngx.thread.spawn(self.pushFCB)  
	end
end

--[[
-- _M:sendMsg( _msg ) 设置轻线程回调
-- @param  _callback 回调函数对象,该对象需要支持回调函数
--]]
function  _M:sendMsg( _msg )
	-- body
	if _msg and type(_msg) == "string" then  
		return self.wb:send_text(_msg) 
	end
	ngx.log(ngx.ERR,"---------- sendMsg err!!")
	local msgData = api_data.new({},"数据格式出错")
	return self.wb.send_text(cjson.encode(msgData)) 
end

--[[
-- _M:loop() 阻塞状态的接收函数
 
--]]
function  _M:loop()
	-- body
	-- if not self.pushFCB or not self.msgFCB  then
		 
	-- 	return self:exit(444)
	-- end 
-- 开启轻线程,如果第三方数据接收,通过该对象执行,主要为系统各种事件
	self:spawn(); 
	-- ngx.log(ngx.ERR," loop  begin-------")
-- 回调消息函数,各个回调函数,自行进行数据组装和管理
	local msgFCB = self.msgFCB

	while self.closeFlag == false do
	    -- 获取数据
	    local data, typ, err = self.wb:recv_frame()

	    -- 如果连接损坏 退出
	    if self.wb.fatal then
	        ngx.log(ngx.ERR, "failed to receive frame: ", err)
	        -- 通知业务引擎进行状态提醒和修改
	        self.msgFCB(WS_EVENT.FATAL_EVENT)
	         
	        return ngx.exit(444)
	    end

	    if not data then
	        local bytes, err = self.wb:send_ping()
	        if not bytes then
	        	ngx.log(ngx.ERR, "failed to send ping: ", err)
	          
	            -- 通知业务引擎进行状态提醒和修改
		        self.msgFCB(WS_EVENT.NODATE_EVENT)
	          
	          	return ngx.exit(444)
	        end
	        -- ngx.log(ngx.ERR, "send ping: ", data)
	    elseif typ == "close" then
	        -- 通知业务引擎进行状态提醒和修改
	        -- msgFCB() 
	        self.msgFCB(WS_EVENT.CLOSE_EVENT)
	        ngx.log(ngx.ERR, "close event from server !")
	        self.closeFlag = true;
	        break
	    elseif typ == "ping" then
	        local bytes, err = self.wb:send_pong()
	        if not bytes then
	            ngx.log(ngx.ERR, "failed to send pong: ", err)

	            -- 通知业务引擎进行状态提醒和修改
	        	 self.msgFCB(WS_EVENT.PING_ERR_EVENT)    
	             return ngx.exit(444)
	        end
	    elseif typ == "pong" then
	        -- ngx.log(ngx.ERR, "client ponged")
	        -- self.msgFCB(WS_EVENT.PONG_EVENT)   
	    elseif typ == "text" then

			-- 通知业务引擎进行状态提醒和修改  返回值需要进行一次json 或者 直接返回string
			local res, taskSign = self.msgFCB(WS_EVENT.TEXT_EVENT,data)  
			if res then 
				local bytes, err = self.wb:send_text(res)
		        -- 发送通知  
		        if not bytes then
		            ngx.log(ngx.ERR, "failed to send a text frame: ", err)
	        		-- 通知业务引擎进行状态提醒和修改 
		           	local res = self.msgFCB(WS_EVENT.SEND_ERR_EVENT,taskSign)  
		                
		            return self:exit(444)
		        end
			end 
	      
	        --syntax: wb:set_timeout(ms)  
	    end
	end

end

return _M