--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_account.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  查询用户账户信息, 
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


local args = request_help.getAllArgs()	

local user_name = args['user_name']
local user_code = args['user_code']
local user_token = args['user_token']




if not user_name or not user_token or not user_code then 
	 ngx.say(api_data_help.new_failed('user_name or token can not be null!'))	 
	 return 
end

local game_account_dao = require "game.model.game_account_dao"
local res = game_account_dao.get_game_account(user_code)
if not res then
	ngx.say(api_data_help.new_failed('用的用户账户信息失败,请稍后再试!'))	 
	return 
end

ngx.say(api_data_help.new_success(res))	  
