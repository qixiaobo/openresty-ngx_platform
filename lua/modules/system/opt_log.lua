--[[
    写入操作日志到数据库
]]
local mysql_db = require "common.db.db_mysql"

local _M = {}

--[[
    写操作日志
    @param: [_type] 日志类型
    @param: [_operater] 操作者
    @param: [_content] 详细内容
]]
function _M.write(_type, _operater, _content)
    local sql =
        string.format(
        "INSERT INTO t_opt_log (log_type, opt_id_fk, opt_time, opt_content) VALUES ('%s', '%s', '%s', '%s');",
        _type,
        _operater,
        os.date("%Y-%m-%d %H:%M:%S", os.time()),
        _content
    )

    local res, err = mysql_db:exec_once(sql)
    if not res then
        return nil, err
    end
    return res
end

return _M
