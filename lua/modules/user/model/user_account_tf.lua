--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:game_account_tf.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  游戏账户交易流水相关功能类
--	
--]]



local uuid_help = require "common.uuid_help" 
local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local pre_config = require "conf.pre_config"
local time_help = require "common.time_help"  
local incr_help = require "common.incr_help"

-- 表基础结构
local _M = {
	id_pk = 0,
	transaction_code = "",		-- 交易编号
    user_code = "",             -- 交易人员
    transaction_from = "",      -- 交易来源
    transaction_from_type = "", -- 交易来源的类型
    transaction_to = "",        -- 交易目标
    transaction_to_type = "",   -- 交易目标的类型 
    transaction_last_code = "", -- 交易相关联类型
    transaction_time = "",      -- 交易时间
    balance_type = "",          -- 交易类型 
    balance = 0,
    nomove_balance = 0,
    integral = 0,
    popularity = 0,
    prop_id_fk = 0,             -- 道具外键id
    game_type_fk = 0,           -- 游戏外键id
	
} 


--[[
-- get_user_account_tfs 获取交易信息
-- example  
    
    local res = _M.get_user_account_tfs(_user_account_tf, _start_index, _offsets,_start_time,_end_time) 
 
-- @param  _user_account_tf 主要用于条件搜索
-- @param  _start_index 搜寻的数据的当前位置, 用于分页查询
-- @param  _offsets  

-- @return  true 或者 nil 代表错误
--]]
_M.get_user_account_tfs = function ( _user_account_tf, _start_index, _offsets,_start_time,_end_time) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   	local str,_size = mysql_help.select_help(" t_user_account_tf ", _user_account_tf,"and" ) 
    
    local time_str =""
    if _start_index and _end_time then 
        if _size == 0 then
            time_str = string.format(" where t_user_account_tf.transaction_time >= '%s' and t_user_account_tf.transaction_time <= '%s'  ", 
                           _start_time, _end_time)  
        else
            time_str = string.format(" and t_user_account_tf.transaction_time >= '%s' and t_user_account_tf.transaction_time <= '%s'  ", 
                           _start_time, _end_time)  
        end     
    end 
    str = str .. time_str .. string.format(" limit %d , %d",_start_index,_offsets)

	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    
    return res,errcode; 
end
  
--[[
-- add_user_account_tf 添加账户流水,账户流水,存入用户redis缓存中,用户交易流水
--  
-- example 
    local _user_account_tf = {...}
    local res = _M.add_user_account_tf(_user_account_tf)

-- @param  _user_account_tf 游戏分类 表结构
-- @return  返回成功或者失败标志
--]]
_M.add_user_account_tf = function ( _user_account_tf ) 
    -- body  
    local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 

    local _key = ZS_user_account_TF_PRE.._user_account_tf.user_code
    -- 记录写入redis缓冲,
    local res, err = redis_cli:lpush(_key,cjson.encode(_user_account_tf));
       
    if not res then
        ngx.log(ngx.ERR,cjson.encode(res),'   ',err)
        return nil
    end
    return res
end
   
--[[
-- 添加账户流水,账户流水,存入用户redis缓存中,用户交易流水
--  
-- example 
    local _user_account_tf = {...}
    local res = _M.add_user_account_tf(_user_account_tf)

-- @param  _user_account_tf 游戏分类 表结构
-- @return  返回成功或者失败标志
--]]
_M.get_recently_user_account_tf = function ( _user_code , _start_index, _offsets) 
    -- body  
    local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 

    local _key = ZS_user_account_TF_PRE.._user_code
    -- 记录写入redis缓冲,
    local res, err = redis_cli:lrange(_key,cjson.encode(_key, _start_index,_offsets);
       
    if not res then
        ngx.log(ngx.ERR,cjson.encode(res),'   ',err)
        return nil
    end
    return res
end

return _M