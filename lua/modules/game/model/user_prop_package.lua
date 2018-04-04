--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_prop_package.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  用户背包,存储用户的背包数据,不同游戏结构不同
--  
--]]




local uuid_help = require "common.uuid_help" 
local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local pre_config = require "conf.pre_config"



local _M = {
	id_pk = 0,
	transaction_code = "",	-- 交易编号
	prop_id_fk = "",		-- 交易的物件
	prop_numbers = 100,	-- 交易数量
	prop_from = 0,	-- 交易来源方
	prop_to = "",	-- 交易接收方
	-- transaction_time ="", -- 交易时间
} 
 

--[[
-- get_user_props 获取用户背包道具信息
-- example  
    
    local res = _M.get_user_props(_user_prop, _start_index, _offsets, )
 
-- @param  _user_prop 需要查询的数据结构,不需要的数据为nil即可,条件字段与该表相同
-- @param  _start_index 搜寻的数据的当前位置, 用于分页查询
-- @param  _offsets  

-- @return  true 或者 nil 代表错误
--]]
_M.get_user_props = function ( _user_code,_pack_type) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 

   	local str = string.format("select t_user_prop_package.* from t_user_prop_package where user_code = %s ",_user_code)
   	if _pack_type then 
    	str = str.."and package_type = ".._pack_type.." ;"
    end
    
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    
    return res,errcode; 
end
 

--[[
-- add_user_prop 添加新数据
--  
-- example 
    local _user_prop = {...}
    local res = _M.add_user_prop(_user_prop)

-- @param  _user_prop 新数据的表结构
-- @return  返回成功或者失败标志
--]]
_M.add_user_prop = function ( _user_prop ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.insert_help("t_user_prop_package", _user_prop)
 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end



--[[
-- update_user_prop 根据条件更新数据, _wparam 主要包括查询条件
--  
-- example 
     local _user_prop = {...}
    local res = _M.update_user_prop(_user_prop)

-- @param  _user_prop 需要更新的数据结构
-- @param  _wparam 条件数据
-- @return  返回成功或者失败标志
--]]
_M.update_user_prop = function ( _user_prop, _wparam ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.update_help("t_user_prop_package", _user_prop,{id_pk = _user_prop.id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end

--[[
-- delete_user_prop 表主键id或唯一code 基本不应该使用
--  
-- example 
    local _user_prop = {...}
    local res = _M.delete_user_prop(1)

-- @param  _id_pk 表的主键   
-- @return  返回成功或者失败标志
--]]
_M.delete_user_prop = function ( _id_pk ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.delete_help("t_user_prop_package", {id_pk = _id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end




return _M