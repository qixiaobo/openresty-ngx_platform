--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:game_bchannel.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--	渠道商模型类,对于渠道商的相关数据的各类数据库信息查询  

--]]
 

local uuid_help = require "common.uuid_help" 
local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local redis_help = require "common.db.redis_help"
local mysql_help = require "common.db.mysql_help" 
local pre_config = require "conf.pre_config"



local _M = {
	id_pk = 0,
	channel_title = "",
	channel_logo  = "",
	parent_channel_id = 0,
	channel_code = "",
	game_id_fk = 1,
	channel_description = "", 
	user_code="",
} 




--[[
-- ge_game_bchannels 查询数据结构
-- example  
    
    local res = _M.get_game_bchannels(_game_bchannel, _start_index, _offsets, )
 
-- @param  _game_bchannel 需要查询的数据结构,不需要的数据为nil即可,条件字段与该表相同
-- @param  _start_index 搜寻的数据的当前位置, 用于分页查询
-- @param  _offsets  

-- @return  true 或者 nil 代表错误
--]]
_M.get_game_bchannels = function ( _game_bchannel, _start_index, _offsets) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   	local str = mysql_help.select_help("select t_game_bchannel.* from t_game_bchannel ", _game_bchannel,"and",_start_index, _offsets ) 
  
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    
    return res,errcode; 
end




--[[
-- add_game_bchannel 添加新数据
--  
-- example 
    local _game_bchannel = {...}
    local res = _M.add_game_bchannel(_game_bchannel)

-- @param  _game_bchannel 新数据的表结构
-- @return  返回成功或者失败标志
--]]
_M.add_game_bchannel = function ( _game_bchannel ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.insert_help("t_game_bchannel", _game_bchannel)
 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end



--[[
-- update_game_bchannel 根据条件更新数据, _wparam 主要包括查询条件
--  
-- example 
     local _game_bchannel = {...}
    local res = _M.update_game_bchannel(_game_bchannel)

-- @param  _game_bchannel 需要更新的数据结构
-- @param  _wparam 条件数据
-- @return  返回成功或者失败标志
--]]
_M.update_game_bchannel = function ( _game_bchannel, _wparam ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.update_help("t_game_bchannel", _game_bchannel,{id_pk = _game_bchannel.id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end

--[[
-- delete_game_bchannel 表主键id或唯一code
--  
-- example 
    local _game_bchannel = {...}
    local res = _M.delete_game_bchannel(1)

-- @param  _id_pk 表的主键   
-- @return  返回成功或者失败标志
--]]
_M.delete_game_bchannel = function ( _id_pk ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.delete_help("t_game_bchannel", {id_pk = _id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end

return _M