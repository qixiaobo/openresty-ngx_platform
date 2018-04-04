--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_center.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--	用户中心, 登录之后,将显示用户的相关信息
--]]

local sign = require "user.auth.sign_in"
local cjson  = require "cjson"
if not sign.isSignIn() then 
	return ngx.redirect("/user/admin_login.shtml");
end

local template = require "resty.template"
 
	-- Using template.new
	-- local view = template.new "view.html"
	-- view.message = "Hello, World!"
	-- view:render()
	-- Using template.render
	-- template.render("admin/web/view.html", { message = "<p>Hello, World!</p>",aside=true })


template.render("goodtime/user_center.html", { message = '' })