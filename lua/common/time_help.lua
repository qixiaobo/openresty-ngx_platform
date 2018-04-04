--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:time_help.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  关于uuid的简单封装,主要用于各式各样的uuid唯一键值的场合,可用于其他多进制的数据转化形成唯一编码信息的输出情形
	根据系统多个版本进行升级使用
	uuid_help.lua  依赖jit-uuid , lua-resty-UUID( 扩展了64进制和94进制, 94进制作为系统唯一code存储使用,不作为用户级使用,
	用户等级使用64进制
--]]

local _M = {};
local ffi = require("ffi")
ffi.cdef[[
    struct timeval {
        long int tv_sec;
        long int tv_usec;
    };
    int gettimeofday(struct timeval *tv, void *tz);
]];
local tm = ffi.new("struct timeval");

-- 返回微秒级时间戳
function _M.current_time_millis()   
    ffi.C.gettimeofday(tm,nil);
    local sec =  tonumber(tm.tv_sec);
    local usec =  tonumber(tm.tv_usec);
    return sec + usec * 10^-6;
end

-- 返回微秒级时间戳
function _M.current_time_micro()   
    ffi.C.gettimeofday(tm,nil);
    local sec =  tonumber(tm.tv_sec);
    local usec =  tonumber(tm.tv_usec);
    return (sec + usec * 10^-3)*1000;
end

-- 返回微秒级时间段
function _M.current_millis()   
    ffi.C.gettimeofday(tm,nil);  
    return  tonumber(tm.tv_usec);
end

-- 返回微秒级时间段
function _M.current_date(_date_temp) 

    return os.date( _date_temp  and  _date_temp or  "%Y-%m-%d" ,os.time())
end

-- 返回微秒级时间段
function _M.current_time(_time_temp)   
      
    return os.date( _time_temp  and  _time_temp or "%H:%M:%S",os.time())
end

-- 返回微秒级时间段
function _M.current_date_time(_time_temp)  
    -- os.date("%Y-%m-%d %H:%M:%S",os.time())
    -- return  ngx.localtime()
    return os.date( _time_temp  and  _time_temp or "%Y-%m-%d %H:%M:%S" ,os.time())
end

return _M;