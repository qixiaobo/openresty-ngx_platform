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

local menu_dao = require "admin.model.menu_dao"

local _API_FUNC = {
	
}
 
--[[
-- add_menu 添加菜单功能接口
--  
-- example 
    curl 127.0.0.1/admin/api/menu/add_menu.action?menu_name=test_menu_name
    参数包括 
    	menu_name 菜单名称			必须
    	menu_index 菜单排序 			非  一般在单独编辑时进行位置排序处理, 添加时如果指定了位置,那么原位置的菜单将自动切换到最后
    	action_url  菜单地址			非  该数据需要转码一次, 也可以通过post的方式将数据传递进系统
    	parent_id 上一级菜单的id		非
    	action_target 点击菜单打开方式 非
    	auth_id 绑定的权限			非
    	class_name 该菜单的效果类		非

-- @return  
--]]
_API_FUNC.add_menu = function()
	-- body
	local args = ngx.req.get_uri_args()
	-- 判断参数
	if not args.menu_name then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "menu_name is nil!")
	end

	local menu = { 
		menu_name = args["menu_name"],
		menu_index = args["menu_index"],
		action_url = args["action_url"],
		parent_id_fk = args["parent_id"],
		action_target = args["action_target"],
		auth_id_fk = args["auth_id"],
		class_name = args["class_name"],
	} 
	local res,err = menu_dao.add_menu(menu) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end
 
end
 

--[[
-- update_menu 修改菜单功能接口
--  
-- example 
    curl 127.0.0.1/admin/api/menu/update_menu.action?menu_name=test_menu_name11\&menu_id=16
    参数包括 
    	menu_id   菜单主键 			必须
    	menu_name 菜单名称			非
    	menu_index 菜单排序 			非  一般在单独编辑时进行位置排序处理, 添加时如果指定了位置,那么原位置的菜单将自动切换到最后
    	action_url  菜单地址			非  该数据需要转码一次, 也可以通过post的方式将数据传递进系统
    	parent_id 上一级菜单的id	非
    	action_target 点击菜单打开方式 非
    	auth_id 绑定的权限			非
    	class_name 该菜单的效果类		非

-- @return  
--]]
_API_FUNC.update_menu = function()
	-- body
	local args = ngx.req.get_uri_args()
	-- 判断参数
	if not args["menu_id"] then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "menu_id is nil!")
	end

	local menu = {
		id_pk = args["menu_id"] ,
		menu_name = args["menu_name"],
		menu_index = args["menu_index"],
		action_url = args["action_url"],
		parent_id_fk = args["parent_id"],
		action_target = args["action_target"],
		auth_id_fk = args["auth_id"],
		class_name = args["class_name"],
	} 

	local res,err = menu_dao.update_menu(menu) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end 
end


--[[
-- delete_menu 删除菜单功能接口
--  
-- example 
    curl 127.0.0.1/admin/api/menu/delete_menu.action?menu_id=16
    参数包括 
    	menu_id   菜单主键 			必须
     

-- @return  
--]]
_API_FUNC.delete_menu = function()
	-- body
	local args = ngx.req.get_uri_args()
	-- 判断参数
	if not args["menu_id"] then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "menu_id is nil!")
	end  

	local res,err = menu_dao.delete_menu(args["menu_id"]) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end 
end


--[[
-- get_menu_details 查询获得商品的详情
--  
-- example 
    curl 127.0.0.1/admin/api/menu/get_menu_details.action?menu_id=15
		menu_id   菜单主键 			必须

-- @param goods_code 商品编号
-- @return 查询商品详情
--]]
_API_FUNC.get_menu_details = function()
	-- body
	local args = ngx.req.get_uri_args()
	-- 判断参数
	if not args["menu_id"] then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "menu_id is nil!")
	end  

	local res,err = menu_dao.get_menu_details( tonumber(args["menu_id"]) ) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end 
 
end

--[[
-- get_goods_details 查询获得商品的详情
--  
-- example 
    curl 127.0.0.1/admin/api/menu/get_menu_tree.action?menu_id=15&depth=1
		menu_id   菜单主键 			必须
		depth 	循环的深度			非
-- @param goods_code 商品编号
-- @return 查询商品详情
--]]
_API_FUNC.get_menu_tree = function()
	-- body
	local args = ngx.req.get_uri_args()
	-- 判断参数
	 
	local res,err = menu_dao.get_menu_tree( tonumber(args["menu_id"]), tonumber(args["depth"])) 
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end 
 
end

return _API_FUNC