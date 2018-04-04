--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:district_machine.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  区服和投币机器查询接口,主要涉及区服查询,区服机器查询以及状态等查询
--]]

local cjson = require "cjson"  
local uuid_help = require "common.uuid_help" 
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help" 
local db_json_help = require "common.db.db_json_help"
local time_help = require "common.time_help"  
local incr_help = require "common.incr_help"


local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help"

local game_district = require "game.model.game_district"


local _API_FUNC = {
	
}

--[[
	推币机器的redis存储的主要关键键值结构如下
	1 区服列表 key 为 coin_machine_districts_map 其主要包括以区服编号为子键,内容为基础数据统计的json数据 机器数量,
					机器在游戏中的数量,故障数量,区服人数
	2 区服基础数据 key 为  coin_machine_district_status_map 以机器编号为唯一子键,内容为该机器当前玩家名字,排队人数等数据
 					
	3 机器详情 key 为 coin_machine_machine_status_map 子键包含 on_gameing_user_info 包含该用户的基础信息,编号,昵称,头像等
									queue_list json数组对象,当前排队人数不得超过10名
									该类数据系统默认通过订阅从服务器状态中获取,服务器异常重启时,可从redis缓存中读取,超时5分钟自动删除
投币机的结构在线机器的结构如下
投币机将以用户区服+机器区域作为主键  机器房间作为map 键盘, 内容为机器编码,该数据为基础存在数据
机器上线时和机器心跳时将数据存入以 开始字段 + 机器编号 的map 中 
该map主要包括机器编号, 机器状态, 机器玩家, 机器排队信息等



]]
--[[
-- get_districts 获取系统推币机器的区服列表
--  
-- example 
    curl 127.0.0.1/game/machine/district_machine/get_districts.action 
-- @return 返回列表区服服务器数据和当前区服的人数数量,空闲机器
--]]
_API_FUNC.get_districts = function()
	-- body
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return api_data_help.new(ZS_ERROR_CODE.REDIS_NEW_ERR,'服务器异常,请稍后再试')
    end  
   
	local res, err = redis_cli:hgetall("coin_machine_districts_map")
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.REDIS_OPT_ERR,'服务器异常,请稍后再试')  
    end 

    local resM = db_json_help.redis_hmap_json(res) 
  	return api_data_help.new_success(resM) 

end

--[[
-- get_machines 获取指定区服下机器的状态信息,该信息由服务器各个机器存储redis缓存服务器中
--  
-- example 
    curl 127.0.0.1/game/machine/district_machine/get_district_filed_machines.action?district_code=xxxx&filed_code=xxxx
-- @return 返回列表区服服务器数据和当前区服的人数数量,空闲机器
--]]
_API_FUNC.get_district_filed_machines = function()
	-- body
	local args = ngx.req.get_uri_args()

	local district_code = args["district_code"]
    local filed_code = args["filed_code"] 

    local machine_status_key = ZS_MACHINE_FILED_PRE
    if district_code then
        machine_status_key = machine_status_key..district_code
    end

    if filed_code then
        machine_status_key = machine_status_key..filed_code
    end

	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return api_data_help.new(ZS_ERROR_CODE.REDIS_NEW_ERR,'服务器异常,请稍后再试')
    end  
   
	local res, err = redis_cli:hgetall(machine_status_key)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.REDIS_OPT_ERR,'数据异常,请检查数据条件')  
    end 

    local resM = db_json_help.redis_hmap_json(res) 
  	return api_data_help.new_success(resM) 

end
  



return _API_FUNC