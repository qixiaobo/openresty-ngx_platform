--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:game_innings.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  游戏对局信息,各类卡牌游戏过程的记录以局进行记录系统游戏信息
--]]

local _M = {} 


local uuid_help = require "common.uuid_help":new(ZS_USER_NAME_SPACE)
local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local pre_config = require "conf.pre_config"


-- 表基础结构
local _M = {
	id_pk = 0,  
	game_id_fk = 0,			 
	game_innings_code = 0,		 
	begin_time = "",
	end_time = "",	 
	game_details = "",

} 




--[[
-- get_game_innings 获得用户记录信息, 该信息减少
-- example  
    
    local res = _M.get_game_innings(_game_inning, _start_index, _offsets, )
 
-- @param  _game_inning 游戏分类 表结构
-- @param  _start_index 搜寻的数据的当前位置, 用于分页查询
-- @param  _offsets  

-- @return  true 或者 nil 代表错误
--]]
_M.get_game_innings = function ( _game_inning, _start_index, _offsets) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   	local str = mysql_help.select_help("select t_game_inning.* from t_game_inning ", _game_inning,"and",_start_index, _offsets ) 
  
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    
    return res,errcode; 
end




--[[
-- add_game_innings 添加游戏分类
--  
-- example 
    local _game_inning = {...}
    local res = _M.add_game_inning(_game_inning)

-- @param  _game_inning 游戏分类 表结构
-- @return  返回成功或者失败标志
--]]
_M.add_game_innings = function ( _game_inning ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.insert_help("t_game_inning", _game_inning)
 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end



--[[
-- update_game_inning 添加游戏分类
--  
-- example 
     local _game_inning = {...}
    local res = _M.update_game_inning(_game_inning)

-- @param  _game_inning 游戏分类 表结构
-- @param  _wparam 条件数据
-- @return  返回成功或者失败标志
--]]
_M.update_game_inning = function ( _game_inning, _wparam ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.update_help("t_game_inning", _game_inning,{id_pk = _game_inning.id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end

--[[
-- delete_game_inning 添加游戏分类
--  
-- example 
    local _game_inning = {...}
    local res = _M.delete_game_inning(1)

-- @param  _id_pk 游戏分类的主键   
-- @return  返回成功或者失败标志
--]]
_M.delete_game_inning = function ( _id_pk ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.delete_help("t_game_inning", {id_pk = _id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end






return _M