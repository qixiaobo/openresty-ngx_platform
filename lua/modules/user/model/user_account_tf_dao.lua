--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_account_tf_dao.lua
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
-- get_trade_tfs 获取交易信息
-- example  
    
    local res = _M.get_trade_tfs(_user_account_tf, _start_index, _offsets,_start_time,_end_time) 
 
-- @param  _user_account_tf 主要用于条件搜索
-- @param  _start_index 搜寻的数据的当前位置, 用于分页查询
-- @param  _offsets  

-- @return  true 或者 nil 代表错误
--]]
_M.get_trade_tfs = function ( _user_account_tf, _start_index, _offsets,_start_time,_end_time) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   	local str,_size = mysql_help.select_help(" t_trade_tf ", _user_account_tf,"and" ) 
    
    local time_str =""
    if _start_index and _end_time then 
        if _size == 0 then
            time_str = string.format(" where t_trade_tf.transaction_time >= '%s' and t_trade_tf.transaction_time <= '%s'  ", 
                           _start_time, _end_time)  
        else
            time_str = string.format(" and t_trade_tf.transaction_time >= '%s' and t_trade_tf.transaction_time <= '%s'  ", 
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
-- add_user_account_tf 添加账户流水,账户流水,存入用户redis缓存中,用户交易流水  功能未实现,请勿调用!!!!
--  
-- example 
    local _user_account_tf = {...}
    local res = _M.add_user_account_tf(_user_account_tf)

-- @param  _user_account_tf 游戏分类 表结构
-- @return  返回成功或者失败标志
--]]
_M.add_user_account_tf = function ( _user_account_tf ) 
    -- body  
    -- 添加记录,同时进行修改用户账户的操作 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,"new mysql client error" 
    end  
    
    local res, err, errcode, sqlstate = mysql_cli:query("START TRANSACTION;") 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err
    end   
     
    return res,errcode,_machine_bet_record.bet_flow_code;  

end
   



--[[
-- recharge_user_account_tf 充值
--  
-- example 
    local _user_account_tf = {...}
    local res = _M.recharge_user_account_tf(_user_account_tf)

-- @param  _user_account_tf 用户账户流水结构
-- @return  返回成功或者失败标志
--]]
_M.recharge_user_account_tf = function ( _user_account_tf ) 
        -- 添加记录,同时进行修改用户账户的操作 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,"new mysql client error" 
    end  
    
    local res, err, errcode, sqlstate = mysql_cli:query("START TRANSACTION;") 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err
    end  
      
    local sql1 = string.format("update t_user_account set balance = balance + %0.2f  where user_code_fk = '%s';",_user_account_tf.trade_to_amount, _user_account_tf.trade_to_id)
    
    local res, err, errcode, sqlstate = mysql_cli:query(sql1) 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err 
    end   
     ngx.log(ngx.ERR,"------- 1111",sql1);
      ngx.log(ngx.ERR,"------- 2222",cjson.encode(res));
    ----- !!!!!!!!!!!!!!!! -----
    if tonumber(res["affected_rows"]) == 0 then
        mysql_cli:query("ROLLBACK;") 
         ngx.log(ngx.ERR,"bad result: account balance is less ",sql1);
        return nil
    end 
    local sql2 = mysql_help.insert_help("t_trade_tf",_user_account_tf)  
    local res, err, errcode, sqlstate = mysql_cli:query(sql2) 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err 
    end    

    local res, err, errcode, sqlstate = mysql_cli:query("commit;") 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
       return res,err 
    end   
    return res
end

--[[
-- 查询最近流水 充值流水
--  
-- example 
     

-- @param  _user_code 
-- @param _start_index
-- @param _offsets
-- @return  返回成功或者失败标志
--]]
_M.get_recently_user_account_tf = function ( _user_code , _start_index, _offsets) 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,"new mysql client error" 
    end  
    
    local sql1 = string.format([[
            select t_trade_tf.trade_no, t_trade_tf.order_type, t_trade_tf.trade_to_amount, t_trade_tf.order_no, t_trade_tf.trade_time,t_trade_tf.trade_status from t_trade_tf
            where  (t_trade_tf.trade_to_id = '%s' and t_trade_tf.trade_to_type='ZSACCOUNT') ;
        ]],_user_code, _user_code)
    
    local res, err, errcode, sqlstate = mysql_cli:query(sql1) 
    if not res then 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".",sql1);
        return res,err 
    end   
    return res 
end

--[[
-- get_user_integral_tf 查询最近流水 支付流水
--  
-- example 
     
-- @param  _user_code 游戏分类 表结构
-- @return  返回成功或者失败标志
--]]
_M.get_user_integral_tf = function ( _user_code , _start_index, _offsets) 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,"new mysql client error" 
    end  
    
    local sql1 = string.format([[
            select t_trade_tf.trade_no, t_trade_tf.order_type, t_trade_tf.trade_from_amount, t_trade_tf.order_no,t_trade_tf.trade_time,t_trade_tf.trade_status from t_trade_tf
            where t_trade_tf.trade_from_id = '%s' and t_trade_tf.trade_from_type='ZSACCOUNT';
        ]],_user_code )
    
    local res, err, errcode, sqlstate = mysql_cli:query(sql1) 
    if not res then 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".",sql1);
        return res,err 
    end   
    return res 
end   


_M.get_user_points_tf = function (user_code , index, size) 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,"new mysql client error" 
    end  
    
    local sql = "select trade_no, order_type, trade_to_amount, order_no, trade_time, trade_status from t_trade_tf"
    sql = sql .. string.format(" where (trade_from_id = '%s' AND trade_from_amount_type='INTEGRAL') or (trade_to_id = '%s' AND trade_to_amount_type='INTEGRAL')", user_code, user_code)
    if index then
        sql = sql .. " LIMIT " .. index .. ", " .. size
    end
    sql = sql .. ";"
    local res, err, errcode, sqlstate = mysql_cli:query(sql) 
    if not res then 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".",sql1);
        return res,err 
    end   
    return res 
end


_M.get_user_balance_tf = function (user_code , index, size) 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,"new mysql client error" 
    end  
    
    local sql = "select trade_no, order_type, trade_to_amount, order_no, trade_time, trade_status from t_trade_tf"
    sql = sql .. string.format(" where (trade_from_id = '%s' AND trade_from_amount_type='ZSB') or (trade_to_id = '%s' AND trade_to_amount_type='ZSB')", user_code, user_code)
    if index then
        sql = sql .. " LIMIT " .. index .. ", " .. size
    end
    sql = sql .. ";"
    local res, err, errcode, sqlstate = mysql_cli:query(sql) 
    if not res then 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".",sql1);
        return res,err 
    end   
    return res 
end


return _M