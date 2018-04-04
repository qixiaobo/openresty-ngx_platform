--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:admin_update.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  管理员修改 
--  
--]]

local cjson  = require "cjson"  
local template = require "resty.template"
local sign = require "admin.auth.sign_in"
local db_json_help = require "common.db.db_json_help"

 
local role_dao = require "admin.model.role_dao"  
local admin_dao = require "admin.model.admin_dao"
--[[ 
    首先判断有无token, 没有直接退出  
--]]    


local args = ngx.req.get_uri_args()
local admin_id = args["admin_id"]

local _admin = admin_dao.get_admin(admin_id)

if not _admin then 
	
	return ngx.exit(404)
end
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



local role_list = role_dao.getRoles()
local menu_tree = db_json_help.cjsonPFTable(role_list,"id_pk","parent_id_fk")

local role_tree_str = role_tree(cjson.decode(menu_tree))
 

template.render("admin/admin_update.html", { title="修改管理员",role_tree_str = role_tree_str, admin=_admin })

