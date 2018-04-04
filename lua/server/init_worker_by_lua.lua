
--  作者:Steven 
--  日期:2017-02-26
--  文件名:system_init.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  系统的初始化脚本,该脚本用作nginx的 init_by_lua_file 的引用,
--  主要包括系统扩展函数,系统配置和系统状态的相关的初始化.
--  
--]]

local cjson = require "cjson"
local ngx_thread_help = require "common.ngx_thread_help"
local redis_help = require "common.db.redis_help"
-- local kaijiang_task = require "task.kaijiang_task" 
-- local once_task = require "task.once_task"
-- local sys_manager = require("server/sys_manager")

local ngx_worker_id = ngx.worker.id()

ngx.log(ngx.ERR, "=== nginx init woeker: id=" .. ngx_worker_id)


-- 系统启动定时器任务, 清零 服务器任务
-- 默认定时任务由 00 号服务器 00 workder执行
-- 系统自动遍历加载任务脚本,进行函数调用,各个程序可以参考系统task系统中实现的进行模版化实现
-- 该功能包括系统启动 
if ngx_worker_id == 0 and SERVER_ID == 0 then
    ngx.log(ngx.ERR, "server 0 ,workder 0 task start ")

    -- once_task.game_room_clear_task()
--    once_task.platform_players_clear_task()
--    once_task.http_task_test_task()

    -- -- 清理redis数据
    -- -- local cmd = "redis-cli del TEST_1; redis-cli del TEST_2;"
    -- local cmd = "redis-cli del CUSTOMER_SERVICE_CENTER;"
    -- local f = io.popen(cmd)
    -- local content = f:read("*a")
    -- f:close()

   -- sys_manager.init()
end

-- local ok, err = ngx.timer.at(3, time_cb)
-- if not ok then
--    ngx.log(ngx.ERR, "failed to create timer: ", err)
--    return
-- end 

-- local function rootinit()
--    -- 系统初始化
--    if not co then
--        co = ngx.thread.spawn(worker_init) 
--    end
--    if not co then  
--         local ok, err = ngx.timer.at(3, rootinit)
--         if not ok then
--             ngx.log(ngx.ERR, "failed to init_rooms: ", err)
--             return
--         end
--     end 
-- end
 
 
-- local ok, err = ngx.timer.at(3, rootinit)
-- if not ok then
--     ngx.log(ngx.ERR, "failed to init_rooms: ", err) 
-- end
 
-- while not co do
--   co = ngx.thread.spawn(worker_init) 
--   ngx.sleep(0.5) 
-- end

 



-- 系统 各个模块 nginx-work 初始化
--[[
local lfs = require "lfs"
local fileSys = require "common.lua_file_help"

local _M = {};
local sys_str = "/lua"
-- 获得当前目录功能,
local project_dir = fileSys.getCurPath()

_M.system_init = function (_init_file,_method)
    -- body
    -- 遍历文件,类似java中的遍历过滤能力
    local system_str = project_dir..sys_str;
    local tJson = {}; 
    local index = 1;
    for file in lfs.dir(system_str) do 
        local p = system_str..'/'..file  
        if file ~= "." and file ~= '..' then
          if fileSys.isDir(p) then
            -- 遍历文件夹 进行文件初始化
            local _moduleName = p..'/'.._init_file;
            
            if not fileSys.isDir(_moduleName..".lua") then
                -- 尝试引入模块，不存在则报错
                local _moduleFile = "system_init."..file..'.'.._init_file;
                local ret, ctrl, err = pcall(require, _moduleFile) 
                
                if ret then
                     
                    -- 尝试获取模块方法，不存在则报错
                    local req_method = ctrl[_method] 
                    if req_method then
                        req_method()
                    end
                end
            end

          end
            
        end 
    end
end
_M.system_init("worker_init","init")
--]]