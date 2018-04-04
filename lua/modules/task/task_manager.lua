
local _M = {
    TYPE= {
        TASK_INSTANTLY = "TASK_INSTANTLY",  -- 即时任务， 立即执行执行
        TASK_TIMED = "TASK_TIMED",          -- 定时任务
    },

    is_timer_on = false,
    task_map = {},
    timer_t = 1     -- 定时器间隔时间，单位：秒
}

-- local task = {
--     name = "",    
--     params = {},
--     handler = nil,
--     type = _M.TYPE.TASK_AT_ONCE,
--     exec_time = "2018-01-01 00:00:00",
--     status = 0
-- }


--[[
    @brief: 启动任务管理定时器
]]
function _M.start_timer() 
    if not _M.is_timer_on then
        _M.task_map = {}
        _M.is_timer_on = true
        ngx.timer.at(_M.timer_t, _M.on_timer)
    end
end

--[[
    @brief: 任务定时器处理函数，对任务列表中的任务进行处理
]]
function _M.on_timer(premature)
    if premature then
        return
    end
    if not _M.is_timer_on then
        return
    end
  
    for name, task in pairs(_M.task_map) do
        if task.type == _M.TYPE.TASK_INSTANTLY then
            _M.exec_task(name)
        elseif task.type == _M.TYPE.TASK_TIMED then
            -- "2014-01-01 00:00:00"
            local Y = string.sub(task.exec_time , 1, 4)  
            local M = string.sub(task.exec_time , 6, 7)  
            local D = string.sub(task.exec_time , 9, 10)  
            local H = string.sub(task.exec_time , 12, 13)  
            local MM = string.sub(task.exec_time , 15, 16)  
            local S = string.sub(task.exec_time , 18, 19)  
            local exec_time = os.time({year=Y, month=M, day=D, hour=H,min=MM,sec=S}) 
            local cur_time = os.time()
            
            if cur_time >= exec_time then
                if task.status == 0 then
                    _M.exec_task(name)
                elseif task.status == 2 then
                    _M.task_map[name] = nil
                end
            end 
        end
    end

    ngx.timer.at(_M.timer_t, _M.on_timer)
end


--[[
    @brief: 停止任务管理定时器
]]
function _M.stop_timer() 
    _M.is_timer_on = false
end

--[[
    @brief: 新建任务
    @param: [type]      TYPE.TASK_INSTANTLY: 立即执行    
                        TYPE.TASK_TIMED:定时执行, 
            [name]      任务名称
            [params]    任务参数，根据不同任务可以有不同参数
            [handler]   任务执行函数, handler(params)
            [exec_time] 格式: 2018-01-20 12:00:00, 对定时执行该参数是必须参数
]]
function _M.new_task(type, name, params, handler, exec_time) 
    ngx.log(ngx.ERR, "=====> [TASK] new task: " .. string.format("type='%s', name='%s', exec_time='%s'", type, name, exec_time))
    local task = {
        name = name,
        params = params,
        handler = handler,
        type = type,
        exec_time = exec_time,
        status = 0
    }
    _M.task_map[name] = task
    if task.type == _M.TYPE.TASK_INSTANTLY then
        _M.exec_task(name)
    end
end

--[[
    @brief: 执行任务
]]
function _M.exec_task(name)
    ngx.log(ngx.ERR, "=====> [TASK] execute task: " .. name)
    local task = _M.task_map[name]
    if not task then
        ngx.log(ngx.ERR, string.format("execute task [%s] failed: task is not exist.", name))
        return nil, string.format("execute task [%s] failed: task is not exist.", name)
    end
    if not task.handler then
        ngx.log(ngx.ERR, string.format("execute task [%s] failed: task has no handler", name))
        return nil, string.format("execute task [%s] failed: task has no handler", name)
    end
    
    task.status = 1
    ngx.thread.spawn(_M.on_task_thread, task)
    return true
end

function _M.on_task_thread(task)
    if task then
        local res, err = task.handler(task.params)
        if not res then
            ngx.log(ngx.ERR, string.format("execute task handler [%s] failed: " .. task.name))
        else
            task.status = 2
            _M.task_map[task.name] = nil
        end

        ngx.log(ngx.ERR, "=====> [TASK] task finished: " .. task.name .. ", status=".. task.status)
    end
end


--[[
    @brief: 创建任务示例
]]
local cjson = require("cjson")
function task_handler(params)
    ngx.log(ngx.ERR, "=====> [TASK HANDLER] " .. cjson.encode(params))    
    return 1
end

function _M.test()
    _M.new_task(_M.TYPE.TASK_INSTANTLY, "TASK1",  {id=100001}, task_handler)
end


_M.start_timer()

return _M