--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:menu.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  后台基础管理模块,合并在管理员角色下,
--  菜单模块,主要涉及菜单,和现实相关的自动化
--  
--]]

local cjson = require "cjson"
local mysql = require "common.db.db_mysql"  
local uuid_help = require "common.uuid_help"  
local mysql_db = require "common.db.db_mysql"   
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help" 
local db_json_help = require "common.db.db_json_help"


local time_help = require "common.time_help"  
local incr_help = require "common.incr_help"


local  cjson = require "cjson"

local  log = ngx.log

local _M = {
-- 1	id_pk	int	11	0	0			1	0	0
-- 0	menu_name	varchar	255	0	0					0
-- 0	menu_index	int	11	0	1			0	0	0
-- 0	action_url	varchar	255	0	1		 操作地址,导航地址			0
-- 0	parent_id_fk	int	11	0	1	00000000000		0	1	1
-- 0	action_target	varchar	255	0	1					0
-- 0	auth_id_fk	int	11	0	0	0	权限id,该字段显示的依赖,如果是一级菜单直接根据是否拥有进行显示;如果为多级菜单,则如果某个角色包含该权限,该权限对应子菜单的某一项,则父菜单的显示必须显示	0	0	0
-- 0	class_name	varchar	256	0	0	fa fa-home	class 效果类名称			0	


}

-- 后台管理员menu列表
_M.menuList = nil


--[[

-- menu 结构 搜索出来直接转换为父子关系 数据库字段可能不一致,主要表示数据通信
	menuMap = {
		{menuId = 1,menuName="主页1",index=1,url="/admin/index.shtml",clazz="",childMenu={
			{menuId = 2,menuName="主页1_1",index=1,url="/admin/index1_1.shtml",clazz="",},
			{menuId = 3,menuName="主页1_2",index=2,url="/admin/index1_2.shtml",clazz="",},
		}},
		{menuId = 21,menuName="主页2",index=2,url="/admin/index.shtml",clazz="",childMenu={
			{menuId = 22,menuName="主页2_1",index=1,url="/admin/index2_1.shtml",clazz="",},
			{menuId = 23,menuName="主页2_2",index=2,url="/admin/index2_2.shtml",clazz="",},
		}},
	}
--]]

--[[
-- _M.getMenuList 获取menulist列表,由于menulist采用父子关系,故采用储存过程进行处理, 
-- 由于mysql返回数据为一层层集合,故函数将会处理一次数据结构形成父子关系
-- example

-- @param  
-- @param _password 	返回消息的主体 

--]]
function _M.getMenuList()

	local  begin_time = ngx.now();
	-- body
	-- 登陆数据库操作
	-- name = ngx.quote_sql_str(name) -- SQL 转义，将 ' 转成 \', 防SQL注入，并且转义后的变量包含了引号，所以可以直接当成条件值使用
	local db = mysql:new() 
	if not db then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin login mysql new db is nil")
		return 	nil 
	end
	-- 执行存储过程
 	local srcSql = string.format("call  _TEMP_SE_PK_FK('%s','%s','%s',%d,%d); ","t_menu_action","id_pk","MENU_PRO_CRE_PF",0,0);  
	-- 如果是root用户,则系统需要未来主义,该账户只能在本地以及指定的IP上登陆 
	-- local srcSql = string.format("select * from t_menu_action;");  
	 
	local res, err, errno, sqlstate = db:query(srcSql)
	db:close()
	if not table.isnull(res)  then
		ngx.log(ngx.ERR,"t_menu_action 读取失败,err code ",err)
	    return nil;
	end 
	for i = 1,table.getn(res) do
		--默认设置为隐藏,通过权限激活显示的菜单按钮
		res[i].isShow = false;
	end 
 
	-- begin_time = ngx.now();
	-- 将结果进行一次数据结构调整 
 	-- return db_json_help.cjsonPFTable1(res,"id_pk","parent_id_fk")
 	return res
end


--[[
-- _M.initMenuList 初始化menulist 由于系统采用的是缓存方式,所以系统会初始化所有的状态到内存中,
-- 管理员可以手动调用该对象进行初始化最新的menu
-- example

-- @param  
-- @param _password 	返回消息的主体 

--]]
function _M.initMenuList()
	-- local menustr = _M.getMenuList();
	-- if menustr then  
	-- 	_M.menuList =  cjson.decode(menustr)
	-- end
	_M.menuList =  _M.getMenuList();
	return _M.menuList
end


--[[
-- _M.add_menu 添加新菜单, 用户添加菜单,如果没有添加菜单,则添加为第一级菜单
-- example

-- @param  _menu 
-- @return res nil 表示失败 其他表示成功 如 {"insert_id":16,"affected_rows":1,"server_status":2,"warning_count":0}
--]]
function _M.add_menu( _menu )
	local db = mysql:new() 
	if not db then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"mysql new db is nil")
		return 	nil 
	end
	-- 执行存储过程
 	local srcSql = mysql_help.insert_help("t_menu_action",_menu) 
	-- 如果是root用户,则系统需要未来主义,该账户只能在本地以及指定的IP上登陆 
	-- local srcSql = string.format("select * from t_menu_action;");  
	 
	local res, err, errno, sqlstate = db:query(srcSql) 
	if not table.isnull(res) then
		ngx.log(ngx.ERR,"err code ",err," errno ",errno)
	    return nil;
	end   
 	return res
end

--[[
-- _M.update_menu 修改菜单功能
-- example

-- @param  _menu 菜单所需要的项 菜单必须包含所需要携带的菜单的主键  
-- @return res nil 表示失败 其他表示成功 如 {"insert_id":0,"affected_rows":1,"message":"Rows matched: 1  Changed: 1  Warnings: 0","server_status":2,"warning_count":0}
--]]
function _M.update_menu( _menu )
	local db = mysql:new() 
	if not db then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"mysql new db is nil")
		return 	nil 
	end
	local param = {
		id_pk = _menu.id_pk
	}
	_menu.id_pk = nil 
	-- 执行存储过程
 	local srcSql = mysql_help.update_help("t_menu_action",_menu, param)  
	local res, err, errno, sqlstate = db:query(srcSql) 
	if not table.isnull(res) then
		ngx.log(ngx.ERR,"err code ",err," errno ",errno)
	    return nil;
	end   
 	return res
end

--[[
-- _M.delete_menu 删除菜单
-- example

-- @param  _id_pk 菜单的主键  
-- @return res nil 表示失败 其他表示成功 如 {"insert_id":0,"affected_rows":1,"server_status":2,"warning_count":0}
--]]
function _M.delete_menu( _id_pk )
	local db = mysql:new() 
	if not db then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"mysql new db is nil")
		return 	nil 
	end 
	-- 执行存储过程
 	local srcSql = mysql_help.delete_help("t_menu_action", {id_pk=_id_pk})  
	local res, err, errno, sqlstate = db:query(srcSql) 
	if not table.isnull(res) then
		ngx.log(ngx.ERR,"err code ",err," errno ",errno)
	    return nil;
	end   
 	return res
end

--[[
-- _M.get_menu_details 获得菜单详情
-- example

-- @param  _id_pk 菜单的主键  
-- @return res nil 表示失败 其他表示成功 如 {"insert_id":0,"affected_rows":1,"server_status":2,"warning_count":0}
--]]
function _M.get_menu_details( _id_pk )
	local db = mysql:new() 
	if not db then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"mysql new db is nil")
		return 	nil 
	end 
	-- 执行存储过程
 	local srcSql = mysql_help.select_help("select * from t_menu_action ", {id_pk=_id_pk})   
	local res, err, errno, sqlstate = db:query(srcSql) 
	if not table.isnull(res) then
		ngx.log(ngx.ERR,"err code ",err," errno ",errno)
	    return nil;
	end   
 	return res
end


--[[
-- _M.get_menu_tree 获得菜单树
-- example

-- @param  _id_pk 菜单的主键  
-- @param  _depth 深度 0 表示 全部

-- @return res nil 表示失败 其他表示成功 如  
--]]
function _M.get_menu_tree( _id_pk ,_depth)
	local db = mysql:new() 
	if not db then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin login mysql new db is nil")
		return 	nil 
	end
	local root_id = _id_pk and _id_pk or 0
	local depth = _depth and _depth or 1

	-- 执行存储过程
 	local srcSql = string.format("call  _TEMP_SE_PK_FK('%s','%s','%s',%d,%d); ","t_menu_action","id_pk","MENU_PRO_CRE_PF",root_id,depth);  
	-- 如果是root用户,则系统需要未来主义,该账户只能在本地以及指定的IP上登陆 
	-- local srcSql = string.format("select * from t_menu_action;");  
	 
	local res, err, errno, sqlstate = db:query(srcSql)
	db:close()
	if not table.isnull(res)  then
		ngx.log(ngx.ERR,"t_menu_action 读取失败,err code ",err)
	    return nil;
	end  
 	
 	return res
end

return _M
