--[[
    
]]
local db_mysql = require "common.db.db_mysql"
local sql_manager = require "common.db.sql_manager"

local _M = {}


--[[
    查询获取渠道信息
    @param: [_id]
    @param: [_name]
    @param: [_phone]
    @param: [_email]

    @return:
]]
function _M.select(_id, _name, _phone, _email)
    local s = ""
    s = sql_manager.append(s, "bizorg_id", _id, "OR")
    s = sql_manager.append(s, "bizorg_name", _name, "OR")
    s = sql_manager.append(s, "phone_number", _phone, "OR")
    s = sql_manager.append(s, "email", _email, "OR")

    if (string.len(s) <= 0) then
        return nil, "参数错误"
    end

    local sql = "SELECT id_pk, bizorg_id, bizorg_name, password, bizorg_logo, phone_number, email, area_code, state "
    sql = sql .. "FROM t_bizorg WHERE " .. s .. ";"
    return db_mysql:exec_once(sql)
end

--[[
    获取所有渠道商信息
]]
function _M.select_all()
    local sql = "SELECT id_pk, bizorg_id, bizorg_name, bizorg_logo, phone_number, email, area_code, state "
    sql = sql .. "FROM t_bizorg;"
    return db_mysql:exec_once(sql)
end

--[[
    插入新渠道信息
    @param: [_id]
    @param: [_name]
    @param: [_phone]
    @param: [_email]

    @return:
]]
function _M.insert(_id, _logo, _name, _phone, _email, _password, _area_code, _state)
    local sql =
        "INSERT INTO t_bizorg (bizorg_id, bizorg_logo, bizorg_name, password, phone_number, email, area_code, state) "
    sql =
        string.format(
        "%s VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s')",
        sql,
        _id,
        _logo,
        _name,
        _password,
        _phone,
        _email,
        _area_code or "0086",
        _state or "NULL"
    )

    return db_mysql:exec_once(sql)
end

--[[
    绑定用户和渠道
    @param: [_channel_id]
    @param: [_user_id]
    @param: []
    @param: []
]]
function _M.bind_user_channel(_channel_id, _user_id, _bizorg_user_id, _bizorg_user_no)
    local params = {
        bizorg_id_fk = _channel_id,
        user_id_fk = _user_id,
        bizorg_user_id = _bizorg_user_id,
        bizorg_user_no = _bizorg_user_no
    }
    local sql = sql_manager.fmt_insert("t_bizorg_user", params)
    return db_mysql:exec_once(sql)
end


function _M.delete( )
end

--[[
    更新渠道商信息
    @param: [id] 渠道商ID
    @param: [phone] 手机号
    @param: [area_code] 手机号区号
    @param: [email] 邮件地址
]]
function _M.update(id, phone, area_code, email)
    local s = ""
    s = sql_manager.append(s, 'phone_number', phone, ",")
    s = sql_manager.append(s, 'area_code', area_code, ",")
    s = sql_manager.append(s, 'email', email, ",")
    if string.len(s) <= 0 then
        return nil, "参数未设置"
    end

    local sql = string.format("UPDATE t_bizorg SET %s WHERE bizorg_id='%s';", s, id)
    return db_mysql:exec_once(sql)
end



return _M
