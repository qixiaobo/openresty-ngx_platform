--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:role_manager.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  角色管理
--  
--]]
local cjson  = require "cjson"
local sign = require "admin.auth.sign_in"

-- if not sign.isSignIn() then 
-- 	return ngx.redirect("admin_login.shtml");
-- end

local template = require "resty.template"

local roles = require "admin.model.role_dao" .get_roles()
ngx.log(ngx.ERR,cjson.encode(auths))
template.render("admin/role_manager.html", { message = "<p>Hello, Worlaaaaadsfasfsd!</p>",roles = roles })