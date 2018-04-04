--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_ex_info.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--	用户中心, 用户扩展信息页面
--]]

local sign = require "user.auth.sign_in"
local cjson  = require "cjson"
if not sign.isSignIn() then 
	return ngx.redirect("/user/admin_login.shtml");
end
 

-- 读取用户基础信息
local user_ex_dao = require "user.model.user_ex_dao"

local user_code = sign.getFiled("user_code")
local res = user_ex_dao.get_user_ex(user_code)

if not res[1] then 
	-- 重定向
end

local user_info = res[1]


local template = require "resty.template"
	-- Using template.new
	-- local view = template.new "view.html"
	-- view.message = "Hello, World!"
	-- view:render()
	-- Using template.render
	-- template.render("admin/web/view.html", { message = "<p>Hello, World!</p>",aside=true })


template.render("goodtime/personalInformation.html", { user_info = user_info })