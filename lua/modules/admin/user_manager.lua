--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_manager.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  用户管理相关,主要包括 用户查询,账号封停,新增用户,密码重置等
--  
--]]
local sign = require "admin.auth.sign_in"
local cjson  = require "cjson"
if not sign.isSignIn() then 
	return ngx.redirect("admin_login.shtml");
end

local template = require "resty.template"
 

-- template.render("admin/user_manager.html", { message = "<p>Hello, Worlaaaaadsfasfsd!</p>",admins = admins })