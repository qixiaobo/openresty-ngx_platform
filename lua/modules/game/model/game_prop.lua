--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:game_prop.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  游戏道具类,主要关于游戏的道具的增删改查,类型获取等
--]]

local _M = {} 

local uuid_help = require "common.uuid_help"
local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local pre_config = require "conf.pre_config"


-- 表基础结构
local _M = {
    id_pk = 0,
    transaction_code = "",      -- 交易编号
    user_code = "",             -- 交易人员
    transaction_from = "",      -- 交易来源
    transaction_from_type = "", -- 交易来源的类型
    transaction_to = "",        -- 交易目标
    transaction_to_type = "",   -- 交易目标的类型 
    transaction_last_code = "", -- 交易相关联类型
    transaction_time = "",      -- 交易时间
} 


--[[
-- get_game_props 获得用户记录信息, 该信息减少
-- example  
    
    local res = _M.game_category(_game_prop, _start_index, _offsets, )
 
-- @param  _game_prop 游戏分类 表结构
-- @param  _start_index 搜寻的数据的当前位置, 用于分页查询
-- @param  _offsets  

-- @return  true 或者 nil 代表错误
--]]
_M.get_game_props = function ( _game_prop, _start_index, _offsets) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   	local str = mysql_help.select_help("select t_game_prop.* from t_game_prop ", _game_prop,"and",_start_index, _offsets ) 
  
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    
    return res,errcode; 
end




--[[
-- add_game_props 添加游戏分类
--  
-- example 
    local _game_prop = {...}
    local res = _M.add_game_prop(_game_prop)

-- @param  _game_prop 游戏分类 表结构
-- @return  返回成功或者失败标志
--]]
_M.add_game_props = function ( _game_prop ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.insert_help("t_game_prop", _game_prop)
 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end



--[[
-- update_game_prop 添加游戏分类
--  
-- example 
     local _game_prop = {...}
    local res = _M.update_game_prop(_game_prop)

-- @param  _game_prop 游戏分类 表结构
-- @param  _wparam 条件数据
-- @return  返回成功或者失败标志
--]]
_M.update_game_prop = function ( _game_prop, _wparam ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.update_help("t_game_prop", _game_prop,{id_pk = _game_prop.id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end

--[[
-- delete_game_prop 添加游戏分类
--  
-- example 
    local _game_prop = {...}
    local res = _M.delete_game_prop(1)

-- @param  _id_pk 游戏分类的主键   
-- @return  返回成功或者失败标志
--]]
_M.delete_game_prop = function ( _id_pk ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.delete_help("t_game_prop", {id_pk = _id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end



return _M