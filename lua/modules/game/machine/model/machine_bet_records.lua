--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:machine_bet_records.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  机器押注过程个类数据记录表
--  
--]]


local uuid_help = require "common.uuid_help" 
local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local pre_config = require "conf.pre_config"
local incr_help = require "common.incr_help"
local redis_queue_help = require "common.db.redis_queue_help"

local _M = {
	id_pk = 0,
	bet_flow_code = "",
	machine_code_fk = "",
	user_code_fk = "",
	bet_money = 100,
	bet_rewards = 0,
	bet_area = "",
	bet_time="",
} 

local MACHINE_BET_RECORDS_NO_COMPELETE_LIST_KEY = "machine_bet_records_no_complete_list"
local MACHINE_BET_RECORDS_CENCEL_LIST_KEY = "machine_bet_records_cancel_list"
local MACHINE_BET_REWARDS_ADD_ERROR_LIST_KEY = "machine_bet_rewards_add_error_list"


_M.MACHINE_BET_RECORDS_NO_COMPELETE_LIST_KEY = MACHINE_BET_RECORDS_NO_COMPELETE_LIST_KEY
_M.MACHINE_BET_RECORDS_CENCEL_LIST_KEY = MACHINE_BET_RECORDS_CENCEL_LIST_KEY
_M.MACHINE_BET_REWARDS_ADD_ERROR_LIST_KEY = MACHINE_BET_REWARDS_ADD_ERROR_LIST_KEY

--[[
-- get_machine_bet_records 查询数据结构
-- example  
    
    local res = _M.get_machine_bet_records(_machine_bet_record, _start_index, _offsets, )
 
-- @param  _machine_bet_record 需要查询的数据结构,不需要的数据为nil即可,条件字段与该表相同
-- @param  _start_index 搜寻的数据的当前位置, 用于分页查询
-- @param  _offsets  

-- @return  true 或者 nil 代表错误
--]]
_M.get_machine_bet_records = function ( _machine_bet_record, _start_index, _offsets) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   	local str = mysql_help.select_help("select t_trade_tf.* from t_trade_tf ", _machine_bet_record,"and",_start_index, _offsets ) 
  
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
	    return nil,errcode;
	end 
    
    return res,errcode; 
end




--[[
-- add_machine_bet_record  押注成功,进行事务处理,完成扣费与记录添加操作
--  
-- example 
    local _machine_bet_record = {
		machine_code_fk='',user_code_fk='',
		bet_money=1,
		bet_rewards, -- or
    }
    local res = _M.add_machine_bet_record(_machine_bet_record)

-- @param  _machine_bet_record 新数据的表结构
-- @return  返回成功或者失败标志
--]]
_M.add_machine_bet_record = function ( _machine_bet_record ) 
     -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,"new mysql client error" 
    end 
-- 修改当前账户余额,返回结果,调用的程序根据反馈情况,操作后续记录
-- start transaction;
-- //1  检查用户的积分是否高于要减的分数
-- select score from score_manage where id = 用户id;
-- //2  从积分管理表用户积分减去要减的积分
-- update score_manage set  score = score - 积分 where id =1;
-- commit; 
----- 建议未来采用存储过程调用,实现该业务过程
   
    local res, err, errcode, sqlstate = mysql_cli:query("START TRANSACTION;") 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err
    end  
    
    local sql2 = ''
 	if _machine_bet_record.bet_money then
     	sql2 = string.format("update t_game_account set balance = balance - %d  where user_code_fk = '%s' and balance - %d >= 0;",_machine_bet_record.bet_money, _machine_bet_record.user_code,_machine_bet_record.bet_money)
	else
	 	sql2 = string.format("update t_game_account set integral = integral + %d  where user_code_fk = '%s';",_machine_bet_record.bet_rewards,_machine_bet_record.user_code)
	end

    local res, err, errcode, sqlstate = mysql_cli:query(sql2) 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err 
    end   

    if tonumber(res["affected_rows"]) == 0 then
    	mysql_cli:query("ROLLBACK;") 
    	 ngx.log(ngx.ERR,"bad result: account balance is less",errcode,"  ",cjson.encode(res)," ",sql2);
    	return nil
    end
    
     -- 支付的流水
    local _user_account_tf = { }
    if _machine_bet_record.bet_money then
            _user_account_tf = {
                trade_no = incr_help.get_time_union_id(),  
                order_no = incr_help.get_uuid(),
                trade_from_type = "ZSACCOUNT",
                trade_from_id = _machine_bet_record.user_code,
                trade_from_amount = _machine_bet_record.bet_money,
                trade_from_amount_type = "ZSB",

                trade_to_type   =   "ZSACCOUNT",
                trade_to_id     =   _machine_bet_record.machine_code,
                trade_to_amount =   _machine_bet_record.bet_money, 
                trade_to_amount_type = "ZSB",
                trade_status = "TRADE_UNDEFINED", 
                order_type = "coin_machine_slot",
            }
 
    else
            _user_account_tf = {
                trade_no = incr_help.get_time_union_id(), 
                order_no = incr_help.get_uuid(), 
                trade_from_type = "ZSACCOUNT",
                trade_from_id = _machine_bet_record.machine_code,
                trade_from_amount = _machine_bet_record.bet_rewards,
                trade_from_amount_type = "INTEGRAL",

                trade_to_type   =   "ZSACCOUNT",
                trade_to_id     =   _machine_bet_record.user_code ,
                trade_to_amount =   _machine_bet_record.bet_rewards, 
                trade_to_amount_type = "INTEGRAL",
                trade_status = "TRADE_SUCCESS", 
                order_type = "投币赢取",
            }


    end
       
 
    local sql4 = mysql_help.insert_help("t_trade_tf",_user_account_tf)   
    local res, err, errcode, sqlstate = mysql_cli:query(sql4) 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ", err,": ",errcode, ": ", sqlstate,"."); 
        return res,err 
    end  
      
    local res, err, errcode, sqlstate = mysql_cli:query("commit;") 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
       return res,err 
    end   
 
    local change_val
    if _machine_bet_record.bet_money then
        change_val = _machine_bet_record.bet_money
    else
        change_val = _machine_bet_record.bet_rewards
    end
  
    return res,errcode,_user_account_tf.trade_no; 
end



--[[
-- add_machine_seat_record  留座扣费记录
--  
-- example 
    local _machine_bet_record = {
        machine_code_fk='',user_code_fk='',
        bet_money=1,
        bet_rewards, -- or
    }
    local res = _M.add_machine_bet_record(_machine_bet_record)

-- @param  _machine_bet_record 新数据的表结构
-- @return  返回成功或者失败标志
--]]
_M.add_machine_seat_record = function ( _machine_bet_record ) 
     -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,"new mysql client error" 
    end 
-- 修改当前账户余额,返回结果,调用的程序根据反馈情况,操作后续记录
-- start transaction;
-- //1  检查用户的积分是否高于要减的分数
-- select score from score_manage where id = 用户id;
-- //2  从积分管理表用户积分减去要减的积分
-- update score_manage set  score = score - 积分 where id =1;
-- commit; 
----- 建议未来采用存储过程调用,实现该业务过程
   
    local res, err, errcode, sqlstate = mysql_cli:query("START TRANSACTION;") 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err
    end  
    
    local sql2 = string.format("update t_game_account set balance = balance - %d  where user_code_fk = '%s' and balance - %d >= 0;",_machine_bet_record.bet_money, _machine_bet_record.user_code,_machine_bet_record.bet_money)
     
    local res, err, errcode, sqlstate = mysql_cli:query(sql2) 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err 
    end   

    if tonumber(res["affected_rows"]) == 0 then
        mysql_cli:query("ROLLBACK;") 
         ngx.log(ngx.ERR,"bad result: account balance is less",errcode,"  ",cjson.encode(res)," ",sql2);
        return nil
    end
    
     -- 支付的流水
    local _user_account_tf = {
        trade_no = incr_help.get_time_union_id(),  
        order_no = incr_help.get_uuid(),
        trade_from_type = "ZSACCOUNT",
        trade_from_id = _machine_bet_record.user_code,
        trade_from_amount = "-".._machine_bet_record.bet_money,
        trade_from_amount_type = "ZSB",

        trade_to_type   =   "ZSACCOUNT",
        trade_to_id     =   _machine_bet_record.machine_code,
        trade_to_amount =   "-".._machine_bet_record.bet_money, 
        trade_to_amount_type = "ZSB",
        trade_status = "TRADE_SUCCESS", 
        order_type = "留座",
    }

   
 
    local sql4 = mysql_help.insert_help("t_trade_tf",_user_account_tf)   
    local res, err, errcode, sqlstate = mysql_cli:query(sql4) 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ", err,": ",errcode, ": ", sqlstate,"."); 
        return res,err 
    end  
      
    local res, err, errcode, sqlstate = mysql_cli:query("commit;") 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
       return res,err 
    end   
 
    local change_val
    if _machine_bet_record.bet_money then
        change_val = _machine_bet_record.bet_money
    else
        change_val = _machine_bet_record.bet_rewards
    end
  
    return res,errcode,_user_account_tf.trade_no; 
end


--[[
-- complete_machine_bet_record 完成当前的操作记录,主要用于用户投币完成之后,等到机器投币完成之后的最终确认
--  
-- example 
    local _machine_bet_record = {...}
    local res = _M.delete_machine_bet_record(1)

-- @param  _id_pk 表的主键    
-- @return  返回成功或者失败标志
--]]
_M.complete_machine_bet_record = function ( _bet_flow_code ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = string.format("update t_trade_tf set trade_status='TRADE_SUCCESS' where trade_no='%s';", _bet_flow_code)
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"update t_trade_tf set bet_status: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        
	    -- 写入缓存数据库
	    redis_queue_help.push_redis_queue(MACHINE_BET_RECORDS_NO_COMPELETE_LIST_KEY,str)
	    -- 写入缓存数据库 
        return nil,errcode;
    end 
    
    return res,errcode; 
end

--[[
-- cancel_machine_bet_record  操作失败取消投注
--  
-- example 
    local _machine_bet_record = {...}
    local res = _M.delete_machine_bet_record(1)

-- @param  _user_code 用户唯一编号
-- @param _bet_flow_code  
-- @return  返回成功或者失败标志
--]]
_M.cancel_machine_bet_record = function (_user_code, _bet_flow_code ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end  

    local res, err, errcode, sqlstate = mysql_cli:query("START TRANSACTION;") 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err
    end   
 
    local sql2 = string.format("update t_game_account set balance = balance + 1  where user_code_fk = '%s';",_user_code)
	  
    local res, err, errcode, sqlstate = mysql_cli:query(sql2) 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err 
    end  

    local sql3 = string.format("update t_trade_tf settrade_status='TRADE_CLOSED'  where trade_no=%d",_bet_flow_code)
    local res, err, errcode, sqlstate = mysql_cli:query(sql3) 
        if not res then
            mysql_cli:query("ROLLBACK;") 
            ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
            return res,err 
        end  
    local new_insert_id = res.insert_id

    local res, err, errcode, sqlstate = mysql_cli:query("commit;") 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
       return res,err 
    end  

    
    return res,errcode; 
end

 



return _M