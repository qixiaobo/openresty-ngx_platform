--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:menu.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  menu 菜单相关管理接口,该接口提供菜单的增删改查以及菜单的权限相关功能
--  
--]]



local cjson = require "cjson"  
local uuid_help = require "common.uuid_help"  
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local db_json_help = require "common.db.db_json_help"

local time_help = require "common.time_help"  
local incr_help = require "common.incr_help"

local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help"

local admin_log_dao = require "admin.model.admin_log_dao"
  
local _API_FUNC = {
	
}

--[[
-- get_logs 查询日志
--  
-- example 
    curl 127.0.0.1/admin/api/admin_log/get_logs.action?id=15
		id   操作人员id 	
		log_type 日志类型
		_start_index
		_offsets
		_start_time	
		_end_time
	

-- @param goods_code 商品编号
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


return _API_FUNC