--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:regex_help.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  正则表达式相关封装,主要关于邮箱, 手机号, 身份证 等类型
--]]


local _M = {}

function _M.isEmail(_str)
	if not _str then return nil end 
	if string.len(_str or "") < 6 then return false end  
    local b,e = string.find(_str or "", '@')  
    local bstr = ""  
    local estr = ""  
    if b then  
        bstr = string.sub(_str, 1, b-1)  
        estr = string.sub(_str, e+1, -1)  
    else  
        return false  
    end  
  
    -- check the string before '@'  
    local p1,p2 = string.find(bstr, "[%w_]+")  
    if (p1 ~= 1) or (p2 ~= string.len(bstr)) then return false end  
  
    -- check the string after '@'  
    if string.find(estr, "^[%.]+") then return false end  
    if string.find(estr, "%.[%.]+") then return false end  
    if string.find(estr, "@") then return false end  
    if string.find(estr, "%s") then return false end --空白符  
    if string.find(estr, "[%.]+$") then return false end  
  
    _,count = string.gsub(estr, "%.", "")  
    if (count < 1 ) or (count > 3) then  
        return false  
    end  
  
    return true  
end


return _M