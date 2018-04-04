--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:do1.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  xxx.do api 访问模式, 本文件主要实现权限相关测试
--  
--]]

--[[ 1, 引入常用函数 当前函数一般入口类必选,用于json编码解码, 请求帮助, 以及 输出结构化处理 ]]
local cjson = require "cjson"  
local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help"



--[[
	2, 引入功能类函数 和 dao 函数
]]
local time_help = require "common.time_help"
-- ......

ngx.say("do1 success")
