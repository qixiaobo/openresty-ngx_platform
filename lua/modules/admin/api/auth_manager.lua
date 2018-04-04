	--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:auth_manager.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  权限管理 api 接口
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

local authority_dao = require "admin.model.authority_dao"

local _API_FUNC = {
	
}


--[[
-- get_auths  获得权限数组列表,包含多级关系
--  
-- example 
    curl 127.0.0.1/admin/api/auth_manager/add_auth.action
    参数包括  
    	parent_id       上一级			非 没有则表示角色为顶级角色 


-- @return  
--]]
_API_FUNC.get_auths = function()
	-- body
	local args = ngx.req.get_uri_args()
 	 
 
	local res,err = authority_dao.get_authoritys(args.parent_id) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end
 
end

--[[
-- add_auths 添加权限管理
--  
-- example 
    curl 127.0.0.1/admin/api/auth_manager/add_auth.action
    参数包括 
    	auth_name	    名称  			必须
    	auth_description 		管理员分类 		非
    	auth_level   	用户角色等级		非
    	parent_id       上一级			非 没有则表示角色为顶级权限
    	status 			角色状态		非 如果不传递该值,表示停用
		action_string   权限字符串 以;隔开

-- @return  
--]]
_API_FUNC.add_auth = function()
	-- body
	local args = ngx.req.get_uri_args()
 	if not args.auth_name then  
 		return api_data_help.new_failed("auth_name is null!!")
 	end

	local _auth = { 
		 auth_name = args.auth_name,
		 auth_description = args.auth_description,
		 auth_level = args.auth_level,
		 action_string = args.action_string,
		 status =  args.status and args.status or "disabled", 
	} 

	local res,err = authority_dao.auth_add(_auth) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end
 
end


--[[
-- update_auth 修改管理员的权限修改
--  
-- example 
    curl 127.0.0.1/admin/api/auth_manager/update_auth.action
	参数包括 
		auth_id 		主键 		必须
    	auth_name	    权限名称  			非

    	auth_description 		权限描述 		非
    	auth_level   	权限等级		非
    	parent_id       上一级			非 没有则表示角色为顶级角色
    	status 			权限状态			非 如果不传递该值,表示停用

-- @return  
--]]
_API_FUNC.update_auth = function()
	-- body
	local args = ngx.req.get_uri_args()

	-- 判断参数
	if not args.auth_id  then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "auth_id  is nil!",cjson.encode(args))
	end

	local _auth = { 
		 id_pk = args.auth_id,
		 auth_name = args.auth_name,
		 auth_description = args.auth_description,
		 auth_level = args.auth_level,
		 parent_id_fk = args.parent_id, 
		 status = args.status,
		 action_string = args.action_string,
	} 
	 
	local res,err = authority_dao.update_auth(_auth) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end
 
end
 

--[[
-- del_auth 修改管理员的权限修改
--  
-- example 
    curl 127.0.0.1/admin/api/auth_manager/update_auth.action
	参数包括 
		auth_id 		主键 		必须
     

-- @return  
--]]
_API_FUNC.del_auth = function()
	-- body
	local args = ngx.req.get_uri_args()

	-- 判断参数
	if not args.auth_id  then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "auth_id  is nil!",cjson.encode(args))
	end
 
	local res,err = authority_dao.delete_auth(args.auth_id ) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end
 
end

return _API_FUNC