--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_account.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  查询用户账户信息, 
--]]

local cjson = require "cjson"  
local uuid_help = require "common.uuid_help" 
local time_help = require "common.time_help"  
local incr_help = require "common.incr_help"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help" 
local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help"
local db_json_help = require "common.db.db_json_help"

local user_dao = require "user.model.user_dao"
local user_account_dao = require "user.model.user_account_dao"

local _M = {}

--[[
	@url:	
			user/api/user_account.do
			?user_id=10000012
			&token=xasdas_s[l]_as
	@example: 
			curl 127.0.0.1/user/api/user_account/user_account_info.action?user_id=10000022&token=xasdas_s[l]_as
	@brief:	
			获取用户账号信息
	@param:	
			[user_id:string] 用户唯一ID
			[token:string] token认证
	@return:
			json格式的消息
			example:
			{
				"code" : 200, --状态码
				"msg" : "获取用户账号信息成功.", 
				"data" : -- 用户账号信息
						{
							"account_state":null,
							"user_id_fk":"10000022",
							"account_type":"USER",
							"balance":0,
							"pay_password":null,
							"popularity":0,
							"integral":0,
							"consume_balance":0,
							"currency_type":"",
							"id_pk":"10"
						}
			}		
]]
function _M.user_account_info()
	local args = request_help.getAllArgs()	
	local user_id = args['user_id']
	local token = args['token']
	 
	--检查验证token值
	local res, msg = user_dao.is_keep_alived_login(user_id, token)
	if not res then
	    return  api_data_help.new_failed("请重新登录. "..msg)
	end

	local res, context = user_account_dao.get_user_account_info(user_id)
	if not res then
		return api_data_help.new_failed("获取用户账号信息失败. err: "..context)
	end

	if res then
		return api_data_help.new_success(context)
	else
		return api_data_help.new_failed("获取用户账号信息失败. 没有用户账号信息.")
	end
end

return _M
