local redis_help = require "common.db.redis_help"

local _M = {}

function _M.clear_redis()
    local redis_cli = redis_help:new()
    if not redis_cli then return false end

    local res, err = redis_cli:del("CUSTOMER_SERVICE_CENTER")
    if not res then return false end

    return true
end


--[[
    在init_worker不能直接使用API操作REDIS, 使用pcall进行调用
    由于在nginx初始化完成之前 REDIS操作会无效, 所以对执行结果进行判断如果执行失败则用
]]
function _M.exec(flag, handler)
    if handler then
        local res, res_func = pcall(handler)
        if not res or not res_func then
            local res = ngx.timer.at(1, _M.exec, handler)
            if not res then
                handler()
            end
        end
    else 
        ngx.log(ngx.ERR, "=== exec failed.")
    end

    -- -- 清理redis数据
    -- -- local cmd = "redis-cli del TEST_1; redis-cli del TEST_2;"
    -- local cmd = "redis-cli del CUSTOMER_SERVICE_CENTER;"
    -- local f = io.popen(cmd)
    -- local content = f:read("*a")
    -- f:close()
end



function _M.init() 
    -- 清理 REDIS 垃圾数据
    _M.exec(nil, _M.clear_redis)

    -- 开启定时任务
    -- local game_task = require("task.game_task")
    -- _M.exec(nil, game_task.init)
end

return _M