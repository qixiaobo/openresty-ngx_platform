local uuid_help = require "common.uuid_help"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"

local _M = {}

--[[
    @brief: 
            查询公告记录
    @param: 
    		[_condition_tbl:table] 查询条件参数
    			{
					news_no = "", --系统自动生成
					news_title = "",
					news_time = "", --数据库插入自动生成
					publish_id_fk = "",
					news_content = "",
					preview_img = "",
					news_state = "",
					subject_no_fk = "", --不是必须
					key_words = "", --不是必须
					bizorg_id_fk = ""
    			}
    @return: 
            true: 成功  false: 失败    
]]
function _M.get_notices_by_condition(_condition_tbl)
	if not _condition_tbl or type(_condition_tbl) ~= 'table' then
		return false, '参数错误, [_condition_tbl] 错误.'
	end

	local condition = {}
	condition.news_no = _condition_tbl.news_no
	condition.news_title = _condition_tbl.news_title
	condition.news_time = _condition_tbl.news_time
	condition.publish_id_fk = _condition_tbl.publish_id_fk
	condition.news_content = _condition_tbl.news_content
	condition.preview_img = _condition_tbl.preview_img
	condition.news_state = _condition_tbl.news_state
	condition.subject_no_fk = _condition_tbl.subject_no_fk
	condition.key_words = _condition_tbl.key_words
	condition.bizorg_id_fk = _condition_tbl.bizorg_id_fk

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

--[[
    @brief: 
            判断公告是否已经存在
            判断依据：
            		新闻标题[news_title] 
            		发布人[publish_id_fk]
            		新闻内容[news_content]
            		新闻所属栏目[subject_no_fk]
            		所属公司[bizorg_id_fk]

    @param: 
    		[_notice_info_tbl:table] 消息日志参数表
    			{
					news_no = "", --系统自动生成
					news_title = "",
					news_time = "", --数据库插入自动生成
					publish_id_fk = "",
					news_content = "",
					preview_img = "",
					news_state = "",
					subject_no_fk = "", --不是必须
					key_words = "", --不是必须
					bizorg_id_fk = ""
    			}
    @return: 
            true: 添加成功  false: 添加失败    
]]
local function notice_is_exist(_notice_info_tbl)
	local res, err = _M.get_notices_by_condition(_notice_info_tbl)
	if not res then
		return false, err
	end

	return res[1] and true or false
end

--[[
    @brief: 
            添加一条通告
    @param: 
    		[_notice_info_tbl:table] 消息日志参数表
    			{
					news_no = "", --系统自动生成
					news_title = "",
					news_time = "", --数据库插入自动生成
					publish_id_fk = "",
					news_content = "",
					preview_img = "",
					news_state = "",
					subject_no_fk = "", --不是必须
					key_words = "", --不是必须
					bizorg_id_fk = ""
    			}
    @return: 
            true: 添加成功  false: 添加失败    
]]
function _M.add_one_msg(_notice_info_tbl)
	if not _notice_info_tbl or type(_notice_info_tbl) ~= 'table'
		or not _notice_info_tbl.news_title or _notice_info_tbl.news_title == '' 
		or not _notice_info_tbl.publish_id_fk or _notice_info_tbl.publish_id_fk == ''
		or not _notice_info_tbl.news_content or _notice_info_tbl.news_content == ''
		or not _notice_info_tbl.bizorg_id_fk or _notice_info_tbl.bizorg_id_fk == ''
	then
		return false, "参数错误, [_notice_info_tbl] 错误."
	end

	--默认关键字为公告标题
	if not _notice_info_tbl.key_words or _notice_info_tbl.key_words == '' then
		_notice_info_tbl.key_words = _notice_info_tbl.news_title
	end

	--默认添加的公告都为首页公告
	if not _notice_info_tbl.subject_no_fk or _notice_info_tbl.subject_no_fk == '' then
		_notice_info_tbl.subject_no_fk = '首页公告'
	end

	--判断公告是否已经存在
	local res, err = notice_is_exist(_notice_info_tbl)
	if res then
		return false, "公告已经存在, 请勿重复添加."
	else
		if err then
			return false, err
		end
	end

	_notice_info_tbl.news_no = uuid_help.get()

	local sql = mysql_help.insert_help("t_news", _notice_info_tbl)
    local res, err = mysql_db:exec_once(sql) 
    if not res then
        return false, err;
    end 
    
    return true, "添加成功."
end

return _M