--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:auth_manager.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  权限管理
--  
--]]
local sign = require "admin.auth.sign_in"
local cjson  = require "cjson"
-- if not sign.isSignIn() then 
-- 	return ngx.redirect("admin_login.shtml");
-- end

local template = require "resty.template"

local auths = require "admin.model.authority_dao".getAuths()
 
template.render("admin/auth_manager.html", { message = "<p>Hello, Worlaaaaadsfasfsd!</p>",auths = auths })