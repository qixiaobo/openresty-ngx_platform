--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:db_mysql.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  主要用于对mysql的简单封装

    update delete insert 返回的数据结构如下
    {"insert_id":55,"affected_rows":1,"server_status":2,"warning_count":0}
    select 返回的结果为数组对象{} or {{name="zhang",password="123456"},{name="zhang",password="123456"}}

--]]

local mysql = require "resty.mysql"
local db_conf = require "conf.db_conf"

local g_mysql_config = db_conf.mysql_master;

local _M = {}

function _M.new(self,mysql_config)
    local db, err = mysql:new()
    if not db then
        ngx.log(ngx.ERR,"new error!-------")
        return nil, "Create DB error"
    end
    if not mysql_config then mysql_config = g_mysql_config end
    db:set_timeout(1000) -- 1 sec
    local ok, err, errno, sqlstate = db:connect(mysql_config)

    if not ok then
        ngx.log(ngx.ERR,"connect error!-------")
        return nil, "Connect DB error"
    end

    local query = "SET NAMES UTF8" 
    local result, errmsg, errno, sqlstate = db:query(query)
    if not result then
        return nil, "mysql.query_failed: " .. (errmsg or "nil") .. ", errno:" .. (errno or "nil") ..
                ", sql_state:" .. (sqlstate or "nil")
    end

    db.close = close
    return db, "Init DB successful"
end

function _M.new_nopool(self)
    local db, err = mysql:new()
    if not db then
        ngx.log(ngx.ERR,"new error!-------")
        return nil
    end
    -- db:set_timeout(1000) -- 1 sec
    local ok, err, errno, sqlstate = db:connect(mysql_config)

    if not ok then
        ngx.log(ngx.ERR,"connect error!-------")
        return nil
    end

    local query = "SET NAMES UTF8" 
    local result, errmsg, errno, sqlstate = db:query(query)
    if not result then
        return nil, "mysql.query_failed: " .. (errmsg or "nil") .. ", errno:" .. (errno or "nil") ..
                ", sql_state:" .. (sqlstate or "nil")
    end

    --db.close = close_nopool
    return db
end

function close(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end
    if self.subscribed then
        return nil, "subscribed state"
    end 
    return sock:setkeepalive(10000, 50)
end

function close_nopool(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end
    if self.subscribed then
        return nil, "subscribed state"
    end 
    return sock:setkeepalive(10000, 50)
end

function _M:exec_once(sql)
    local db = _M:new()
    if not db then
        return nil, "Create mysql db object failed."
    end
    local res, errmsg, errcode, sqlstate = db:query(sql)
    if not res then
        db:close()
        ngx.log(ngx.ERR,"=====> [数据库] Database Error: sql=["..sql.. "], " .. errmsg.. ", code=".. errcode.. ", sqlstate=".. sqlstate.. ".");
        return nil, string.format("Database error: code='%s', msg='%s'", errcode, errmsg)
    end
    db:close()
    return res
end


function _M:exec_query(sql, db)
    local db_cli = db or _M:new()
    if not db_cli then
        return nil, "Create mysql db object failed."
    end
    local res, errmsg, errcode, sqlstate = db_cli:query(sql)
    if not res then
        if not db then
            db_cli:close()
        end
        ngx.log(ngx.ERR,"=====> [数据库] Database Error: sql=["..sql.. "], " .. errmsg.. ", code=".. errcode.. ", sqlstate=".. sqlstate.. ".");
        return nil, string.format("Database error: code='%s', msg='%s'", errcode, errmsg)
    end
    ngx.log(ngx.ERR,"=====> [数据库] Database successful: sql=" ..sql )
    if not db then
        db_cli:close()
    end
    return res
end

function _M:new_db(mysql_config)
    local db, err = mysql:new()
    if not db then
        ngx.log(ngx.ERR,"new error!-------")
        return nil, "Create DB error"
    end
    if not mysql_config then mysql_config = g_mysql_config end
    db:set_timeout(1000) -- 1 sec
    local ok, err, errno, sqlstate = db:connect(mysql_config)
    if not ok then
        ngx.log(ngx.ERR,"connect error!-------")
        return nil, "Connect DB error"
    end

    local query = "SET NAMES UTF8" 
    local result, errmsg, errno, sqlstate = db:query(query)
    if not result then
        return nil, "mysql.query_failed: " .. (errmsg or "nil") .. ", errno:" .. (errno or "nil") ..
                ", sql_state:" .. (sqlstate or "nil")
    end

    return db, "Init DB successful"
end

function _M:db_begin_transaction(db)
    if not db then
        return nil, ZS_ERROR_CODE.MYSQL_ERR, "db is nil.";
    end

    local res, errmsg, errcode, sqlstate = db:query("BEGIN;")
    if not res then
        ngx.log(ngx.ERR,"=====> [数据库] Database Error: sql=["..sql.. "], " .. errmsg.. ", code=".. errcode.. ", sqlstate=".. sqlstate.. ".");
        return nil, ZS_ERROR_CODE.MYSQL_ERR, string.format("数据库操作失败! code='%s', msg='%s'",errcode, errmsg)
    end

    return res, ZS_ERROR_CODE.RE_SUCCESS, "开启事务成功.", db
end

function _M:db_close(db)
    if not db then
        return nil, ZS_ERROR_CODE.MYSQL_ERR, "db is nil.";
    end
    
    return db:close()
end

function _M:db_set_keepalive(db, timeout, pool_size)
    if not db then
        return nil, ZS_ERROR_CODE.MYSQL_ERR, "db is nil.";
    end
    
    if not timeout then timeout = 60000 end
    if not pool_size then pool_size = 100 end

    return db:set_keepalive(timeout, pool_size)

end

function _M:db_rollback(db)
    if not db then
        return nil, ZS_ERROR_CODE.MYSQL_ERR, "db is nil.";
    end

    local res, errmsg, errcode, sqlstate = db:query("ROLLBACK;")
    if not res then
        ngx.log(ngx.ERR,"=====> [数据库] Database Error: sql=["..sql.. "], " .. errmsg.. ", code=".. errcode.. ", sqlstate=".. sqlstate.. ".");
        return nil, ZS_ERROR_CODE.MYSQL_ERR, string.format("数据库操作失败! code='%s', msg='%s'",errcode, errmsg)
    end

    return res, ZS_ERROR_CODE.RE_SUCCESS, "回退事务成功.", db
end

function _M:db_commit(db)
    if not db then
        return nil, ZS_ERROR_CODE.MYSQL_ERR, "db is nil.";
    end

    local res, errmsg, errcode, sqlstate = db:query("COMMIT;")
    if not res then
        ngx.log(ngx.ERR,"=====> [数据库] Database Error: sql=["..sql.. "], " .. errmsg.. ", code=".. errcode.. ", sqlstate=".. sqlstate.. ".");
        return nil, ZS_ERROR_CODE.MYSQL_ERR, string.format("数据库操作失败! code='%s', msg='%s'",errcode, errmsg)
    end

    return res, ZS_ERROR_CODE.RE_SUCCESS, "提交事务成功.", db
end


_M.errorCount = 0
_M.okCount = 0
return _M