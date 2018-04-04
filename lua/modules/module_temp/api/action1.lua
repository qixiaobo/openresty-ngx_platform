--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:action1.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  xxx.action api 访问模式, 本文件主要实现权限相关测试与界面模版调用
--  
--]]

--[[ 1, 引入常用函数 当前函数一般入口类必选,用于json编码解码, 请求帮助, 以及 输出结构化处理 ]]
local cjson = require "cjson"  
local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help"



--[[
	2, 引入功能类函数 和 dao 函数集合
]]
local time_help = require "common.time_help"
local admin_log_dao = require "admin.model.admin_log_dao"
-- ......


-- 定义该类功能的集合
local _API_FUNC = {
	
}

--[[
-- get_logs 获得操作日志
--  
-- example 
    curl 127.0.0.1/module_temp/api/action1/get_logs.action?id=xx
	  
-- @param id   操作人员id 	必须
-- @param log_type 日志类型 非
-- @param _start_index	非 与_offsets 成对出现
-- @param _offsets		非 _start_index 成对出现
-- @param _start_time		非 _end_time 成对出现
-- @param _end_time		非 _start_time 成对出现
-- @return 查询商品详情
--]]
_API_FUNC.get_logs = function()
	-- body
	local args = ngx.req.get_uri_args()
	-- 判断参数
 	if not args._start_index then
 		args._start_index = 0
 	end
 	if not args._offsets then
 		args._offsets = 20
 	end


	local res,err = admin_log_dao.get_logs(args.id, args._start_index, args._offsets, args._start_time, args._end_time  ) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end 
 
end
--[[
-- test 测试功能
--  
-- example 
    curl 127.0.0.1/module_temp/api/action1/test.action
	 
-- @param none	 
-- @return 查询商品详情
--]]
_API_FUNC.test = function()
	-- body
	local args = ngx.req.get_uri_args()
	-- 判断参数
 	if not args._start_index then
 		args._start_index = 0
 	end
 	if not args._offsets then
 		args._offsets = 20
 	end


	local res,err = admin_log_dao.get_logs(args.id, args._start_index, args._offsets, args._start_time, args._end_time  ) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end 
 
end

return _API_FUNC