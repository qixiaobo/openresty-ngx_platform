--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:admin_manager.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  后台管理中心界面
--  
--]]
local sign = require "admin.auth.sign_in"
local cjson  = require "cjson"
-- if not sign.isSignIn() then 
-- 	return ngx.redirect("admin_login.shtml");
-- end

local template = require "resty.template"

local admins = require "admin.model.admin_dao" .getAdmins()

template.render("admin/admin_manager.html", 
	{ message = "<p>Hello, Worlaaaaadsfasfsd!</p>",admins = admins })