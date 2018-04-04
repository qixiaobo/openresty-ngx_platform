--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:multi_languages.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  多语言初始化,
--  
--]]
local _M={}
local default_language="en"
local path='system_init.organization.international.'
local language_list={
	zh_cn="zh_cn",
	en="en",
}

for k,v in pairs(language_list) do
	_M[k] = require (path..v);
end

return _M;
