local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"

local _M = {}

--[[
    @brief: 
            添加一条执行日志
    @param: 
    		[_log_info_tbl:table] 执行日志参数表
    			{
					opt_no = "",
					ask_for_no_fk = "",
					ask_for_state = "",
					opt_time = "",
					opt_id_fk = "",
					opt_state = "",
					next_opt_id_fk = ""
    			}
    @return: 
            true: 添加成功  false: 添加失败    
]]
function _M.add_one_log(_log_info_tbl)
	if not _log_info_tbl or type(_log_info_tbl) ~= 'table'
		or not _log_info_tbl.opt_no or _log_info_tbl.opt_no == '' 
		or not _log_info_tbl.ask_for_no_fk or _log_info_tbl.ask_for_no_fk == ''
		or not _log_info_tbl.ask_for_state or _log_info_tbl.ask_for_state == ''
		or not _log_info_tbl.opt_id_fk or _log_info_tbl.opt_id_fk == ''
		or not _log_info_tbl.opt_state or _log_info_tbl.opt_state == ''
		or not _log_info_tbl.next_opt_id_fk or _log_info_tbl.next_opt_id_fk == ''
	then
		return false, "参数错误, [_log_info_tbl] 错误."
	end

	local sql = mysql_help.insert_help("t_ask_for_channel_log", _log_info_tbl)
    local res, err = mysql_db:exec_once(sql) 
    if not res then
        return false, err;
    end 
    
    return true, "添加日志成功."
end

--[[
    @brief: 
            查询执行日志
    @param: 
    		[_condition_tbl:table] 查询条件参数
    			{
					opt_no = "",
					ask_for_no_fk = "",
					ask_for_state = "",
					opt_time = "",
					opt_id_fk = "",
					opt_state = "",
					next_opt_id_fk = ""
    			}
    @return: 
            true: 成功  false: 失败    
]]
function get_log_by_condition(_condition_tbl)
	if not _condition_tbl or type(_condition_tbl) ~= 'table' then
		return false, '参数错误, [_condition_tbl] 错误.'
	end

	local condition = {}
	condition.opt_no = _condition_tbl.opt_no
	condition.ask_for_no_fk = _condition_tbl.ask_for_no_fk
	condition.ask_for_state = _condition_tbl.ask_for_state
	condition.opt_time = _condition_tbl.opt_time
	condition.opt_id_fk = _condition_tbl.opt_id_fk
	condition.opt_state = _condition_tbl.opt_state
	condition.next_opt_id_fk = _condition_tbl.next_opt_id_fk

	local sqlwheresuffix = ""
	for k,v in pairs(condition) do
		if sqlwheresuffix == "" then
			sqlwheresuffix ="where".." "..k.."="..ngx.quote_sql_str(v)
		else
			sqlwheresuffix = sqlwheresuffix.."and "..k.."="..ngx.quote_sql_str(v)
		end
	end

	local sql = string.format("select * from t_ask_for_channel_log %s;", sqlwheresuffix)
	local res, code, err = mysql_db:exec_once(sql) 
    if not res then
        return false, err;
    end 

    return true, res
end

return _M