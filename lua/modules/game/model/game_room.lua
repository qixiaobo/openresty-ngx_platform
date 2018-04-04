--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:chat_room.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  游戏房间,对于房间分为固定房间,用户/主播房间,直播类游戏机为房间
--  
--]]


--[[
	房间主要包括以下信息
]]


local clazz = require "common.clazz.clazz"
local _M = {} 
 


--[[
-- get_game_rooms 获得用户记录信息, 该信息减少
-- example  
    
    local res = _M.get_game_rooms(_game_room, _start_index, _offsets, )
 
-- @param  _game_room 游戏分类 表结构
-- @param  _start_index 搜寻的数据的当前位置, 用于分页查询
-- @param  _offsets  

-- @return  true 或者 nil 代表错误
--]]
_M.get_game_rooms = function ( _game_room, _start_index, _offsets) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   	local str = mysql_help.select_help("select t_game_room.* from t_game_room ", _game_room,"and",_start_index, _offsets ) 
  
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    
    return res,errcode; 
end




--[[
-- add_game_rooms 添加游戏分类
--  
-- example 
    local _game_room = {...}
    local res = _M.add_game_room(_game_room)

-- @param  _game_room 游戏分类 表结构
-- @return  返回成功或者失败标志
--]]
_M.add_game_rooms = function ( _game_room ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.insert_help("t_game_room", _game_room)
 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end



--[[
-- update_game_room 添加游戏分类
--  
-- example 
     local _game_room = {...}
    local res = _M.update_game_room(_game_room)

-- @param  _game_room 游戏分类 表结构
-- @param  _wparam 条件数据
-- @return  返回成功或者失败标志
--]]
_M.update_game_room = function ( _game_room, _wparam ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.update_help("t_game_room", _game_room,{id_pk = _game_room.id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end

--[[
-- delete_game_room 添加游戏分类
--  
-- example 
    local _game_room = {...}
    local res = _M.delete_game_room(1)

-- @param  _id_pk 游戏分类的主键   
-- @return  返回成功或者失败标志
--]]
_M.delete_game_room = function ( _id_pk ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.delete_help("t_game_room", {id_pk = _id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end


return _M