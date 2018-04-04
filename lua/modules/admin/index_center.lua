--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:index_center.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  后台管理中心界面
--  
--]]
local sign = require "admin.auth.sign_in"
local cjson  = require "cjson" 
 
 --[[

    首先判断有无token,没有直接退出

 --]]    

local template = require "resty.template"

-- 定义lua session 状态数据关联
 local adminUser = sign.getFiled("admin_name")
ngx.log(ngx.ERR,"admin-----",adminUser)
template.render("admin/index_center.html", { })


