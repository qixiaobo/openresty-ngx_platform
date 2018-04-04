--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:game_machine_dao.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  直播机器游戏对象,包含机器的各类状态信息,系统进行创建新游戏实例,通过子线程进行业务请求
--]]


local clazz = require "common.clazz.clazz"
local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local uuid_help = require "common.uuid_help" 
local incr_help = require "common.incr_help"
local _M = {} 
_M.__index = _M
 

-- 机器基础信息包括如下
--[[
	渠道商id 
	区服/网点 机器编号 机器名称 机器状态 机器所属的游戏类型
	机器二维码等信息

	创建新的机器,需要将以下参数 初始化到机器对象中!!!!!!!
]]
_M.channel_id_fk = 0

_M.machine_code = ""

_M.machine_name = ""

_M.machine_status = 0

_M.game_id_fk = 0

_M.districs_id_fk = 0	

_M.user_code = ""

setmetatable(_M,clazz)  -- _M 继承于 clazz
 

local MACHINE_STATUS = {
	ERROR = -1,		-- 机器故障

	NO_PLAY = 0,	-- 没人试玩
	ON_PLAYING = 1,	-- 正在被玩家占用

}
 
--[[
-- get_coin_machines 查询机器服务器,返回系统机器,机器的状态存储到redis系统中,使用hmap的方式进行存储和状态管理
-- example  
    
    local res = _M.get_coin_machines(_coin_machine, _start_index, _offsets, )
 
-- @param  _coin_machine 需要查询的数据结构,不需要的数据为nil即可,条件字段与该表相同
-- @param  _start_index 搜寻的数据的当前位置, 用于分页查询
-- @param  _offsets  

-- @return  true 或者 nil 代表错误
--]]
_M.get_coin_machines = function ( _coin_machine, _start_index, _offsets) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   	local str = mysql_help.select_help("select t_coin_machine.* from t_coin_machine ", _coin_machine,"and",_start_index, _offsets ) 
  
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    
    return res,errcode; 
end
 
--[[
-- add_coin_machine  押注成功,进行事务处理,完成扣费与记录添加操作
--  
-- example 
    local _coin_machine = {...}
    local res = _M.add_coin_machine(_coin_machine)

-- @param  _coin_machine 新数据的表结构
-- @return  返回成功或者失败标志
--]]
_M.add_coin_machine = function ( _coin_machine ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 

    
   local str = mysql_help.insert_help("t_coin_machine", _coin_machine)
 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end



--[[
-- delete_coin_machine 表主键id或唯一code 基本不应该使用
--  
-- example 
    local _coin_machine = {...}
    local res = _M.delete_coin_machine(1)

-- @param  _id_pk 表的主键   
-- @return  返回成功或者失败标志
--]]
_M.delete_coin_machine = function ( _id_pk ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.delete_help("t_coin_machine", {id_pk = _id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end

 

--[[
-- get_coin_machine_rooms 查询机器房间列表,用来清理房间人数纪录
-- example  
    
    local res = _M.get_coin_machine_rooms()
 
-- @param  wu  

-- @return  true 或者 nil 代表错误
--]]
_M.get_coin_machine_rooms = function ( ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
    local str = "select t_machine_room.* from t_machine_room;"
  
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end


return _M