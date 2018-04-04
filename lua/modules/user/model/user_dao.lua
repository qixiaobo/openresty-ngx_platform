--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_dao.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  用户user相关的数据库访问数据库访问功能,
--]]
 

local cjson = require "cjson"
local mysql = require "resty.mysql"
local pre_config = require "conf.pre_config"
local incr_help = require "common.incr_help"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local uuid_help = require "common.uuid_help":new(ZS_USER_NAME_SPACE)

local user = require "user.model.user"
local user_ex_dao = require "user.model.user_ex_dao"
local user_account_dao = require "user.model.user_account_dao"
local user_recommend_dao = require "user.model.user_recommend_dao"

local _M = {}


local ZS_PRE_USER_KEEPALIVETOKEN = "USER_AUTH_LOGIN_"
-- 用户唯一编号,系统采用11位起步的数字编号,编号从8位开始计数

local ZS_PRE_USER_CODE_INC = "USER_CODE_INC"

local ZS_PRE_USER_CODE_START = 10000000
-- 用户名字redis缓存maps key 
local ZS_PRE_USER_NAMES_MPAS = "USER_NAMES_MPAS"
-- 用户手机号码缓存存储的集合 key
local ZS_PRE_USER_MOBILES_MPAS = "USER_MOBILES_MPAS"
-- 用户邮箱存储的集合 key
local ZS_PRE_USER_EMAIL_MPAS = "USER_EMAIL_MPAS"

-- 用户物流地址存储的集合 key
local ZS_PRE_LOGISTICS_MPAS = "LOGISTICS_MPAS"


--[[
    @brief: 
            用户注销
    @param: 
            [_user_id] 用户唯一ID
    @return  
            true 成功 false 失败  
--]]
_M.unregister = function(_user_id)
    local sql = string.format("DELETE FROM t_user WHERE user_id='%s'", _user_id)
    return mysql_db:exec_once(sql)
end

--[[
    @brief: 用户注册
    @param: _param 用户注册信息  
        {
            user_name = "xxxxx",
            password = "iom08a9sdaskdj", 
            email = "abc@123.com",
            phone_number = "1386152xxxx",
            area_code = "0086",
            user_state = "nomal",
            nick_name = ''
        }
    @return  状态（true:成功 false/nil：失败） 错误码（200：成功 400：失败） 错误消息  
--]]
_M.register = function ( _param ) 
    --获取推荐人用户ID
    local recommend_user_id = _param.recommend_user_id
    _param.recommend_user_id = nil

    local nick_name = _param.nick_name
    _param.nick_name = nil

    local agent_no = _param.agent_no
    _param.agent_no = nil

    if recommend_user_id then
        local sql = string.format("select * from t_user where user_id = '%s'", recommend_user_id)
        local res, msg = mysql_db:exec_once(sql)
        if not res then
            return res, ZS_ERROR_CODE.MYSQL_ERR, msg
        end

        if not res[1] then
            return false, 400, "推荐人用户不存在."
        end
    end

    --开启事务
    --mysql_db:exec_query("SET AUTOCOMMIT=0") --设置为不自动提交，因为MYSQL默认立即执行
    local db = mysql_db:new_db()
    mysql_db:db_begin_transaction(db)
    
    local sql = mysql_help.insert_help("t_user", _param)
    local res, msg = mysql_db:exec_query(sql, db)
    if not res then
        mysql_db:db_rollback(db)
        mysql_db:db_set_keepalive(db)
        return res, ZS_ERROR_CODE.MYSQL_ERR, msg
    end

    if recommend_user_id then
        local user_recmommend_info = {}
        user_recmommend_info.recommend_id_fk = recommend_user_id
        user_recmommend_info.user_id_fk = _param.user_id
        local res, err = user_recommend_dao.add_user_recommend_info(user_recmommend_info, db)
        if not res then
            mysql_db:db_rollback(db)
            mysql_db:db_set_keepalive(db)
            return res, 400, err
        end
    end

    local account_info = {}
    account_info.user_id_fk = _param.user_id
    account_info.balance = 0.0
    account_info.consume_balance = 0.0
    account_info.integral = 0
    account_info.popularity = 0.0
    account_info.pay_password = nil
    account_info.account_state = nil
    account_info.account_type = ZS_ACCOUNT_TYPE.DEFAULT
    account_info.currency_type = ''
    local res, err = user_account_dao.add_user_account(account_info, db)
    if not res then
        ngx.log(ngx.ERR, "err: ", err)
        mysql_db:db_rollback(db)
        mysql_db:db_set_keepalive(db)
        return res, 400, err
    end

    local user_ext_info = {}
    user_ext_info.user_id_fk = _param.user_id
    user_ext_info.nick_name = nick_name and nick_name or _param.user_id
    user_ext_info.head_portrait = 'images/user_head/user_head.png'
    user_ext_info.user_level_fk = 0
    user_ext_info.reg_code = ZS_LANGUAGE_CODE.DEFAULT
    local res, err = user_ex_dao.add_user_ex(user_ext_info, db)
    if not res then
        ngx.log(ngx.ERR, "err: ", err)
        mysql_db:db_rollback(db)
        mysql_db:db_set_keepalive(db)
        return res, 400, err
    end

    --如果需要, 存储渠道与用户关系表
    if agent_no then
        local res = ngx.location.capture(
                        "/business/api/channel/bind_user_channel.action", 
                        {
                            args = {
                                        channel_id = agent_no,
                                        user_id = _param.user_id
                                    }
                        }
                    )
        if not res then
            --处理用户表
            return false, 400, "系统错误, bind_user_channel 失败."
        end
        ngx.log(ngx.ERR, "status:", res.status, " response:", res.body)
        local data = cjson.decode(res.body)
        if not data then
            mysql_db:db_rollback(db)
            mysql_db:db_set_keepalive(db)
            return false, 400, "系统错误. cjson.decode 失败."
        end

        if data.code ~= '200' then
            mysql_db:db_rollback(db)
            mysql_db:db_set_keepalive(db)
            return false, 400, "系统错误, err: "..res.body
        end
    end

    --结束事务
    mysql_db:db_commit(db)
    mysql_db:db_set_keepalive(db)

    return true, 200, "注册成功."
end

--[[
    @brief: 
            获取所有用户信息
    @param: 
    @return: 
            true: 获取信息成功  false: 获取信息失败    
]]
_M.get_all_user_info = function ()
    local sql = "SELECT * FROM t_user LEFT JOIN t_user_ext_info ON t_user_ext_info.user_id_fk=t_user.user_id LEFT JOIN t_account ON t_account.user_id_fk=t_user.user_id;"
    local res, msg = mysql_db:exec_once(sql)
    if not res then
        return false, "数据库操作异常."
    end

    if not res[1] then
        return false, "没用用户信息."
    end
    return true, "获取用户信息成功.", res
end

--[[
    @brief: 
            获取用户信息，用户名、手机、邮箱 任意一个匹配则返回该信息
    @参数: 
            [_name] 用户名
            [_email] 用户邮箱
            [_phone] 用户手机号码
    @返回: 
            返回用户个人信息
--]]
_M.get_user = function (_name, _email, _phone, _user_id) 
    local sql = "SELECT * FROM t_user LEFT JOIN t_user_ext_info ON t_user_ext_info.user_id_fk=t_user.user_id LEFT JOIN t_account ON t_account.user_id_fk=t_user.user_id "
    sql = sql .. string.format("WHERE (t_user.user_name='%s' or t_user.email='%s' or t_user.phone_number='%s' or t_user.user_id='%s');", _name, _email, _phone, _user_id)
    return mysql_db:exec_once(sql)
end
 
--[[
    @brief: 
            获取用户所有信息
    @param: 
            [_user_id:string] 用户唯一ID
    @return: 
            nil 没有此ID的用户信息   用户信息     
]]
_M.get_user_info = function(_user_id)
    local sql = "SELECT * from t_user A, t_user_ext_info B, t_account C "
    sql = sql .. string.format("WHERE A.user_id='%s'  AND B.user_id_fk='%s' AND C.user_id_fk='%s';", _user_id, _user_id, _user_id)
    return mysql_db:exec_once(sql)
end

--[[
    @brief: 
            修改用户密码
    @param: 
            [_user_id:string] 用户唯一ID
            [_password:string] 原密码
            [_new_password:string] 新密码 
    @return:
            true 成功  nil  失败
--]]
_M.change_password = function (_user_id, _password, _new_password)
    local sql =  string.format("update t_user set password='%s' where t_user.user_id='%s'",_new_password, _user_id)
    if _password then
        sql = sql.."and t_user.password='".._password.."'"
    end
    sql = sql..";"
    ngx.log(ngx.ERR, "\n\n ======== ", sql)
    return mysql_db:exec_once(sql)
end

--[[
    @brief: 
            修改用户绑定的手机号
    @param: 
            [_user_id:string] 用户唯一ID
            [_phone_number:string] 手机号
    @return:
            true 成功  false 失败
--]]
_M.change_phone_number = function (_user_id, _phone_number)
    local sql =  string.format("update t_user set phone_number='%s' where t_user.user_id='%s';",_phone_number, _user_id)
    ngx.log(ngx.ERR, "\n[change_phone_number]: ", sql)
    
    local res, err = mysql_db:exec_once(sql)
    if not res then
        return false, err
    end

    if res.affected_rows > 0 then
        return true
    else
        return false, err
    end
end

--[[
    @brief: 
            修改用户绑定的邮箱账号
    @param: 
            [_user_id:string] 用户唯一ID
            [_email:string] 手机号
    @return:
            true 成功  false 失败
--]]
_M.change_email = function (_user_id, _email)
    local sql =  string.format("update t_user set email='%s' where t_user.user_id='%s';",_email, _user_id)
    ngx.log(ngx.ERR, "\n[change_email]: ", sql)
    
    local res, err = mysql_db:exec_once(sql)
    if not res then
        return false, err
    end

    if res.affected_rows > 0 then
        return true
    else
        return false, err
    end
end

--[[
    @brief: 
            修改用户名
    @param: 
            [_user_id:string] 用户唯一ID
            [_user_name:string] 用户名
    @return:
            true 成功  false 失败
--]]
_M.change_user_name = function (_user_id, _user_name)
    local sql =  string.format("update t_user set user_name='%s' where t_user.user_id='%s';",_user_name, _user_id)
    ngx.log(ngx.ERR, "\n[change_user_name]: ", sql)
    
    local res, err = mysql_db:exec_once(sql)
    if not res then
        return false, err
    end

    if res.affected_rows > 0 then
        return true
    else
        return false, err
    end
end

--[[
    @brief: 
            makePassword 创建user_uuid namespace 下的94进制密码,用于注册或者登录时的密码处理 
                减少 系统存储用户密码长度 该客户端 密码为处理 sha256
    @example： 
 	          local password = 'xxxxx' 
 	          local pwd_94 = _M.makePassword(password)
    @param:  
            [_password] 密码明文
    @return: 
            密码94进制字符串 不可用于url传输(可通过编码之后进行传输)
]]
_M.make_password = function ( _password )
	if not _password then return nil end
	local pwd = uuid_help:get94(_password)
    -- 94进制的数据中存在' " 两个字符串, 所以系统需要将字符串转译一次
    pwd = string.gsub(pwd,"'","\\'")
    pwd = string.gsub(pwd,"\\","//")
    return pwd
end

--[[
    @brief:
            make_user_id 创建用户唯一编号
            用户唯一数字编号,系统本次采用redis作为自增唯一id
    @example:
            local password = 'xxxxx' 
            local pwd_94 = _M.makePassword(password)
    @param:
    @return:
            返回用户唯一编号
]]
_M.make_user_id = function ( )
    -- body 
    local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end  

    -- 记录写入redis缓冲,
    local res, err = redis_cli:incr(ZS_PRE_USER_CODE_INC);
    
    if not res then  
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR,"redis_cli:incr(ZS_PRE_USER_CODE_INC)");
       return nil
    end

    return res + ZS_PRE_USER_CODE_START
end

--[[
    @brief: 
            保持用户登录状态, 保存token信息到redis, 有效时长30天
            (ZS_PRE_USER_KEEPALIVETOKEN)  -->  ($user_code)_token --> $token
    @param: 
            [user_id] 用户唯一ID
            [token] token值
    @return: 
            设置用户token有效登录状态,超时时间为30天
--]]
_M.keep_alived_login = function ( _user_id, _token )
    if not _user_id or not _token then 
        ngx.log(ngx.ERR,"user_id or token 未设置")
        return nil
    end

    --开启事务
    local db = mysql_db:new_db()
    mysql_db:db_begin_transaction(db)
    
    --添加登录记录
    local sql = string.format("INSERT INTO t_user_help (user_id_fk, login_time) VALUES('%s', '%s');", _user_id, ngx.localtime())
    local res, err = mysql_db:exec_query(sql, db)
    if not res then
        mysql_db:db_rollback(db)
        mysql_db:db_set_keepalive(db)
        return false, err
    end

    local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        mysql_db:db_rollback(db)
        mysql_db:db_set_keepalive(db)
        return nil
    end 
    
    local key = ZS_PRE_USER_KEEPALIVETOKEN.._user_id.."_token"
    local res, err = redis_cli:set(key, _token)
    if not res then
        ngx.log(ngx.ERR,cjson.encode(res),'   ',err)
        mysql_db:db_rollback(db)
        mysql_db:db_set_keepalive(db)
        return nil
    end

    local res, err = redis_cli:expire(key, pre_config.monthTimeSec)  
    if not res then
        redis_cli:del(key)
        mysql_db:db_rollback(db)
        mysql_db:db_set_keepalive(db)
        ngx.log(ngx.ERR,cjson.encode(res),'   ',err)
    end  

    --提交事务
    local res = mysql_db:db_commit(db)
    if not res then
        mysql_db:db_rollback(db)
        redis_cli:del(key)
    end

    mysql_db:db_set_keepalive(db)
    return res
end


--[[
    @brief: 
            查询用户是否保持登录状态
    @param: 
            [user_id] 用户唯一ID
            [token] token值
    @return: 
            true: 保持登录; false: 不保持登录
--]]
_M.is_keep_alived_login = function ( _user_id, _token )
    if true then
        return true
    end
    if not _user_id or not _token or _user_id == '' or _token == '' then 
        return false, "参数错误: [user_id] 或 [token] is nil."
    end

	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR, "REDIS异常: new failed.");
        return false, "REDIS异常: new failed."
    end 

    local key = ZS_PRE_USER_KEEPALIVETOKEN.._user_id.."_token"
    local res, err = redis_cli:get(key)
    if not res or res ~= _token then
        return false, "用户未保持登录状态."
    end

	return true, "用户保持登录状态."
end

--[[
    @brief: 
            退出用户登录状态
    @param: 
            [_user_id] 用户唯一ID
            [_token] token值
    @return: 
            true: 成功; false: 失败     
]]
_M.logout = function (_user_id, _token)
    if not _user_id or not _token or _user_id == '' or _token == '' then 
        return false, "参数错误: [user_id] 或 [token] is nil."
    end

    local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR, "REDIS异常: new failed.");
        return false, "REDIS异常: new failed."
    end 

    local key = ZS_PRE_USER_KEEPALIVETOKEN.._user_id.."_token"
    redis_cli:del(key)

    return true
end

--[[
    @brief: 
            签到 
    @param: 
            [_user_id] 用户唯一ID
            [_value] token值
    @return: 
            true: 成功; false: 失败  
]]
_M.set_sign_trade = function (_user_id, _value)
    local db = mysql_db:new_db()
    if not db then 
        return false, "数据库连接异常";
    end

    mysql_db:db_begin_transaction(db)
    
    local sql = string.format("INSERT INTO t_user_help (user_id_fk, sign_time) VALUES('%s', '%s');", _user_id, ngx.localtime())
    local res, err = mysql_db:exec_query(sql, db) 
    if not res then
        mysql_db:db_rollback(db)
        mysql_db:db_set_keepalive(db)
        return false, err
    end

    --更新奖励 TODO 。。。
     -- -- res = user_ex_dao.update_balance(user_id, "收入", "签到奖励", value, os.date("%Y-%m-%d %H:%M:%S", os.time()), "用户签到奖励钻石"..value)
     -- local sql = string.format("update t_game_account set balance = balance + %d  where user_code_fk = '%s';", _value, _user_id) 
     -- local res, err, errcode, sqlstate = mysql_cli:query(sql) 
     -- if not res then 
     --     return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "更新账户余额失败", string.format("DB error: %s, code='%s'", err, errcode))
     -- end

     local cur_time = ngx.localtime()
     --需要确认账户货币类型和账户类型
     local params = {
         trade_no = incr_help.get_time_union_id(),
         order_no_fk = "",
         trade_type_fk = "签到奖励",
         trade_from_account_type = "ZSACCOUNT",
         trade_from_id = "server_acount",
         trade_from_amount = _value,
         trade_from_amount_type = "ZSB",
         trade_to_account_type = "ZSACCOUNT",
         trade_to_id = _user_id,
         trade_to_amount = _value,
         trade_to_amount_type = "ZSB",
         initiate_time = cur_time,
         pay_time = cur_time,
         finish_time = cur_time,
         trade_state = "TRADE_SUCCESS",
         --remarks = "系统交易"
     }
    
    local sql = mysql_help.insert_help("t_trade_tf", params) 
    ngx.log(ngx.ERR, "[set_sign_trade] "..sql )
    local res, err = mysql_db:exec_query(sql, db) 
    if not res or tonumber(res["affected_rows"]) == 0  then
        mysql_db:db_rollback(db)
        mysql_db:db_set_keepalive(db)
        return false, err
        --return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "写入交易流水失败", string.format("DB error: %s, code='%s'",err,errcode))
    end

    local res, err = mysql_db:db_commit(db)
    if not res then
        mysql_db:db_rollback(db)
        mysql_db:db_set_keepalive(db)
        ngx.log(ngx.ERR,"bad result: ", err,": ",errcode, ": ", sqlstate,".");
        return false, err
    end   
    
    mysql_db:db_set_keepalive(db)
    return true
end

--[[
    @brief: 
            获取签到信息 
    @param: 
            [_user_id] 用户唯一ID
    @return: 
            返回签到信息; false: 失败  
]]
_M.get_user_sign_info = function ( _user_id )
    if not _user_id or _user_id == '' then
        return false, "参数错误 [user_id] 为空."
    end

    local sql = string.format("SELECT * from t_user_help WHERE user_id_fk='%s' and date_format(sign_time, '%%Y%%m')=date_format(CURDATE(), '%%Y%%m');", _user_id)
    return mysql_db:exec_once(sql)
end

--[[
    @brief: 
            获取最近几天内签到信息  最多取100条数据
    @param: 
            [_user_id:string] 用户唯一ID
            [_day:number] 最近天数
    @return: 
            返回签到信息; false: 失败  
]]
_M.get_user_sign_info_by_day = function (_user_id, _day)
    if not _user_id or _user_id == '' then
        return false, "参数错误 [user_id] 为空."
    end

    if not _day or type(_day) ~= 'number' then
        _day = 0
    end

    --最大支持100天数据
    if _day > 100 then
        _day = 100
    end

    _day = _day - 1

    local sql = string.format("SELECT * from t_user_help WHERE user_id_fk='%s' and DATE_SUB(CURDATE(), INTERVAL %d DAY) <= date(sign_time);", _user_id, _day)
    --ngx.log(ngx.ERR, "sql: ", sql)
    return mysql_db:exec_once(sql)
end

--[[
    @brief: 
            验证邮箱账号是否已经注册
    @param: 
            [_email] 邮箱账号
    @return: 
            true: 已经注册; false: 未注册     
]]
_M.is_email_exist = function (_email)
    if not _email or _email == "" then
        return false, "参数错误."
    end

    local sql = string.format("SELECT * FROM t_user WHERE email='%s';", _email)
    local res, msg = mysql_db:exec_once(sql)
    if not res then
        return false, "数据库操作异常."
    end

    if not res[1] then 
        return false
    else 
        return true
    end
end

--[[
    @brief: 
            验证手机号是否已经注册
    @param: 
            [_phone_number] 手机号
    @return: 
            true: 已经注册; false: 未注册     
]]
_M.is_mobile_phone_exist = function (_phone_number)
    if not _phone_number or _phone_number == "" then
        return false, "参数错误."
    end

    local sql = string.format("SELECT * FROM t_user WHERE phone_number='%s';", _phone_number)
    local res, msg = mysql_db:exec_once(sql)
    if not res then
        return false, "数据库操作异常."
    end

    if not res[1] then 
        return false
    else 
        return true
    end
end

--[[
    @brief: 
            验证用户名是否已经注册
    @param: 
            [_user_name] 用户名
    @return: 
            true: 已经注册; false: 未注册     
]]
_M.is_user_name_exist = function (_user_name)
    if not _user_name or _user_name == "" then
        return false, "参数错误."
    end

    local sql = string.format("SELECT * FROM t_user WHERE user_name='%s';", _user_name)
    local res, msg = mysql_db:exec_once(sql)
    if not res then
        return false, "数据库操作异常."
    end

    if not res[1] then 
        return false
    else 
        return true
    end
end

return _M
