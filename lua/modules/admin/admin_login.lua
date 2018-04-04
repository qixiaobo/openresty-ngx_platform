--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:admin_login.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  后台登陆界面,后台登陆界面需要登陆需要进行加密处理,三次错误之后需要输入验证码模块进行否则无法进行登陆操作
--  
--]]

-- 判断用户是否登陆,如果登陆则进行操作

local cjson  = require "cjson"
local sign = require "admin.auth.sign_in"

local admin_log_dao = require "admin.model.admin_log_dao"

-- 未登录,判断是否传递登陆post请求,如果请求中存在字段,则进行获取之后判断是否登陆
local request_help = require "common.request_help" 
local api_data_help = require "common.api_data_help"

-- post 表示登陆 
if request_help.get_or_post() then
	-- 判断用户账户和密码,如果正确,写入session,否则提示用户账户或者密码错误
	local userData = request_help.get_all_args();
	if not userData.name or not userData.password then
		ngx.say(api_data_help.new_failed())   
		return 
	end
	 
	-- sign.signIn(userData.name,userData.password) 
	local adminUser = sign.signIn(userData.name,userData.password)
 	
	if not adminUser then  
		ngx.say(api_data_help.new_failed())  
		return  
	end 
	local jsonData = api_data_help.new_success();
	--jsonData.data = adminUser; 
	admin_log_dao.add_log(adminUser.id_pk,"login failed","admin_login")
	ngx.say(jsonData)   
 	return 
else 
	local template = require "resty.template"
	-- Using template.new
	-- local view = template.new "view.html"
	-- view.message = "Hello, World!"
	-- view:render()
	-- Using template.render
	-- template.render("admin/web/view.html", { message = "<p>Hello, World!</p>",aside=true })
 
	template.render("admin/admin_login.html", { message = '' })
	-- local view     = template.new("admin/web/view1.html", "admin/web/layout.html")
	-- view.title     = "Testing lua resty template blocks"
	-- view.message   = "Hello, World33!"
	-- view.keywords  = { "test", "lua", "template", "blocks" }
	-- view:render()
end

