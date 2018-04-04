--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:ngx_thread_help.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  基于ngx线程对象封装 线程使用存在一些约束
--  1, 当线程对象存在用户上下文发起的时候,当前上下文如果使用ngx.exit 则基于该上下文的线程也将关闭
--  2, 对于定时器的上下文开启的线程是独立的线程, 不会因为 ngx.exit 退出而释放, 包括reload
--  3, 对于ngx.eof之后的用户端线程不会被释放, 包括reload(RELOAD 只会影响数据内存,不会影响执行代码线程)
--  

local _M = {}
开启系统线程建议使用 ngx.timer.at 在回调函数中进行线程开启任务 !!!!
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
local mutex_help = require "common.mutex_help"
local spawn = ngx.thread.spawn
local wait = ngx.thread.wait
local kill = ngx.thread.kill


local _M = {}

_M.__index = _M

_M.cur_index = os.time()
_M.exit_flag = false
_M.time_out = nil
 
--[[
	example:
 	
-- @param _self thread 对象父类本身
-- @param _cb_proc thread 消息循环主函数
-- @param _obj thread 用户传递的对象,作为 cb_proc 参数

]]
_M.new = function( _self, _cb_proc, _obj)
   local impl = setmetatable({}, _self)
   -- 等于当前对象的index数据 用于系统重启时候的资源释放
   impl.cur_index = _M.cur_index
   -- 默认退出标志为false
   impl.exit_flag = false
   -- 系统回调函数
   impl.proc_cb = _cb_proc
   -- 用户端参数对象
   impl.obj = _obj
   
   return impl
end

-- 创建线程对象传递 对象和函数
-- 程序需要集成thread 自带初始化函数 用户上下文的线程 默认为用户上下文 ,
-- 退出时建议使用ngx.exit 函数进行退出, 防止用户 线程一直在后台空操作
function _M:thread_start( _time_out)
	-- body
	if not self.proc_cb then
		return false
	end

	if self.co then
		kill(self.co)
	end
	self.time_out = _time_out 

	self.co = spawn(self.proc_cb,self.obj) 
	if not self.co then
		return false end

	return true
end	

-- -- 线程内部循环函数
-- function _M:main_loop( )
-- 	-- body
-- 	while not self.exit_flag do  
-- 		local res,pres = pcall(self.proc_cb,self.obj)
-- 		if not res or not pres then
-- 			self.exit_flag = false
-- 			return -1
-- 		end
-- 	end 
-- 	return 1 
-- end

-- 退出 
function _M:exit( _code )
	-- body
	if not _code then _code = -1 end
	self.exit_flag = true
	self.obj.exit_flag = true
	return _code
end

-- 强制退出 如果用户线程为强制性回调,则进行强行kill操作
function _M:kill( )
	-- body
	if self.co then
		kill(self.co)
		self.co = nil
	end
end

return _M