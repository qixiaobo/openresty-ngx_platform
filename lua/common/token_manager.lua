
local uuid_help = require("common.uuid_help")

local redis_manager = require("common.db.redis_manager")

local _M = {}

--[[
    创建新的TOKEN
    @param: [data: 需要保存的有效数据，格式自定义]
    @param: [expire_time: 有效期,单位秒]
]]
function _M.create(data, expire_time)
    local token = uuid_help.get()

    local key = "TOKEN:" .. token
    local res, err = redis_manager.exec(nil, "set", key, data or "{data is not set}")
    if not res then
        return nil, err
    end

    if expire_time then
        local res, err = redis_manager.exec(nil, "expire", key, expire_time)
        if not res then
            return nil, err
        end
    end
    return token
end

--[[
    检查TOKEN的有效性
    @param: [token]
]]
function _M.check(token)
    -- local header = ngx.req.get_headers()
    -- local token = header["Token"]
    local key = "TOKEN:" .. token
    local res, err = redis_manager.exec(nil, "get", key)
    if not res then
        return nil, err
    end
    return res
end

return _M
