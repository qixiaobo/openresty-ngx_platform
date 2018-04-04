--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:prop_transaction.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  道具交易记录表
--  
--]]
 
local cjson = require "cjson"
local uuid_help = require "common.uuid_help" 
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
-- get_prop_transactions 查询数据结构
-- example  
    
    local res = _M.get_prop_transactions(_prop_transaction, _start_index, _offsets, )
 
-- @param  _prop_transaction 需要查询的数据结构,不需要的数据为nil即可,条件字段与该表相同
-- @param  _start_index 搜寻的数据的当前位置, 用于分页查询
-- @param  _offsets  

-- @return  true 或者 nil 代表错误
--]]
_M.get_prop_transactions = function ( _prop_transaction, _start_index, _offsets) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   	local str = mysql_help.select_help("select t_prop_transaction.* from t_prop_transaction ", _prop_transaction,"and",_start_index, _offsets ) 
  
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    
    return res,errcode; 
end




--[[
-- add_prop_transaction 添加新数据
--  
-- example 
    local _prop_transaction = {...}
    local res = _M.add_prop_transaction(_prop_transaction)

-- @param  _prop_transaction 新数据的表结构
-- @return  返回成功或者失败标志
--]]
_M.add_prop_transaction = function ( _prop_transaction ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.insert_help("t_prop_transaction", _prop_transaction)
 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end



--[[
-- update_prop_transaction 根据条件更新数据, _wparam 主要包括查询条件
--  
-- example 
     local _prop_transaction = {...}
    local res = _M.update_prop_transaction(_prop_transaction)

-- @param  _prop_transaction 需要更新的数据结构
-- @param  _wparam 条件数据
-- @return  返回成功或者失败标志
--]]
_M.update_prop_transaction = function ( _prop_transaction, _wparam ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.update_help("t_prop_transaction", _prop_transaction,{id_pk = _prop_transaction.id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end

--[[
-- delete_prop_transaction 表主键id或唯一code 基本不应该使用
--  
-- example 
    local _prop_transaction = {...}
    local res = _M.delete_prop_transaction(1)

-- @param  _id_pk 表的主键   
-- @return  返回成功或者失败标志
--]]
_M.delete_prop_transaction = function ( _id_pk ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.delete_help("t_prop_transaction", {id_pk = _id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end




return _M