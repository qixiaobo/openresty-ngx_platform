--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:authority.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  后台基础管理模块,合并在管理员角色下,
--  权限相关的管理,主要涉及权限的增删改查
--  
--]]

local  mysql = require "common.db.db_mysql"
local  db_help = require "common.db.mysql_help"
local  db_json_help = require "common.db.db_json_help"
local  cjson = require "cjson"

local log = ngx.log

local _M = {}


function _M.get_authoritys(_parentId) 
	-- body
	-- 登陆数据库操作
	-- name = ngx.quote_sql_str(name) -- SQL 转义，将 ' 转成 \', 防SQL注入，并且转义后的变量包含了引号，所以可以直接当成条件值使用
	local db = mysql:new() 
	if not db then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin login mysql new db is nil")
		return 	nil 
	end
	if not _parentId then _parentId = 0 end

	-- 执行存储过程
 	local srcSql = string.format("call  _TEMP_SE_PK_FK('%s','%s','%s',%d,%d); ","t_authority","id_pk","AUTH_PRO_CRE_PF",_parentId,0);  
	-- 如果是root用户,则系统需要未来主义,该账户只能在本地以及指定的IP上登陆 
	-- local srcSql = string.format("select * from t_menu_action;");  
	-- ngx.log(ngx.ERR,srcSql)
	local res, err, errno, sqlstate = db:query(srcSql)

	db:close()
	if not table.isnull(res)  then
		ngx.log(ngx.ERR,"res is null",err," errno ",errno)
	    return nil;
	end 

	for i = 1,table.getn(res) do
		--默认设置为隐藏,通过权限激活显示的菜单按钮
		res[i].isShow = false;
	end 
	
	ngx.log(ngx.ERR,cjson.encode(res))
	-- ngx.say(ngx.now() - begin_time)
	-- begin_time = ngx.now();
	-- 将结果进行一次数据结构调整 cjson.encode(res)
	 -- return res --db_json_help.cjsonPFTable1(res,"id_pk","parent_id_fk")
	 return db_json_help.cjsonPFTable1(res,"id_pk","parent_id_fk")
end





--[[
-- _M.add_auth 新增角色,包含角色名称,角色描述,角色父id,角色状态 
-- example

-- @param  _auth 新加的权限信息
-- @param  _auths 角色的权限列表 结构为json数组 [{auth_id_fk=1,},{}]

--]]

function _M.add_auth(_auth)
	  
	-- name = ngx.quote_sql_str(name) -- SQL 转义，将 ' 转成 \', 防SQL注入，并且转义后的变量包含了引号，所以可以直接当成条件值使用
	local mysql_cli = mysql:new() 
	if not mysql_cli then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin login mysql new mysql_cli is nil")
		return 	nil 
	end

	-- 执行事务开始
 	local srcSql = mysql_help.insert_help("t_authority",_auth)  
	-- 如果是root用户,则系统需要未来主义,该账户只能在本地以及指定的IP上登陆 
	-- local srcSql = string.format("select * from t_menu_action;");  
	
	local res, err, errcode, sqlstate = mysql_cli:query(srcSql)
 
	if not res then
		--ngx.say(err)
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
	    return nil;
	end 
	 
	-- begin_time = ngx.now();
	-- 将结果进行一次数据结构调整 cjson.encode(res)
 	return res -- db_json_help.cjsonPFTable1(res,"id_pk","parent_id_fk")

end


--[[
-- _M.update_auth 修改权限 
-- example

-- @param _auth role 对象 

--]]

function _M.update_auth(_auth)
	-- body 
	-- 登陆数据库操作
	-- name = ngx.quote_sql_str(name) -- SQL 转义，将 ' 转成 \', 防SQL注入，并且转义后的变量包含了引号，所以可以直接当成条件值使用
	local mysql_cli = mysql:new() 
	if not mysql_cli then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin login mysql new mysql_cli is nil")
		return 	nil 
	end

	local _param = {
		id_pk = _auth.id_pk
	}
	_auth.id_pk = nil
	local srcSql = mysql_help.update_help("t_authority",_auth,_param) 

	local res, err, errcode, sqlstate = mysql_cli:query(srcSql) 
	mysql_cli:close()
	if not res then 
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
    	return nil;
	end
  
 	return res  

end
 

--[[
-- _M.delete_auth 删除权限,同时删除相关角色页面的权限
-- example

-- @param _auth role 对象 

--]]

function _M.delete_auth(_auth_id)
	-- body 
	-- 登陆数据库操作
	-- name = ngx.quote_sql_str(name) -- SQL 转义，将 ' 转成 \', 防SQL注入，并且转义后的变量包含了引号，所以可以直接当成条件值使用
	local mysql_cli = mysql:new() 
	if not mysql_cli then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin login mysql new mysql_cli is nil")
		return 	nil 
	end
 	local srcSql = string.format("delete from t_authority where id_pk = %d or parent_id_fk == %d", _auth_id, _auth_id) 
	local res, err, errcode, sqlstate = mysql_cli:query(srcSql)  

	if not res then 
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
    	return nil;
  	end
	mysql_cli:close()
 	return res  

end


return _M