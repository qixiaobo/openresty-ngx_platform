--[[
    用户扩展数据 相关的数据库访问数据库访问功能,
]]

local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local uuid_help = require "common.uuid_help":new(ZS_USER_NAME_SPACE)


local _M = {}

--[[
    @brief: 
             新增用户扩展信息,系统默认创建时新增
    @param:  
            [_user_ex_tbl:table] 用户扩展信息
    @return：
            true 创建成功 false 创建失败
]]
_M.add_user_ex = function (_user_ex_tbl, _db)
    if not _user_ex_tbl or type(_user_ex_tbl) ~= 'table' then
        return false, "参数错误, [_user_ex_tbl] 错误."
    end 

    if not _user_ex_tbl.user_id_fk or _user_ex_tbl.user_id_fk == '' then
        return false, "参数错误, [user_id_fk] 错误."
    end 

    --查询改id是否已经存在
    local sql = "select * from t_user where user_id = '".._user_ex_tbl.user_id_fk.."';"
    local res, code, err = mysql_db:exec_query(sql, _db) 
    if not res then
        return false, err;
    else
        if not res[1] then
            return false, "用户ID: ".._user_ex_tbl.user_id_fk.." 不存在."
        end
    end
 
    --查询该用户是否已经存在账户
    local sql = "select * from t_user_ext_info where user_id_fk = '".._user_ex_tbl.user_id_fk.."';"
    local res, code, err = mysql_db:exec_query(sql, _db) 
    if not res then
        return false, err;
    else
        if res[1] then
            return false, "用户ID: ".._user_ex_tbl.user_id_fk.." 已经存在账户.";
        end
    end

    local sql = mysql_help.insert_help("t_user_ext_info", _user_ex_tbl)
    local res, code, err = mysql_db:exec_query(sql, _db) 
    if not res then
        return false, err;
    end 
    
    return true, "创建账户成功."
end

--[[
    @brief: 
            更新用户扩展信息数据库
    @param: 
            [_user_id:string] 用户唯一ID
            [_user_ex：table] 用户参数表 针对t_user_ext_info表
    @return: 
            true: 更新成功; false: 更新失败     
]]
_M.update_user_ex = function (_user_id, _user_ex) 
    local condition_tbl = {}
    condition_tbl.user_id_fk = _user_id

    local sql = mysql_help.update_help("t_user_ext_info", _user_ex, condition_tbl)
    ngx.log(ngx.ERR, "[update_user_ex] sql: ", sql)
    local res, msg = mysql_db:exec_once(sql)
    if not res then
        ngx.log(ngx.ERR, "[update_user_ex] msg: ", (msg and msg or 'nil'))
        return false, msg
    end

    if res.affected_rows > 0 then
        return true
    else
        return false, msg
    end
end
 
--[[
-- get_user_ex 获得用户扩展信息
--  
-- example  
    local _user_code = 'xxxx'
    local res = UserExDao.get_user_ex(user)
-- @param  _user_code 用户唯一编号
-- @return  返回用户个人信息 或者 nil 代表错误
--]]

_M.get_user_ex = function ( user_code ) 
    local sql = string.format("select t_user_ext_info.* from t_user_ext_info where t_user_ext_info.user_code_fk='%s';",  user_code)  
    return mysql_db:exec_once(sql)
end

--[[
    @brief: 
            更改用户头像数据库
    @param:
            [_user_id:string]   用户唯一ID
            [_head_image_url:string] 头像图片地址
    @return:
            true 成功  false 失败 
--]]
_M.change_head_portrait = function (_user_id, _head_image_url)
    local sql = string.format("update t_user_ext_info set head_image='%s' where user_id_fk='%s';", _head_image_url, _user_id)
    local res, err = mysql_db:exec_once(sql)
    if not res then
        return false, err
    end

    if res.affected_rows > 0 then
        return true
    else
        return false, err
    end
end

--[[ 添加用户积分变化详情记录 ]]
_M.add_points_detail = function ( user_code, type, sub_type, points, timestamp, detail, balance)
    local sql = "INSERT INTO t_user_points_detail (user_code_fk, type, sub_type, points, timestamp, detail, balance) "
    sql = sql.. string.format(" VALUES('%s','%s','%s','%s','%s','%s','%s');",user_code,type,sub_type,points,timestamp,detail, balance)
    return mysql_db:exec_once(sql)
end

--[[ 获取用户积分变化详情记录 ]]
_M.get_points_detail = function ( user_code, row_index, size  )
    local sql = "select * from t_user_points_detail where user_code_fk='"..user_code.."' ORDER BY timestamp DESC "
    sql = sql .. "limit " .. row_index .. "," .. size .. ";"
    return mysql_db:exec_once(sql)
end


--[[ 改变用户积分（增加或减少） ]]
_M.update_points = function ( user_code, type, sub_type, change_val, timestamp, detail)
    local sql = string.format("SELECT integral from t_game_account WHERE user_code_fk='%s';", user_code)
    local res, msg = mysql_db:exec_once(sql)
    if not res then
        return nil, ZS_ERROR_CODE.MYSQL_ERR, msg
    end
    if not res[1] then
        return nil, ZS_ERROR_CODE.RE_FAILED, string.format("t_game_account表中无用户[%s]记录", user_code)
    end

    local total = tonumber(res[1].integral) + change_val
    if total < 0 then
        return nil, 0, "用户积分异常" 
    end

    sql = string.format( "UPDATE t_game_account SET integral='%s' WHERE user_code_fk='%s'", total, user_code)
    local res, msg = mysql_db:exec_once(sql)
    if not res then
        return nil, ZS_ERROR_CODE.MYSQL_ERR, msg
    end
    return _M.add_points_detail(user_code, type, sub_type, change_val, timestamp, detail, total)
end


_M.add_balance_detail = function ( user_code, type, sub_type, change_val, timestamp, detail, total)
    local sql = "INSERT INTO t_user_balance_detail (user_code_fk, type, sub_type, change_val, timestamp, detail, balance) "
    sql = sql .. string.format(" VALUES('%s', '%s', '%s', '%s', '%s', '%s', '%s');", user_code, type, sub_type, change_val, timestamp, detail, total)
    return mysql_db:exec_once(sql)
end

_M.get_balance_detail = function ( user_code, row_index, size )
    local sql = "SELECT * from t_user_balance_detail WHERE user_code_fk='"..user_code.."' ORDER BY timestamp DESC "
    sql = sql .. "limit " .. row_index .. "," .. size .. ";"
    return mysql_db:exec_once(sql)
end


_M.update_balance = function ( user_code, type, sub_type, change_val, timestamp, detail)
    local sql = string.format("SELECT balance from t_game_account WHERE user_code_fk='%s';", user_code)
    local res, msg= mysql_db:exec_once(sql)
    if not res then
        return nil, ZS_ERROR_CODE.MYSQL_ERR, msg
    end
    if not res[1] then
        return nil, ZS_ERROR_CODE.RE_FAILED, string.format("t_game_account表中无用户[%s]记录", user_code)
    end

    local total = tonumber(res[1].balance) + change_val
    if total < 0 then
        return nil, 0, "用户钻石异常" 
    end

    sql = string.format( "UPDATE t_game_account SET balance='%s' WHERE user_code_fk='%s'", total, user_code)
    local res, msg = mysql_db:exec_once(sql)
    if not res then
        return nil, ZS_ERROR_CODE.MYSQL_ERR, msg
    end
    return _M.add_balance_detail(user_code, type, sub_type, change_val, timestamp, detail, total)
end


return _M