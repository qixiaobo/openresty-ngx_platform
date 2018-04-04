--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:admin_manager.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  管理员后台api 管理接口
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

local admin_dao = require "admin.model.admin_dao"

local _API_FUNC = {}

--[[
-- add_admin_account 添加管理员账号,对于root用户无效
--  
-- example 
    curl 127.0.0.1/admin/api/admin_manager/add_admin_account.action?admin_name=xxx&password=xxxxx&mobile_number=xxx&email=xxx&status=disabled
    参数包括 
    	admin_name	管理员ID  		必须
    	password 		管理员密码 		必须
    	mobile_number   后台用户手机号	必须
    	email           后台用户邮箱		必须
    	status 			用户状态			非 不上传或者状态不等于指定的字符串,都将默认设置为 disabled
    	role_id			角色外键			非 如果存在角色id 则添加用户所在角色表,如果存在该记录则更新,不存在则添加
-- @return  
--]]
_API_FUNC.add_admin_account =
	function()
	-- body
	local args = ngx.req.get_uri_args()

	-- 判断参数
	if not args.id or not args.status then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "id , status is nil!", cjson.encode(args))
	end

	local _admin = {
		name = args.admin_name,
		password = args.password,
		mobile_number = args.mobile_number,
		email = args.email,
		status = args.status and args.status or "disabled",
		role_id = args.role_id
	}

	local res, err = admin_dao.admin_add(_admin)
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end
end

--[[
-- update_status 修改管理员的状态,对于root用户无效
--  
-- example 
    curl 127.0.0.1/admin/api/admin_manager/update_status.action?id=2&status=disabled
    参数包括 
    	id			管理员ID  			必须
    	status 		设置的管理员状态 		必须
-- @return  
--]]
_API_FUNC.update_status =
	function()
	-- body
	local args = ngx.req.get_uri_args()

	-- 判断参数
	if not args.id or not args.status then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "id , status is nil!", cjson.encode(args))
	end

	local _admin = {
		id_pk = args.id,
		status = args.status
	}

	local res, err = admin_dao.admin_update(_admin)
	if not res then
		return api_data_help.system_error()
	else
		return api_data_help.new_success(res)
	end
end

function _API_FUNC.login()
	local args = ngx.req.get_uri_args()
	local name = args["name"]
	local password = args["password"]

	if not name or not password then
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "Param error.")
	end

	local res = admin_dao.login(name, password)
	if not res then
		return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "ERROR")
	end

	local token = admin_dao.create_token(name)
	return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "Successful.", {token = token})
end

return _API_FUNC
