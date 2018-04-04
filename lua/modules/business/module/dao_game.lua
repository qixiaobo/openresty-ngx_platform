local db_mysql = require "common.db.db_mysql"
local sql_manager = require "common.db.sql_manager"

local _M = {}

function _M.insert(_platform_no, _name, _gameno, _ab, _logo, _index, _state)
    -- INSERT INTO 't_game' ('id_pk', 'game_name', 'game_no', 'game_ab', 'game_state', 'game_logo', 'game_css', 'game_cate_no_fk', 'game_platform_no_fk', 'game_index') VALUES (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    local params = {
        game_name = _name,
        game_no = _gameno,
        game_ab = _ab,
        game_logo = _logo,
        game_index = _index,
        game_platform_no_fk = _platform_no
    }
    local sql = sql_manager.fmt_insert("t_game", params)
    return db_mysql:exec_once(sql)
end

function _M.query(_agentid)
    local sql = string.format("SELECT * FROM t_game WHERE game_platform_no_fk='%s';", _agentid)
    return db_mysql:exec_once(sql)
end

return _M
