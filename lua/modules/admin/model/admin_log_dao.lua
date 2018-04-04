--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:admin_log_dao.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  admin log 管理对象, 系统所有的操作都需要进行log日志记录,包括登录,增删改等
--  
--]]

local cjson = require "cjson"
local mysql = require "common.db.db_mysql"  
local uuid_help = require "common.uuid_help"  
local mysql_db = require "common.db.db_mysql"   
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help" 
local db_json_help = require "common.db.db_json_help"


local time_help = require "common.time_help"  
local incr_help = require "common.incr_help"


local  cjson = require "cjson"

local  log = ngx.log

local _M = {
-- 1	id_pk	bigint	20	0	0			0	0	0
-- 0	content	varchar	256	0	0		操作类容			0
-- 0	log_type	varchar	256	0	0		日志类型, 主要分为增删改查等不同类型			0
-- 0	opt_id_fk	int	32	0	0		操作人员id	0	0	0
-- 0	opt_time	timestamp	0	0	0	CURRENT_TIMESTAMP		0 
}
  
--[[
-- _M.get_log 查看操作log, 如果提供 id_pk 则表示查询指定用户的log
-- example 

-- @param  
-- @param _password 	返回消息的主体 

--]]
function _M.get_logs(_id_pk, _start_index, _offsets,_start_time,_end_time)
 	local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   
    local str,_size = mysql_help.select_help(" select * from t_admin_log ", {opt_id_fk = _id_pk},"and" )  
    local time_str =""
    if _start_index and _end_time then 
        if _size == 0 then
            time_str = string.format(" where t_admin_log.transaction_time >= '%s' and t_admin_log.transaction_time <= '%s'  ", 
                           _start_time, _end_time)  
        else
            time_str = string.format(" and t_admin_log.transaction_time >= '%s' and t_admin_log.transaction_time <= '%s'  ", 
                           _start_time, _end_time)  
        end     
    end 
    str = str .. time_str .. string.format(" limit %d , %d",_start_index,_offsets)
    ngx.log(ngx.ERR,"sql -str ",str)
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    
    return res,errcode; 
end
 
--[[
-- _M.add_log 添加日志
-- example

-- @param  _menu 
-- @return res nil 表示失败 其他表示成功 如 {"insert_id":16,"affected_rows":1,"server_status":2,"warning_count":0}
--]]
function _M.add_log( _id_pk, _content, _log_type )
	local db = mysql:new() 
	if not db then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"mysql new db is nil")
		return 	nil 
	end
	local _log={
		opt_id_fk = _id_pk,
		content = _content,
		log_type = _log_type,
	}
	-- 执行存储过程
 	local srcSql = mysql_help.insert_help("t_admin_log",_log) 
	-- 如果是root用户,则系统需要未来主义,该账户只能在本地以及指定的IP上登陆 
	-- local srcSql = string.format("select * from t_menu_action;");  
	 
	local res, err, errno, sqlstate = db:query(srcSql) 
	if not table.isnull(res) then
		ngx.log(ngx.ERR,"err code ",err," errno ",errno)
	    return nil;
	end   
 	return res
end
  
 
 
return _M
