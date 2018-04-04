local cjson = require "cjson" 
local api_data_help = require "common.api_data_help"
local random_help = require "common.random_help"
local redis_help = require "common.db.redis_help"
local mysql_help = require "common.db.mysql_help"
local mysql_db = require "common.db.db_mysql" 
local incr_help = require "common.incr_help"

local _M = {}


_M.reward = function(user_A, code, user_B) 
    -- local args = ngx.req.get_uri_args()
    -- local user_A = args['user_A']
    -- local code = args['code']
    -- local user_B = args['user_B']

    local value = 60
    local redis_cli = redis_help:new();
    if not redis_cli then
        return nil, "REDIS异常: redis new failed"
    end

    local res = redis_cli:hget("INVITE_USER_CODE", user_A)
    if not res then
        return nil, "user [".. user_A .. "] has no invite code" 
    end
    if res ~= tostring(code) then
        return nil, "user [".. user_A .. "]’s invite code is not [" .. code .. "]"
    end
    
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil, "数据库连接异常";
    end

    local res, err, errcode, sqlstate = mysql_cli:query("START TRANSACTION;") 
    if not res then
        ngx.log(ngx.ERR,"bad result: ", err,": ",errcode, ": ", sqlstate,".");
        return res, err
    end  

    local sql = string.format("update t_game_account set balance = balance + %d  where user_code_fk = '%s' or user_code_fk='%s';", value, user_A, user_B) 
    local res, err, errcode, sqlstate = mysql_cli:query(sql) 
    if not res then 
        return nil, string.format("更新账户余额失败, DB error: %s, code='%s'",err,errcode)
    end

    local params = {
        trade_no = incr_help.get_time_union_id(),
        order_no = "",
        order_type = "邀请好友注册奖励", --_order_code,
        trade_from_type = "ZSACCOUNT",
        trade_from_id = "server_acount",
        trade_from_amount = value,
        trade_from_amount_type = "ZSB",
        trade_to_type = "ZSACCOUNT",
        trade_to_id = user_A,
        trade_to_amount = value,
        trade_to_amount_type = "ZSB",
        trade_time = os.date("%Y-%m-%d %H:%M:%S", os.time()),
        trade_status = "TRADE_SUCCESS"
    }
    local sql = mysql_help.insert_help("t_trade_tf", params) 
    local res, err, errcode, sqlstate = mysql_cli:query(sql) 
    if not res or tonumber(res["affected_rows"]) == 0  then
        mysql_cli:query("ROLLBACK;") 
        return nil, string.format("写入交易流水失败, DB error: %s, code='%s'",err,errcode)
    end

    local params = {
        trade_no = incr_help.get_time_union_id(),
        order_no = "",
        order_type = "邀请码注册奖励", --_order_code,
        trade_from_type = "ZSACCOUNT",
        trade_from_id = user_B,
        trade_from_amount = value,
        trade_from_amount_type = "ZSB",
        trade_to_type = "ZSACCOUNT",
        trade_to_id = "server_acount",
        trade_to_amount = value,
        trade_to_amount_type = "ZSB",
        trade_time = os.date("%Y-%m-%d %H:%M:%S", os.time()),
        trade_status = "TRADE_SUCCESS"
    }
    local sql = mysql_help.insert_help("t_trade_tf", params) 
    local res, err, errcode, sqlstate = mysql_cli:query(sql) 
    if not res or tonumber(res["affected_rows"]) == 0  then
        mysql_cli:query("ROLLBACK;") 
        return nil, string.format("写入交易流水失败, DB error: %s, code='%s'",err,errcode)
    end

    local res, err, errcode, sqlstate = mysql_cli:query("commit;") 
    if not res then
        mysql_cli:query("ROLLBACK;") 
           ngx.log(ngx.ERR,"bad result: ", err,": ",errcode, ": ", sqlstate,".");
       return nil, err 
    end  


    local cur_date= os.date("%Y-%m-%d %H:%M:%S", os.time())
    local mail = {
        user_code_fk = user_A,
        mail_time = cur_date,
        content = string.format("邀请好友成功注册奖励, 获得积分%s.", cur_date, value),
        is_readed = 0
    }


    local msg = { process_type=0x1e, sub_type=0x08, data=mail }
    msg.data.balance_changed = value
    local res = redis_cli:publish(ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR..user_A, cjson.encode(msg))

    mail.user_code_fk = user_B
    mail.content = string.format("通过邀请码成功注册奖励, 获得积分%s.", cur_date, value)
    msg.data=mail
    msg.data.balance_changed = value
    local res = redis_cli:publish(ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR..user_B, cjson.encode(msg))

    return true
end

return _M