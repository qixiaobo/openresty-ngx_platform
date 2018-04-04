--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:token_auth.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  管理员后台类型的登录权限判断, 系统支持web以及ajax异步请求的接口方式,异步请求同时也会进行权限判断和页面重定向

--]]
local cjson = require "cjson"  
local api_data_help = require "common.api_data_help"
local sign_in = require "admin.auth.sign_in"
local redirect_url = require "common.redirect_url"

 --[[

	首先判断有无token,没有直接退出
	判断是否拥有权限
 --]]     
local last_url = ngx.var.request_uri 

if last_url == "/admin/admin_login.shtml" or last_url == "/admin/admin_login.do"  then
	return
end
local session = require "resty.session".open() 
ngx.log(ngx.ERR,"  session test---------------     ", ngx.worker.id() , sign_in.isSignIn() ,"  ",ngx.encode_base64(session.secret)) 
if sign_in.isSignIn()  then  
	if serverType == "1" or serverType == "2" then

		-- 判断一次逻辑
	   if not auth_obj.auth_check() then
	   		ngx.say(api_data_help.new(403))
	   		ngx.exit(200)
	   end
	else
	
	end
else
			-- 网页进行登录页面重定向 
		-- 获得当前页面地址   
		local cur_url = redirect_url.make_redirect_url()
		-- ngx.log(ngx.ERR,"---------cur_url:",cur_url) 
		-- ngx.redirect("/admin/admin_login.shtml?"..cur_url)
		ngx.redirect("/admin/admin_login.shtml")
		 
end