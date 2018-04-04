local uuid_help = require "common.uuid_help"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"

local _M = {}

--[[
    @brief: 
            添加一条消息日志
    @param: 
    		[_msg_info_tbl:table] 消息日志参数表
    			{
					msg_id = "", --系统自动生成
					msg_type = "",
					msg_sender_no = "",
					msg_recv_no = "",
					attachment = "",
					msg_title = "",
					msg_content = "",
					send_time = "", --不是必须
					rec_time = "", --不是必须
					msg_state = "",
					msg_attach = ""
    			}
    @return: 
            true: 添加成功  false: 添加失败    
]]
function _M.add_one_msg(_msg_info_tbl)
	if not _msg_info_tbl or type(_msg_info_tbl) ~= 'table'
		or not _msg_info_tbl.msg_type or _msg_info_tbl.msg_type == '' 
		--or not _log_info_tbl.msg_sender_no or _log_info_tbl.msg_sender_no == ''
		or not _msg_info_tbl.msg_recv_no or _msg_info_tbl.msg_recv_no == ''
		or not _msg_info_tbl.msg_title or _msg_info_tbl.msg_title == ''
		or not _msg_info_tbl.msg_content or _msg_info_tbl.msg_content == ''
		or not _msg_info_tbl.msg_state or _msg_info_tbl.msg_state == ''
	then
		return false, "参数错误, [_msg_info_tbl] 错误."
	end

	if not _msg_info_tbl.msg_sender_no or _msg_info_tbl.msg_sender_no == '' then
		_msg_info_tbl.msg_sender_no = "系统"
	end

	_msg_info_tbl.msg_id = uuid_help.get()

	local sql = mysql_help.insert_help("t_messages", _msg_info_tbl)
    local res, code, err = mysql_db:exec_once(sql) 
    if not res then
        return false, err;
    end 
    
    return true, "添加成功."
end

--[[
    @brief: 
            查询消息记录
    @param: 
    		[_condition_tbl:table] 查询条件参数
    			{
					msg_id = "", --系统自动生成
					msg_type = "",
					msg_sender_no = "",
					msg_recv_no = "",
					attachment = "",
					msg_title = "",
					msg_content = "",
					send_time = "", --不是必须
					rec_time = "", --不是必须
					msg_state = "",
					msg_attach = ""
    			}
    @return: 
            true: 成功  false: 失败    
]]
function _M.get_msg_by_condition(_condition_tbl)
	if not _condition_tbl or type(_condition_tbl) ~= 'table' then
		return false, '参数错误, [_condition_tbl] 错误.'
	end

	local condition = {}
	condition.msg_id = _condition_tbl.msg_id
	condition.msg_type = _condition_tbl.msg_type
	condition.msg_sender_no = _condition_tbl.msg_sender_no
	condition.msg_recv_no = _condition_tbl.msg_recv_no
	condition.attachment = _condition_tbl.attachment
	condition.msg_title = _condition_tbl.msg_title
	condition.msg_content = _condition_tbl.msg_content
	condition.send_time = _condition_tbl.send_time
	condition.rec_time = _condition_tbl.rec_time
	condition.msg_state = _condition_tbl.msg_state
	condition.msg_attach = _condition_tbl.msg_attach

	local sqlwheresuffix = ""
	for k,v in pairs(condition) do
		if sqlwheresuffix == "" then
			sqlwheresuffix ="where".." "..k.."="..ngx.quote_sql_str(v)
		else
			sqlwheresuffix = sqlwheresuffix.."and "..k.."="..ngx.quote_sql_str(v)
		end
	end

	local sql = string.format("select * from t_messages %s;", sqlwheresuffix)
	local res, err = mysql_db:exec_once(sql) 
    if not res then
        return false, err;
    end 

    return true, res
end


return _M