
local cjson = require "cjson"
local uuid_help = require "common.uuid_help"
local mysql_db = require "common.db.db_mysql"
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local pre_config = require "conf.pre_config"
local time_help = require "common.time_help"
local incr_help = require "common.incr_help"


local _M = {}


--[[
    @说明：数据库查询BANNER信息
    @参数：无
]]
 _M.get_banner = function ()
    local sql = "SELECT * from t_banner_manager T WHERE T.status=1;"
    return mysql_db:exec_once(sql)
end

--[[
    @说明：数据库查询积分排行榜
    @参数：无
]]
_M.get_points_toplist = function ()
    local sql = "SELECT A.user_code ,A.user_name, B.integral "
    sql = sql .. "FROM t_user A, t_game_account B "
    sql = sql .. "WHERE A.user_code = B.user_code_fk ORDER BY B.integral DESC LIMIT 0, 100;"
    return mysql_db:exec_once(sql)
end



local machine_info = {
    machine_name = "福星高照",
    room_code = "coin_machine_2000",
    room_name = "苍老一号",
    logo = "/images/a3.jpg",
    field_code = "1"
}

--[[
    @brief：数据库查询机器信息
    @param：[machine_code] 机器编码code
]]
_M.get_machine_info = function (machine_code)
    local sql = "SELECT machine_code, machine_name, machine_room_code, machine_room_name, room_logo, machine_field_code_fk "
    sql = sql .. "FROM t_machine, t_machine_room "
    sql = sql .. "WHERE "
    sql = sql .. "machine_code = '" .. machine_code .. "' "
    sql = sql .. "and t_machine_room.machine_room_code = t_machine.machine_room_code_fk;"
    return mysql_db.exec_once(sql)
end

--[[
    @brief：数据库查询游戏房间分类级别信息：field：初级场、中级场、高级场
    @param：[game_code] 游戏类型code
]]
_M.get_game_field = function (game_code)
    local sql = "SELECT * from t_game_filed WHERE game_code_fk='"..game_code.."';"
    return mysql_db.exec_once(sql)
end

return _M