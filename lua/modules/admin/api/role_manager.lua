	--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:role_manager.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  角色管理 api 接口
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

local role_dao = require "admin.model.role_dao"

local _API_FUNC = {
	
}




--[[
-- get_roles  获得角色数组列表,包含多级关系
--  
-- example 
    curl 127.0.0.1/admin/api/role_manager/add_role.action
    参数包括 
    	 
    	parent_id       上一级			非 没有则表示所有权限
    	 


-- @return  
--]]
_API_FUNC.get_roles = function()
	-- body
	local args = ngx.req.get_uri_args()
 	 
 
	local res,err = role_dao.get_roles(args.parent_id) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end
 
end

--[[
-- add_role 添加管理员账号,对于root用户无效
--  
-- example post上传
    curl 127.0.0.1/admin/api/role_manager/add_role.action
    参数包括 
    	role_name	    名称  			必须
    	role_description 		管理员分类 		非
    	role_level   	用户角色等级		非
    	parent_id       上一级			非 没有则表示角色为顶级角色
    	status 			角色状态			非 如果不传递该值,表示停用
		auth_list 	[]权限列表

-- @return  
--]]
_API_FUNC.add_role = function()
	-- body
	local args = ngx.req.get_uri_args()
 	if not args.role_name then  
 		return api_data_help.new_failed("role_name is null!!")
 	end

	local _role = { 
		 role_name = args.role_name,
		 role_description = args.role_description,
		 role_level = args.role_level,
		 parent_id_fk = args.parent_id,
		 status =  args.status and args.status or "disabled", 
		
	} 
	local auth_list = args.auth_list
	local res,err = role_dao.add_role(_admin,auth_list) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end
 
end


--[[
-- update_role 修改管理员的状态,对于root用户无效
--  
-- example 
    curl 127.0.0.1/admin/api/role_manager/update_role.action
	参数包括 
		role_id 		主键 		必须
    	role_name	    名称  			非

    	role_description 		管理员分类 		非
    	role_level   	用户角色等级		非
    	parent_id       上一级			非 没有则表示角色为顶级角色
    	status 			角色状态			非 如果不传递该值,表示停用

-- @return  
--]]
_API_FUNC.update_role = function()
	-- body
	local args = ngx.req.get_uri_args()

	-- 判断参数
	if not args.role_id  then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "role_id  is nil!",cjson.encode(args))
	end

	local _role = { 
		 id_pk = args.role_id,
		 role_name = args.role_name,
		 role_description = args.role_description,
		 role_level = args.role_level,
		 parent_id_fk = args.parent_id, 
		 status = args.status,
	} 
	 
	local res,err = role_dao.update_role(_role) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end
 
end


--[[
-- update_role 修改管理员的状态,对于root用户无效
--  
-- example 
    post  127.0.0.1/admin/api/role_manager/update_role_auth.action
	参数包括 
		role_id 		主键 		必须
    post 数据为json数组
		格式为[ {auth_id = 1},{auth_id=2}] 
-- @return  
--]]
_API_FUNC.update_role_auth = function()
	-- body
	local args = ngx.req.get_uri_args()
	local json_obj = request_help.get_post_json()
	-- 判断参数
	if not args.role_id  then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "role_id  is nil!",cjson.encode(args))
	end

	local _auths = {}
	for i=1,#json_obj do
		_auths[i] = {
			role_id_fk = args.role_id,
			auth_id_fk = json_obj[i].auth_id,
		}
	end
	 
	local res,err = role_dao.update_role_auth(args.role_id, _auths) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end
end




return _API_FUNC