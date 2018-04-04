--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:mail_dao.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  站内信操作, 系统通知用户消息
--]]

local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local redis_help = require "common.db.redis_help"
local mysql_help = require "common.db.mysql_help"
local logs_help = require "common.logs.logs_help"
local uuid_help = require "common.uuid_help"
local incr_help = require "common.incr_help"
local random_help = require "common.random_help"


local _M = {
-- local Access_Key_ID = "LTAIsvG38Qe4YuYx"
-- local Access_Key_Secret = "OyKGqd6GvQQAHehaX5r1CijFyHedHp"
-- local SignName = "正溯网络"
-- local TemplateCode = "SMS_119920940"
}
 
 _M.get_mails = function( user_code, index, size)
    local sql = string.format("SELECT * from t_platform_mail WHERE user_code_fk='%s'", user_code)
	if index then 
		sql = sql .. " LIMIT " .. index .. "," .. size 
	end
	sql = sql .. ";"
    return mysql_db:exec_once(sql)
end

--[[
-- _M.add_mail() 添加站内信
    _mail = {
        user_code=xx,
        content = xx,
    }

-- @param _mail mail
-- @param _is_msg 是否需要发送短信
-- @return 
--]]
 _M.add_mail = function ( _mail ,_is_msg)  

    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end
    -- 默认约束 #000000 
    -- local msg_context = string.gsub(_msg_context, "#000000" , _msg_code)
   
    local str = mysql_help.insert_help("t_platform_mail", _mail)
    
    local res, err, errcode, sqlstate = mysql_cli:query(str)
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
        return nil,errcode;
    end 

    -- 通过订阅发送
    local redis_cli = redis_help:new()
    if redis_cli then  
        redis_cli:publish(ZS_MACHINE_ONLINE_PRE.._mail.user_code_fk,
            cjson.encode({process_type=0x1e, code=200, msg=_mail.content})) 
    end
    
    -- 发送短信通知
    if _is_msg then
        

    end


    return res
 end


--[[
-- _M.read_mail() 读取站内信
 
-- @param _mail 读取 mail 其中 id_pk or user_code_fk 只有一个值有效
-- @param _msg_code 验证码
-- @return 
--]]
 _M.read_mail = function( _mail )   
	-- 发送短信信息写入mysql 数据库,短信信息未来写入分布式数据库中
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end
    -- 默认约束 #000000 
    -- local msg_context = string.gsub(_msg_context, "#000000" , _msg_code)
    
    local str = mysql_help.update_help("t_platform_mail", {is_read = 1},_mail)
    
    local res, err, errcode, sqlstate = mysql_cli:query(str)
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
        return nil,errcode;
    end 
    return res 

end
 
_M.delete_mail = function(user_code, id) 
    local sql = "DELETE from t_platform_mail WHERE user_code_fk='" .. user_code .. "' AND id_pk='" .. id .. "';"
    local res = mysql_db:exec_once(sql)
end
 
_M.delete_mail_all = function(user_code) 
    local sql = "DELETE from t_platform_mail WHERE user_code_fk='" .. user_code .. "';"
    return mysql_db:exec_once(sql)
end

return _M