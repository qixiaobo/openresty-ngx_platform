--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_account_dao.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  游戏账户,不同游戏应对不同的账户,游戏账户主要包含游戏币,免费送不可置换的游戏币,积分,游戏积分,游戏人望
--	
--]]

local cjson = require "cjson"
local uuid_help = require "common.uuid_help" 
local pre_config = require "conf.pre_config"
local time_help = require "common.time_help"  
local incr_help = require "common.incr_help"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"


-- 表基础结构
local _M = {
	id_pk = 0,             -- 用户积分
	user_code = "",        -- 用户编号
    balance = 0,           -- 账户余额
    integral = 0,              -- 账户积分
    reputation = 0,         -- 账户信用等级或者积分
    pay_password = "",      -- 支付密码
} 


--[[
-- get_user_accounts 获得用户记录信息, 该信息减少
-- example   
    local res = _M.get_user_accounts(_user_account, _start_index, _offsets, )
 
-- @param  _user_account 游戏分类 表结构
-- @param  _start_index 搜寻的数据的当前位置, 用于分页查询
-- @param  _offsets  

-- @return  true 或者 nil 代表错误
--]]

_M.get_user_accounts = function ( _user_account, _start_index, _offsets) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   	local str = mysql_help.select_help("select t_user_account.* from t_user_account ", _user_account,"and",_start_index, _offsets ) 
  
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    
    return res,errcode; 
end

--[[
-- get_user_user_account 获得用户记录信息, 该信息减少
-- example  
    
    local res = _M.get_user_accounts(_user_code, )
 
-- @param  _user_code 游戏分类 表结构
-- @param  _start_index 搜寻的数据的当前位置, 用于分页查询
-- @param  _offsets  

-- @return  true 或者 nil 代表错误
--]]
_M.get_user_user_account = function ( _user_code ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   	local str = string.format("select t_user_account.* from t_user_account where t_user_account.user_code_fk = '%s';",_user_code)  
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    
    return res,errcode; 
end


--[[
-- add_user_account 开启账户,系统默认为用户开启账户
--  
-- example 
    local _user_account = {...}
    local res = _M.add_user_account(_user_account)

-- @param  _user_account 游戏分类 表结构
-- @return  返回操作成功或失败,以及失败的错误编码
--]]
_M.add_user_account = function ( _user_account ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 

    local str = mysql_help.insert_help("t_user_account", _user_account)
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end




--[[
--  update_user_account 
--  更新用户游戏账号,下面主要体现的为流水记录上的区别
--  1 当用户之间的交易, 内部交易, 修改用户两个账号的相关数据,
--  2 向系统购买, 发起方为用户, 目标为系统商家id, 产生扣费行为; 
    3 用户发起方为充值, 表示由系统充值记录发起的行为,目标账号为用户
        该编号作为发起方的id, 发起类型为第三方支付, WECHAT, ZHIFUBAO, BANK,
        第三方账号时, code为第三方系统给的账号信息, 银联支付则包含银行的基础信息

    4 系统提现, 接收方为用户的第三方账户, 发起方为用户账号  
    完成之后 修改完成 生成 流水,系统流水
    系统开奖或其他获取的方式,发起方为系统,发起类型为system
-- example 
    local _wparam = {
        
    }
    local res = _M.update_user_account(_wparam)
 
-- @param  _wparam 条件数据
-- @return  返回成功或者失败标志
--]]
_M.update_user_account = function ( _wparam ) 
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

    local strimpl=""
    
    local transaction_code = incr_help.get_time_union_id() 
    local transaction = {
        transaction_code = transaction_code,
        transaction_from = _wparam.transaction_from,
        transaction_from_type = _wparam.transaction_from_type,
        transaction_to = _wparam.transaction_to,
        transaction_to_type = _wparam.transaction_to_type,  
    } 
    
    _wparam.transaction_from = nil
    _wparam.transaction_from_type = nil
    _wparam.transaction_to = nil
    _wparam.transaction_to_type = nil

    for k,v in pairs(_wparam) do 
        if tonumber(v) > 0 then
            strimpl = strimpl .. k .."="..k.."+"..v..","
        else
            strimpl = strimpl .. k .."="..k..v..","
        end
        transaction[k] = v
    end

    strimpl = string.sub(strimpl,1,#strimpl-1) 
    local sql2= string.format("update t_user_account set %s where user_code_fk = '%s';",strimpl,_user_code)

    local res, err, errcode, sqlstate = mysql_cli:query(sql2) 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err 
    end  
 
    -- 添加流水记录
    -- local transaction_code = uuid_help:get64(); 

    local sql3 = mysql_help.insert_help("t_trade_tf",transaction)  
    local res, err, errcode, sqlstate = mysql_cli:query(sql3) 
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
    return res,errcode; 
end



--[[
-- user_account_recharge 充值操作,用户充值操作需要执行本功能函数,充值包括用户,充值来源等基础信息
--  如果充值成功,而数据库操作失败,则需要将数据异步存储到消息队列和日志队列中,进行双保险操作,同时未来根据消息查询解决失败的情况
-- example 
    
    local res = _M.update_user_account( _user_code, _from_code ,_from_code_type,_money,_integral)

-- @param  _user_code   充值的账号
-- @param  _from_code   充值编号    由于充值主要现在采用第三方和银联卡,顾该字段采用相对于的交易编号即可
-- @param  _from_code_type 充值类型
-- @param  _money 充值金钱
-- @param  _integral 系统赠送的积分
-- @return  返回成功或者失败标志
--]]
_M.user_account_recharge = function ( _user_code, _from_code ,_from_code_type,_money,_integral)  
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

    local strimpl=""
    
    local transaction_code = incr_help.get_time_union_id() 
    local transaction = {
        transaction_code = transaction_code,
        transaction_from = _from_code,
        transaction_from_type = _from_code_type,
        transaction_to = _user_code,
        transaction_to_type = "user_account",  
    }  

    local _wparam = {
        balance = _money,
        integral = _integral
    }

    for k,v in pairs(_wparam) do 
        if tonumber(v) > 0 then
            strimpl = strimpl .. k .."="..k.."+"..v..","
        else
            strimpl = strimpl .. k .."="..k..v..","
        end
        transaction[k] = v
    end

    strimpl = string.sub(strimpl,1,#strimpl-1) 
    local sql2= string.format("update t_user_account set %s where user_code_fk = '%s';",strimpl,_user_code)

    local res, err, errcode, sqlstate = mysql_cli:query(sql2) 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err 
    end  
 
    -- 添加流水记录
    -- local transaction_code = uuid_help:get64(); 

    local sql3 = mysql_help.insert_help("t_trade_tf",transaction)  
    local res, err, errcode, sqlstate = mysql_cli:query(sql3) 
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
    return res,errcode; 
end

--[[
-- user_account_transfer 转账操作的函数,主要用于用户之间转账
--  转账操作目标位同类用户
-- example  
    local res = _M.user_account_transfer( _to_code, _from_code ,_money)

-- @param  _from_code   系统目标账户 
-- @param  _to_code     目标用户账号
-- @param  _money 充值金钱 
-- @return  返回成功或者失败标志
--]]
_M.user_account_transfer = function ( _from_code, _to_code, _money)  
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
  
 
    local sql2 = string.format("update t_user_account set balance=balance - %d where user_code_fk = '%s';",_from_code,_money)

    local res, err, errcode, sqlstate = mysql_cli:query(sql2) 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err 
    end  

    local sql3= string.format("update t_user_account set balance=balance + %d where user_code_fk = '%s';",_to_code ,_money)

    local res, err, errcode, sqlstate = mysql_cli:query(sql3) 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err 
    end  

    local transaction_code = incr_help.get_time_union_id() 
    local transaction = {
        transaction_code = transaction_code,
        transaction_from = _from_code,
        transaction_from_type = "user_account",
        transaction_to = _to_code,
        transaction_to_type = "user_account", 
        balance = _money, 
    }  
    -- 添加流水记录
    -- local transaction_code = uuid_help:get64();  
    local sql4 = mysql_help.insert_help("t_trade_tf",transaction)  
    local res, err, errcode, sqlstate = mysql_cli:query(sql4) 
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
    return res,errcode; 
end


--[[
-- user_account_shop 用户购买行为,主要用于购买行为,订单可以为购买,代付,AA,随机付等等
--  购买行为的支付流水主要体现在用户user_account_shop
-- example  
    local res = _M.user_account_shop( _to_code, _from_code ,_money)

-- @param  _from_code   系统目标账户 
-- @param  _to_code     订单编号
-- @param  _money 充值金钱 
-- @return  返回成功或者失败标志
--]]
_M.user_account_shop = function ( _from_code, _to_code, _money)  
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
  
 
    local sql2= string.format("update t_user_account set balance=balance - %d where user_code_fk = '%s';",_from_code,_money)

    local res, err, errcode, sqlstate = mysql_cli:query(sql2) 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err 
    end   

    local transaction_code = incr_help.get_time_union_id() 
    local transaction = {
        transaction_code = transaction_code,
        transaction_from = _from_code,
        transaction_from_type = "user_account",
        transaction_to = _to_code,
        transaction_to_type = "order_code", 
        balance = _money, 
    }  
    -- 添加流水记录
    -- local transaction_code = uuid_help:get64();  
    local sql4 = mysql_help.insert_help("t_trade_tf",transaction)  
    local res, err, errcode, sqlstate = mysql_cli:query(sql4) 
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
    return res,errcode; 
end


--[[
-- delete_user_account 添加游戏分类
--  
-- example 
    local _user_account = {...}
    local res = _M.delete_user_account(1)

-- @param  _id_pk 游戏分类的主键   
-- @return  返回成功或者失败标志
--]]
_M.delete_user_account = function ( _id_pk ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
   local str = mysql_help.delete_help("t_user_account", {id_pk = _id_pk}) 
 
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end


--[[
-- get_account_tf 获取账户流水
--  
-- example 
    local _user_account = {...}
    local res = _M.delete_user_account(1)

-- @param  _id_pk 游戏分类的主键   
-- @return  返回成功或者失败标志
--]]
_M.get_account_tf = function ( _user_code,_start_index,_offset,_begin_time,_end_time ) 
    -- body 
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
    local str = string.format([[
          
        ]])
    local res, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil,errcode;
    end 
    
    return res,errcode; 
end


return _M