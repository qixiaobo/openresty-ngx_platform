--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:url_redirect.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--	登录授权界面的重定向,用于网页重定向功能
--]]
local request_help = require "common.request_help"
local _M = {
	
}




--[[
-- _M.redirect_last_url() 获取当前网页的地址,如果地址中存在surl 表示当前有地址需要在执行成功之后进行跳转
-- example
	 
-- @param 无
-- @return 当前执行环境的目录
--]]
_M.redirect_last_url = function( ... )
	-- body
	local args = ngx.req.get_uri_args()
	if not args then return end;
	local url = nil
	local iSize = 0
	for k,v in pairs(args) do
		if k == "redirect_url" then
			url = v
		end 
	end   
	if url then 
		-- local url = ngx.unescape_uri(url) 
		return ngx.redirect(url); 
	end
 
end




--[[
-- _M.make_redirect_url() 获取当前网址, 进行字符串编码处理 ,该类型主要用于网页客户端
-- example
	 
-- @param 无
-- @return 当前执行环境的目录
--]]
_M.make_redirect_url = function (  )
	 
	return "redirect_url="..ngx.escape_uri(request_help.get_curl_url()) 
end


return _M

