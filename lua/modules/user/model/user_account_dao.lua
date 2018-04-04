--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:game_account.lua
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
local _M = {} 

--[[
    @brief: 
             获取用户账号信息
    @param:  
            [_user_id:string] 用户唯一ID
    @return:
            true, 返回用户信息    false, 错误信息
]]
function _M.get_user_account_info(_user_id) 
    if not _user_id or _user_id == '' then
        return false, "参数错误, [_user_id] 不能为空."
    end

    local sql = "select * from t_account where user_id_fk = '".._user_id.."';"
    local res, code, err = mysql_db:exec_once(sql) 
    if not res then
        return false, err;
    end

    if not res[1] then
        return false, "没有ID: ".._user_id.." 用户."
    end

    return true, res[1]
end

--[[
    @brief: 
             新增账户,系统默认创建时新增
    @param:  
            [_user_account:table] 用户账户信息
    @return：
            true 创建成功 false 创建失败
]]
function _M.add_user_account(_user_account, _db) 
    if not _user_account or type(_user_account) ~= 'table' then
        return false, "参数错误, [_user_account] 错误."
    end 

    if not _user_account.user_id_fk or _user_account.user_id_fk == '' then
        return false, "参数错误, [user_id_fk] 错误."
    end 

    --查询改id是否已经存在
    local sql = "select * from t_user where user_id = '".._user_account.user_id_fk.."';"
    local res, err = mysql_db:exec_query(sql, _db) 
    if not res then
        return false, err;
    else
        if not res[1] then
            return false, "用户ID: ".._user_account.user_id_fk.." 不存在."
        end
    end
 
    --查询该用户是否已经存在账户
    local sql = "select * from t_account where user_id_fk = '".._user_account.user_id_fk.."';"
    local res, code, err = mysql_db:exec_query(sql, _db) 
    if not res then
        return false, err;
    else
        if res[1] then
            return false, "用户ID: ".._user_account.user_id_fk.." 已经存在账户.";
        end
    end

    local sql = mysql_help.insert_help("t_account", _user_account)
    local res, code, err = mysql_db:exec_query(sql, _db) 
    if not res then
        return false, err;
    end 
    
    return true, "创建账户成功."
end

--[[
    @brief: 
            删除账户
    @param:  
            [_user_id:string] 用户唯一ID
    @return:
            true 删除成功 false 删除失败
]]
function _M.delete_user_account( _user_id ) 
    if not _user_id or _user_id == '' then
        return false, "参数错误, [_user_id] 不能为空."
    end

    local sql = "delete from t_account where user_id_fk = '".._user_id.."';"
    local res, code, err = mysql_db:exec_once(sql) 
    if not res then
        return false, err;
    end

    if res.affected_rows > 0 then
        return true, "删除账户成功."
    else
        return false, "删除账户失败或账户不存在."
    end 
end

--[[
    @brief: 
            更新账户信息
    @param:  
            [_param:table] 用户唯一ID
                {
                    user_id_pk = '1234455',
                    balance = 1000,
                    consume_balance = 0,
                    integral = 0,
                    popularity = 0,
                    pay_password='xasaxxxxx',
                    account_state='',
                    account_type='',
                    currency_type=''
                }
    @return:
            true 更新成功 false 更新失败
]]
function _M.update_user_account( _param ) 
    if not _param or type(_param) == 'table' then
        return false, "参数错误, [_param] 错误."
    end

    --参数检测
    if not _param.user_id or _param.user_id == '' then
        return false, "参数错误, [user_id] 不正确"
    end
    
    local account_info = {}
    account_info.user_id_fk = _param.user_id_pk
    account_info.balance = _param.balance
    account_info.consume_balance = _param.consume_balance
    account_info.integral = _param.integral
    account_info.popularity = _param.popularity
    account_info.pay_password = _param.pay_password
    account_info.account_state = _param.account_state
    account_info.account_type = _param.account_type
    account_info.currency_type = _param.currency_type

    local condition = {}
    condition.user_id_fk = _param.user_id_pk
    --数据更新
    local sql = mysql_help.update_help('t_account', account_info, condition)
    local res, code, err = mysql_db:exec_once(sql) 
    if not res then
        return false, err;
    end

    if res.affected_rows > 0 then
        return true, "更新账户成功."
    else
        return false, "更新账户失败或账户不存在."
    end 
end
 
return _M