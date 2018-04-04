
local redis_help = require "common.db.redis_help"

local _M = {}

-- local config = {
--     host = "127.0.0.1",
--     port = 6379,
--     user = "root",
--     -- passwd = "Zhengsu@2014",
--     max_packet_size = 1024 * 1024 
-- }

-- function _M.conn()
--     local red, err = redis:new()
--     if not red then
--         ngx.log(ngx.ERR, "===>>  REDIS new failed" .. err)
--         return nil, "REDIS new failed:" .. err
--     end

--     red:set_timeout(1000)

--     local res, err = red:connect(config.host, config.port)
--     if not res then
--         ngx.log(ngx.ERR, "===>>  REDIS connect failed")
--         return nil, "REDIS connect failed:" .. err
--     end

--     red.close = close
--     return red
-- end

-- function close (self)
--     local sock = self.sock
--     if not sock then
--         return nil, "not initialized"
--     end
--     if self.subscribed then
--         return nil, "subscribed state"
--     end
--     return sock:setkeepalive(10000, 50)
-- end

function _M.create()
    local err = nil
    local redis = redis_help:new();
    if not redis then
        err = "create redis object failed"
    end
    return redis, err
end


function _M.exec(red, cmd, ... )
    local red, err = red or _M.create()
    if not red then return nil, err end
    local redis_cmd = red[cmd]
    if not redis_cmd then
        return nil, "redis command [" .. cmd .. "] is not exist." 
    end
    return redis_cmd(red, ... )
end

return _M