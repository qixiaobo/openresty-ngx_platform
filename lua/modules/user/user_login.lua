--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_login.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--	用户登录界面,支持第三方登录,如微信,qq,微博等登录
--]]

local cjson  = require "cjson"
local sign = require "user.auth.sign_in"
local redircet_url = require "common.redirect_url"
local requestHelp = require "common.request_help"
local template = require "resty.template"
local uuid_help = require "common.uuid_help":new(ZS_USER_UUID)
local User = require "user.model.user"
local UserDao = require "user.model.user_dao"

 
-- post 登录提交
if ngx.var.request_method == "POST" then
--	查询当前是否有数据提交,如果包含账户和密码, 判断账号密码
-- 	如果没有账号密码 则判断登录
 	
	local args = requestHelp.getAllArgs()
	if not args.user_name and not args.passwd then 
	else
		-- 登录系统
		local user = User:new({ 
	 					user_name = args.user_name,  
	 					password = UserDao.make_password(args.passwd),

 		})
 
		local res = UserDao.login(user) 
		if #res == 1 and res[1].status ==  1  then
			sign.signIn(user_name,uuid_help.get(),res)  
			redircet_url.redirect_last_url() 
		end
	end
	
end


-- 已经登录的用户直接跳转
-- if sign.isSignIn() then  
-- 	redircet_url.redirect_last_url()
-- 	return ngx.redirect("goodtime/user_center.shtml");
-- end 

 
	-- Using template.new
	-- local view = template.new "view.html"
	-- view.message = "Hello, World!"
	-- view:render()
	-- Using template.render
	-- template.render("admin/web/view.html", { message = "<p>Hello, World!</p>",aside=true })


template.render("goodtime/user_login.html", { message = '' })