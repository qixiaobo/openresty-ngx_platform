--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:machine_records.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  机器投币和返回记录
--]]

local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local api_data_help = require "common.api_data_help"



local _API_FUNC = {
	
} 
 
--[[
-- get_user_machine_records 用户历史投币/获奖记录
--  
-- example 
    curl 127.0.0.1/game/machine/district_machine/get_districts.action?user_code=xxx&user_token=xxx 
-- @return 返回列表区服服务器数据和当前区服的人数数量,空闲机器
--]]
_API_FUNC.get_user_machine_records = function()
	-- body
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return api_data_help.new(ZS_ERROR_CODE.REDIS_NEW_ERR,'服务器异常,请稍后再试')
    end  
   
	local res, err = redis_cli:hgetall("coin_machine_districts_map")
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.REDIS_OPT_ERR,'服务器异常,请稍后再试')  
    end 

    local resM = db_json_help.redis_hmap_json(res) 
  	return api_data_help.new_success(resM) 


end




return _API_FUNC
