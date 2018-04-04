--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:redis_queue.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  消息队列,主要完成系统对未操作成功的队列执行的记录,由系统任务队列 对程序进行管理业务处理
--	
--]]

local cjson = require "cjson"
local uuid_help = require "common.uuid_help" 
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local pre_config = require "conf.pre_config"
local incr_help = require "common.incr_help"


local _M = {}



_M.push_redis_queue = function ( _task_list_name ,_data_str )
	-- body
 	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 
   
    local res, err =redis_cli.rpush(_task_list_name,_data_str)
    if not res then
    	 ngx.log(ngx.ERR,"push_redis_queue rpush error _task_list_name: ", _task_list_name," ",_data_str)
    	return nil
    end
    return true;

end
 


return _M


