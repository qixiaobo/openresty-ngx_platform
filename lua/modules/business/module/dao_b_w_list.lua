local db_mysql = require "common.db.db_mysql"
local sql_manager = require "common.db.sql_manager"

local _M = {}

function _M.get(_ip, _channel_id, type)
    local sql =
        string.format("SELECT * FROM t_black_while_list WHERE ip_address='%s'AND org_id_fk='%s' AND black_white='%s';", _ip, _channel_id, type)
    return db_mysql:exec_once(sql)
end

function _M.get_by_channel_id(_channel_id)
    local sql = string.format("SELECT * FROM t_black_while_list WHERE org_id_fk='%s';", _channel_id)
    return db_mysql:exec_once(sql)
end

--[[

]]
function _M.insert(_ip, _ip_type, _type, _channel_id)
    -- 'INSERT INTO `t_black_while_list` (`ip_address`, `ip_type`, `black_white`, `org_id_fk`) VALUES (NULL, NULL, NULL, NULL, NULL);'
    local params = {
        ip_address = _ip,
        ip_type = _ip_type,
        black_white = _type,
        org_id_fk = _channel_id
    }
    local sql = sql_manager.fmt_insert("t_black_while_list", params)
    ngx.log(ngx.ERR, sql)
    return db_mysql:exec_once(sql)
end

function _M.delete(_ip, _channel_id, _type)
    local sql =
        string.format(
        "DELETE FROM t_black_while_list WHERE ip_address='%s' AND org_id_fk='%s' and black_white='%s';",
        _ip,
        _channel_id,
        _type
    )
    local result, err = db_mysql:exec_once(sql)
    if result and result.affected_rows==0 then
        return nil, "no record"
    end
    return result, err
end

return _M
