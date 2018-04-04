--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:admin_index.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  后台管理中心界面
--  
--]]

local cjson  = require "cjson" 
local template = require "resty.template" 
local sign = require "admin.auth.sign_in"

-- 定义lua session 状态数据关联
local adminUser = sign.getFiled("admin_name")

local function makeMenu(_tmenu)
 	if not _tmenu then 
 		ngx.log(ngx.ERR,"-------------error      ")
 		return ""
 	end
 	if table.getn(_tmenu) < 1 then  return "" end

    local str = "<li>"
    -- ngx.log(ngx.ERR,"-------------length      ",table.getn(_tmenu))
    for i=1,table.getn(_tmenu) do
        local menuTemp = _tmenu[i]
        if not menuTemp then 
			ngx.log(ngx.ERR,"+++++++++++++++++++++menu is error")
        end
        if menuTemp.childList then
            -- 有子菜单的格式
            str = str ..  string.format('<a href="#"><i class="fa fa-home"></i><span class="nav-label">%s</span><span class="fa arrow"></span></a>',menuTemp.menu_name)

            str = str .. '<ul class="nav nav-second-level">' 
           
           	str = str .. makeMenu(menuTemp.childList)
           
            str = str .. '</ul>'
        else
            str = str ..  string.format('<a class="J_menuItem" href="%s"><i class="fa fa-columns"></i>  <span class="nav-label">%s</span></a>',menuTemp.action_url,menuTemp.menu_name)
            
        end

    end
    str = str.."</li>"
    return str
end
local menustr = makeMenu(cjson.decode(sign.getFiled("menu_list")))
 

template.render("admin/index.html", { menustr = menustr })


