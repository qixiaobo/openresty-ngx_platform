local db_mysql = require "common.db.db_mysql"
local sql_manager = require "common.db.sql_manager"

local _M = {}

function _M.insert(_channel_id, _pri_key, _pub_key, _algorithm, _password)
    --
    local params = {
        bizorg_id_fk = _channel_id,
        rsa_pri_key = _pri_key,
        rsa_pub_key = _pub_key,
        rsa_algorithm = _algorithm,
        rsa_time = os.date("%Y-%m-%d %H:%M:%S", os.time()),
        private_key = _password
    }
    local sql = sql_manager.fmt_insert("t_rsa_record", params)
    local result, err = db_mysql:exec_once(sql)
    return result, err
end

return _M
