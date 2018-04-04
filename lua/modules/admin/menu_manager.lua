--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:admin_index.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  后台管理中心界面
--  
--]]
local sign = require "admin.auth.sign_in"
local cjson  = require "cjson" 
 
 --[[

    首先判断有无token,没有直接退出

 --]]    

local template = require "resty.template"
local menu_dao = require "admin.model.menu_dao"
local db_json_help = require "common.db.db_json_help"

local menu_list = menu_dao.get_menu_tree()
for i=1,#menu_list  do
	for k,v in pairs(menu_list[i]) do
		if v == ngx.null then
			menu_list[i][k] = nil
		end
	end
end
local menu_tree = db_json_help.cjsonPFTable(menu_list,"id_pk","parent_id_fk")


ngx.log(ngx.ERR,menu_tree)

template.render("admin/menu_manager.html", { menu_tree=menu_tree })

