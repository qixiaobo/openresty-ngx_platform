--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:incr_help.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  自增长功能类,主要用于各种唯一性字段增长,不使用redis,减少性能消耗
--]]

local time_help = require "common.time_help"

local _M = {}


--[[
--  get_time_union_id 获得系统唯一编号,系统采用时间编号  主要用于编号类系统,容易查看
-- example
		inir_help.get_time_union_id()

-- @param _key 指定的自增长key
-- @param _start_index 开始累加的字段, 起始默认为 800000
-- @return 返回当前时间+累加的值
--]]
_M.get_time_union_id = function( _key, _start_index )
	-- body
	if not _start_index then _start_index = 800000 end
	local ngx_cache = ngx.shared.ngx_cache  
	if not _key then
		_key = "DefaultKey"
	end
	local newval, err, forcible = ngx_cache:incr(_key,1,_start_index) 
	return os.date("%Y%m%d%H%M%S",os.time())..time_help.current_millis()..SERVER_ID..newval
end 
  
  
local sf = require "snowflake"
-- works 不得超过32线程,如果系统比较强大,可以进行服务器分离操作,用代理服务器进行负载!!!!!!
local workers = ngx.worker.count()  
sf.init(SERVER_ID, workers) 
_M.get_uuid = function( )
	-- body  
	return sf.next_id() 
end

return _M