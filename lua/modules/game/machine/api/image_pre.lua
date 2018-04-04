--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:machine_records.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  机器投币和返回记录
--]]

local cjson = require "cjson" 
local redis_help = require "common.db.redis_help"
local api_data_help = require "common.api_data_help"


local args = ngx.req.get_uri_args()
local machine_code = args.machine_code

local redis_cli = redis_help:new()
if not redis_cli then
	ngx.exit(500)
end

local image_name = redis_cli:get("machine_pre_image_"..machine_code)
if not image_name then 
	ngx.exit(500)
end 
local dst_dir = "/opt/project/fengmi_game/html/upload/"


-- ngx.say(string.sub(dst_dir..machine_code..".jpg", str_len - 4 ,str_len - 4 )) 
-- local res = dst_dir..machine_code.."_1.jpg"
--   local str_len = string.len(res)
--   ngx.say(res)
--   local _file_name = ""
--     if  string.sub(res, str_len - 4 ,str_len - 4) == '1' then
--         _file_name = string.sub(res,1,str_len-5).."2.jpg"
--     else
--         _file_name = string.sub(res,1,str_len-5).."1.jpg"
--     end

-- ngx.say(_file_name)

local file = io.open(dst_dir..image_name , 'rb'); 
local steam = file:read("*a")
file:close(); 
ngx.header["Content-Type"] = "image/jpg";  
ngx.say(steam)
-- ngx.redirect("/upload/"..image_name)