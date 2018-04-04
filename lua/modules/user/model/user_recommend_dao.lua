--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:game_account.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  用户推荐表
--	
--]]

local pre_config = require "conf.pre_config"
local time_help = require "common.time_help"  
local incr_help = require "common.incr_help"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"

local _M = {}

--[[
    @brief: 
             新增账号推荐信息
    @param:  
            [_user_recommend_tbl:table] 用户账户信息
    @return：
            true 创建成功 false 创建失败
]]
function _M.add_user_recommend_info(_user_recommend_tbl, _db) 
    if not _user_recommend_tbl or type(_user_recommend_tbl) ~= 'table' then
        return false, "参数错误, [_user_recommend_tbl] 错误."
    end 

    if not _user_recommend_tbl.user_id_fk or _user_recommend_tbl.user_id_fk == '' then
        return false, "参数错误, [user_id_fk] 错误."
    end 

    if not _user_recommend_tbl.recommend_id_fk or _user_recommend_tbl.recommend_id_fk == '' then
        return false, "参数错误, [recommend_id_fk] 错误."
    end 

    --查询改id是否已经存在
    local sql = "select * from t_user where user_id = '".._user_recommend_tbl.recommend_id_fk.."';"
    local res, code, err = mysql_db:exec_query(sql, _db) 
    if not res then
        return false, err;
    else
        if not res[1] then
            return false, "用户ID: ".._user_recommend_tbl.recommend_id_fk.." 不存在."
        end
    end

    local sql = "select * from t_user where user_id = '".._user_recommend_tbl.user_id_fk.."';"
    local res, code, err = mysql_db:exec_query(sql, _db) 
    if not res then
        return false, err;
    else
        if not res[1] then
            return false, "用户ID: ".._user_recommend_tbl.user_id_fk.." 不存在."
        end
    end
 
    --防止重复信息
    local sql = "select * from t_user_recommend where user_id_fk = '"
    sql = sql.._user_recommend_tbl.user_id_fk.."' and recommend_id_fk = '"
    sql = sql.._user_recommend_tbl.recommend_id_fk.."';"
    local res, code, err = mysql_db:exec_query(sql, _db) 
    if not res then
        return false, err;
    else
        if res[1] then
            return false, "用户推荐信息已经存在.";
        end
    end

    local sql = mysql_help.insert_help("t_user_recommend", _user_recommend_tbl)
    local res, code, err = mysql_db:exec_query(sql, _db) 
    if not res then
        return false, err;
    end 
    
    return true, "添加用户推荐信息成功."
end

--[[
    @brief: 
            获取所有用户推荐信息
    @param: 
    @return: 
            true: 获取信息成功  false: 获取信息失败    
]]
_M.get_all_user_recommend_info = function ()
    local sql = "SELECT * FROM t_user_recommend "
    local res, msg = mysql_db:exec_once(sql)
    if not res then
        return false, "数据库操作异常."
    end

    if not res[1] then
        return false, "没用用户信息."
    end
    return true, "获取用户信息成功.", res
end

--[[
    @brief: 
            获取用户所有推荐信息 指该用户推荐的所有其他用户信息
    @param: 
    		[_recommend_id:string] 推荐人ID
    @return: 
            true: 获取信息成功  false: 获取信息失败    
]]
_M.get_user_recommend_info_by_id = function (_recommend_id)
	if not _recommend_id or _recommend_id == '' then
		return false, "参数错误， [_recommend_id] 错误."
	end

    local sql = "SELECT * FROM t_user_recommend where recommend_id_fk=".._recommend_id..";"
    local res, msg = mysql_db:exec_once(sql)
    if not res then
        return false, "数据库操作异常."
    end

    if not res[1] then
        return false, "没用该用户推荐信息."
    end
    return true, "获取用户信息成功.", res
end

--[[
    @brief: 
            获取用户被推荐信息 指该用户被其它用户推荐信息
    @param: 
    		[_user_id:string] 被推荐人ID
    @return: 
            true: 获取信息成功  false: 获取信息失败    
]]
_M.get_user_recommend_info_by_id = function (_user_id)
	if not _user_id or _user_id == '' then
		return false, "参数错误， [_user_id] 错误."
	end

    local sql = "SELECT * FROM t_user_recommend where user_id_fk=".._user_id..";"
    local res, msg = mysql_db:exec_once(sql)
    if not res then
        return false, "数据库操作异常."
    end

    if not res[1] then
        return false, "没用用户推荐信息."
    end
    return true, "获取用户信息成功.", res[1]
end

return _M