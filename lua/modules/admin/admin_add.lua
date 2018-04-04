--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:admin_add.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  添加管理员
--  
--]]
local sign = require "admin.auth.sign_in"
local cjson  = require "cjson" 
 
 --[[

    首先判断有无token,没有直接退出

 --]]    

local template = require "resty.template"
local role_dao = require "admin.model.role_dao"
local db_json_help = require "common.db.db_json_help"



-- 生成 role tree 字符串
local function role_tree(_role_tree)
	local str = "" 
	for i=1,#_role_tree do
		str = str..[[<li>]] .. string.format([[<a href="#" onclick="role_select(%d)" >%s</a>]],_role_tree[i].id_pk,_role_tree[i]["role_name"])
		
		if _role_tree[i].childList then
			str = str..[[<ul class="dl-submenu">]]
			str = str .. role_tree(_role_tree[i].childList)
			str = str .. [[</ul>]]
		end 
		str = str..[[</li>]] 
	end  
	 
	return str
end
local role_list = role_dao.get_roles()
local menu_tree = db_json_help.cjsonPFTable(role_list,"id_pk","parent_id_fk")

local role_tree_str = role_tree(cjson.decode(menu_tree))

ngx.log(ngx.ERR,'-----', role_tree_str, menu_tree)

template.render("admin/admin_add.html", { title="添加管理员",role_tree_str = role_tree_str })

