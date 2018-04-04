local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"

local _M = {}

--[[
    @brief: 
            添加一条操作日志
    @param: 
    		[_msg_info_tbl:table] 操作日志参数表
    			{
					log_type = "",
					opt_id_fk = "",
					opt_content = ''
    			}
    @return: 
            true: 添加成功  false: 添加失败    
]]
function _M.add_one_opt_log(_log_info_tbl)
	if not _log_info_tbl or type(_log_info_tbl) ~= 'table'
		or not _log_info_tbl.log_type or _log_info_tbl.log_type == ''
		or not _log_info_tbl.opt_id_fk or _log_info_tbl.opt_id_fk == ''
		or not _log_info_tbl.opt_content or _log_info_tbl.opt_content == ''
	then
		return false, "参数错误 [_log_info_tbl] 错误."
	end

	local sql = mysql_help.insert_help("t_opt_log", _log_info_tbl)
    local res, code, err = mysql_db:exec_once(sql) 
    if not res then
        return false, err;
    end 
    
    return true, "添加成功."
end

--[[
    @brief: 
            查询操作日志记录
    @param: 
    		[_condition_tbl:table] 查询条件参数
    			{
					log_type = "",
					opt_id_fk = "",
					opt_time = '',
					opt_content = ''
    			}
    @return: 
            true: 成功  false: 失败    
]]
function _M.get_opt_logs_by_condition(_condition_tbl)
	if not _condition_tbl or type(_condition_tbl) ~= 'table' then
		return false, '参数错误, [_condition_tbl] 错误.'
	end

	local condition = {}
	condition.log_type = _condition_tbl.log_type
	condition.opt_id_fk = _condition_tbl.opt_id_fk
	condition.opt_time = _condition_tbl.opt_time
	condition.opt_content = _condition_tbl.opt_content

	local sqlwheresuffix = ""
	for k,v in pairs(condition) do
		if sqlwheresuffix == "" then
			sqlwheresuffix ="where".." "..k.."="..ngx.quote_sql_str(v)
		else
			sqlwheresuffix = sqlwheresuffix.."and "..k.."="..ngx.quote_sql_str(v)
		end
	end

	local sql = string.format("select * from t_opt_log %s;", sqlwheresuffix)
	local res, err = mysql_db:exec_once(sql) 
    if not res then
        return false, err;
    end 

    return true, res
end

return _M