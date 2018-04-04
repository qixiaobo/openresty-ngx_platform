--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:log.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  log 功能,系统默认进行网络日志记录,当网络不通时或用户配置时才进行本地文件写入
--]]

local syslog = require "logs.syslog"
 


-- 记录json之后将发送到本地或者网络的日志服务器上
-- ngx.log(ngx.ERR,"eeeee0-----------",logs_help.getJsonMsg())



-- local logger = require "resty.logger.socket"
-- if not logger.initted() then
--     local ok, err = logger.init{
--         host = '192.168.1.200',
--         port = 5858,
--         sock_type="tcp",
--         flush_limit = 1,   --日志长度大于flush_limit的时候会将msg信息推送一次
--         -- drop_limit = 99999,
--     }
--     if not ok then
--         ngx.log(ngx.ERR, "failed to initialize the logger: ",err)
--         return
--     end
-- end

-- local msg = "test------"
-- local bytes, err = logger.log(msg)
-- if err then
--     ngx.log(ngx.ERR, "failed to log message: ", err)
--     return
-- end
-- ngx.log(ngx.ERR,msg)
-- local cjson = require "cjson"
-- -- local client = require "resty.kafka.client"
-- local producer = require "resty.kafka.producer"
-- local logs_help = require "logs.logs_help"


-- local broker_list = {
--     { host = "192.168.1.200", port = 9092 },
-- }

-- local key = "key"
-- local message = "hello world"
-- ngx.log(ngx.ERR,"log by lua ",message)
-- -- usually we do not use this library directly
-- -- local cli = client:new(broker_list)
-- -- local brokers, partitions = cli:fetch_metadata("test")
-- -- if not brokers then
-- --     ngx.say("fetch_metadata failed, err:", partitions)
-- -- end
-- -- ngx.say("brokers: ", cjson.encode(brokers), "; partitions: ", cjson.encode(partitions))


-- -- sync producer_type
-- -- local p = producer:new(broker_list)

-- -- local offset, err = p:send("test", key, message)
-- -- if not offset then
-- --     ngx.log(ngx.ERR,"send err:", err)
-- --     return
-- -- end 

-- -- this is async producer_type and bp will be reused in the whole nginx worker
-- local bp = producer:new(broker_list, { producer_type = "async" })

-- local ok, err = bp:send("test", key, message)
-- if not ok then
--     ngx.log(ngx.ERR,"send err:", err)
--     return
-- end
