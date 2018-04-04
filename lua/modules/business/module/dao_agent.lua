local db_mysql = require "common.db.db_mysql"
local sql_manager = require "common.db.sql_manager"

local _M = {}

function _M.insert(_name, _agentid, _url, _logo, _effects, _desc, _hot, _state, _index)
    local param = {
        platform_name = _name,
        platform_code = _agentid,
        platform_url = _url,
        platform_logo = _logo,
        platform_effects = _effects,
        platform_description = _desc,
        platform_hot = _hot,
        platform_state = _state,
        platform_index = _index 
    }
    local sql = sql_manager.fmt_insert("t_three_game_platform", param)
    return db_mysql:exec_once(sql)
end


--[[
    查询
]]
function _M.query(agentid)
    local sql = string.format("SELECT * FROM t_three_game_platform WHERE platform_code='%s';", agentid)
    return db_mysql:exec_once(sql)
end

return _M
