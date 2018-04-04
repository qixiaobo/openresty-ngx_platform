--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:once_task.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  单次任务队列,系统启动时,进行某些状态值的清空操作,或新任务状态控制操作
--]]


local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local uuid_help = require "common.uuid_help" 
local incr_help = require "common.incr_help"
local redis_queue_help = require "common.db.redis_queue_help"
 
local random_help = require "common.random_help"

local _M = {

}


-- 清空在线人数
local function platform_players_clear()

	-- 清空当前在线人数
	local redis_cli = redis_help:new()
	if not redis_cli then
		return nil
	end 
	-- 清除在线用户数量
	local machine_on_line_users = "coin_machine_on_line_users"
	redis_cli:del(SYSTEM_ON_LINE_USERS..machine_on_line_users)
    ngx.log(ngx.ERR,"platform_players_clear 执行结束")
    return true
end

-- 清空房间在线人数
-- 读取房间信息
local function game_room_clear()
   	local game_machine_dao = require "game.machine.model.game_machine_dao"
  	local res = game_machine_dao.get_coin_machine_rooms()


  		-- 清空当前在线人数
	local redis_cli = redis_help:new()
	if not redis_cli or not res  then
 		return nil
	end 
	for i=1,#res do
		redis_cli:del(SYSTEM_ON_LINE_USERS..res[i].machine_room_code) 
	end
	ngx.log(ngx.ERR,"game_room_clear 执行结束")
	return true
end

local function platform_players_clear_task() 
	-- body
	local ok,res = pcall(platform_players_clear) 
	if not ok or not res then
		local ok, err = ngx.timer.at(1, platform_players_clear_task)
        if not ok then
            ngx.log(ngx.ERR, "failed to init_rooms: ", err)
            platform_players_clear_task()
            return
        end
	end

end

local function game_room_clear_task ()
	local ok,res = pcall(game_room_clear) 
	if not ok or not res then
		local ok, err = ngx.timer.at(1, game_room_clear_task)
        if not ok then
            ngx.log(ngx.ERR, "failed to init_rooms: ", err)
            game_room_clear_task()
            return
        end
	end

end

local function http_task_test()

	local http = require "resty.http"
		local httpc = http.new()
		local res, err = httpc:request_uri("http://127.0.0.1/tests/cookie_test.do", {
				method = "GET",  
			})

		if not res then
			ngx.log(ngx.ERR,"failed to request: ", err)
		 	return nil
		end

		-- In this simple form, there is no manual connection step, so the body is read
		-- all in one go, including any trailers, and the connection closed or keptalive
		-- for you.
 		ngx.log(ngx.ERR,"get body: ", res.body)

	return true      

end
local function http_task_test_task ()
	local ok,res = pcall(http_task_test) 
	if not ok or not res then
		local ok, err = ngx.timer.at(1, http_task_test_task)
        if not ok then
            ngx.log(ngx.ERR, "failed to init_rooms: ", err)
            http_task_test_task()
            return
        end
	end

end

_M.platform_players_clear_task = platform_players_clear_task
_M.game_room_clear_task = game_room_clear_task
_M.http_task_test_task = http_task_test_task
return _M