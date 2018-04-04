--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:timer_help.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  定时器实现,与系统的定时不同,注意

local _M = {}


开启系统线程建议使用 ngx.timer.at 在回调函数中进行线程开启任务
定时器传递对象本身
—第一个参数为系统参数,跟普通的:定义方式不同
_M.f = function(_timer_self,_self,_param) 
     ngx.sleep(2)
     ngx.log(ngx.ERR,"f: hello",_param)  
 end
local ok, err = ngx.timer.at(1, _M.f,_M,"aaaa")
if not ok then
    ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
end
  

--]] 
local semaphore = require "ngx.semaphore"
local _M = {}

_M.__index = _M
_M.exit_flag = false
_M.time_out = nil
 
--[[
	example:
	
-- @param _cb_proc 定时器回调对象
-- @param _obj 		定时参数,一般函数为该对象的函数,采用类似类的概念
-- @param _param 	其他参数, 封装在一个表对象中
-- @return nil 表示失败  定时器对象
]]
_M.new = function( _self, _cb_proc, _obj, _param)
   local impl = setmetatable({}, _self)
   -- 等于当前对象的index数据 用于系统重启时候的资源释放
   impl.sema = semaphore.new()  
   -- 默认退出标志为false
   impl.exit_flag = false
   -- 系统回调函数
   impl.proc_cb = _cb_proc
   -- 用户端参数对象
   impl.obj = _obj
   impl.time_out = 3
   -- 定时器执行多少次, 默认执行一次 , 如果执行多次则每次到时间都会去执行一次函数,当函数返回nil,表示定时直接关闭
   impl.counts = 1
   impl.param = _param
   return impl
end
 


--[[
-- timer_at 定时器 超时执行 timer_at timer_every 只能同时开启一个, 使用时需要注意
-- example  

-- @param _time_out 超时对象
-- @param _counts 超时次数,即进行尝试次数 默认为1次
-- @return nil 表示失败 true 表示成功 
--]]
function _M:timer_at( _time_out, _counts)
	-- body 
	if _time_out then self.time_out = _time_out end
	if _counts then self.counts = _counts end 
	 
	if self.co then 
		return true
	end
	self.co = ngx.thread.spawn(self.main_loop,self) 
	if not self.co then
		return false end
	return true
end	
--[[
-- timer_every 定时器 每隔 _time_out 执行一次 直到用户或者系统取消
					timer_at timer_every 只能同时开启一个, 使用时需要注意
-- example  

-- @param _time_out 超时对象 单位秒
-- @param _counts 超时次数,即进行尝试次数 默认为1次
-- @return nil 表示失败 true 表示成功 
--]]
function _M:timer_every( _time_out )
	-- body 
	if _time_out then self.time_out = _time_out end 

	if self.co then 
		return true
	end
	self.co = ngx.thread.spawn(self.main_loop1,self) 
	if not self.co then
		return false end
	return true
end	

-- 线程内部循环函数
function _M:main_loop( )
	-- body
	while not self.exit_flag do   
		local ok, err = self.sema:wait(self.time_out)  -- wait for a second at most
	    if not ok then -- 定时器执行
	        self.counts = self.counts - 1 
	        local res,pres = pcall(self.proc_cb, self.obj, self.param) 
			if not res or not pres then
				 ngx.log(ngx.ERR,"res is ",res," pres is ",pres,", left: ",self.counts )
				self.exit_flag = true
				return -1
			end
	    else
	    	-- 系统直接收到激活事件  直接退出 
	        return 1
	    end
		if self.counts == 0  then
			return 1
		end
	end  
	return 1 
end

-- 线程内部循环函数
function _M:main_loop1( )
	-- body
	while not self.exit_flag do   
		local ok, err = self.sema:wait(self.time_out)  -- wait for a second at most
	    if not ok then -- 定时器执行 
	        local res,pres = pcall(self.proc_cb,self.obj) 
        else
    		-- 系统直接收到激活事件  直接退出 
        	return 1
	    end 
	end  
	return 1 
end

-- 退出 
function _M:exit( _code )
	-- body
	if not _code then _code = -1 end 
	self.sema:post(1)
	self.exit_flag = true
	return _code
end

-- 强制退出 如果用户线程为强制性回调,则进行强行kill操作
function _M:kill( )
	-- body
	if not self.co then
		ngx.thread.kill(self.co)
	end
end

return _M