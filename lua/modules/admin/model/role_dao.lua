--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:role.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  后台基础管理模块,合并在管理员角色下,
--  角色模块,主要涉及角色相关查询
--  
--]]

local  mysql = require "common.db.db_mysql"
local  db_help = require "common.db.mysql_help"
local  db_json_help = require "common.db.db_json_help"
local  cjson = require "cjson"

local log = ngx.log

local _M = {}


--[[
-- _M.get_roles 获取 角色 列表,由于menulist采用父子关系,故采用储存过程进行处理, 
-- 由于mysql返回数据为一层层集合,故函数将会处理一次数据结构形成父子关系
-- example

-- @param  _parentId  父id
-- @return roles table list 

--]]
function _M.get_roles(_parentId) 
	-- body
	-- 登陆数据库操作
	-- name = ngx.quote_sql_str(name) -- SQL 转义，将 ' 转成 \', 防SQL注入，并且转义后的变量包含了引号，所以可以直接当成条件值使用
	local mysql_cli = mysql:new() 
	if not mysql_cli then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin login mysql new mysql_cli is nil")
		return 	nil 
	end

	if not _parentId then _parentId = 0 end
	-- 执行存储过程
 	local srcSql = string.format("call  _TEMP_SE_PK_FK('%s','%s','%s',%d,%d); ","t_role","id_pk","ROLE_PRO_CRE_PF",_parentId,0);  
	-- 如果是root用户,则系统需要未来主义,该账户只能在本地以及指定的IP上登陆 
	-- local srcSql = string.format("select * from t_menu_action;");  
	 
	local res, err, errcode, sqlstate = mysql_cli:query(srcSql)

	mysql_cli:close()
	if not res  then
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errcode, ": ", sqlstate, ".") 
	    return nil;
	end 
  
	-- begin_time = ngx.now();
	-- 将结果进行一次数据结构调整 cjson.encode(res)
 	return res -- db_json_help.cjsonPFTable1(res,"id_pk","parent_id_fk")
end




--[[
-- _M.add_role 新增角色,包含角色名称,角色描述,角色父id,角色状态
--	系统同时提醒用户添加角色的权限以及权限的str列表,将str同时存储到系统中
-- example

-- @param  _rolePro 新加的角色信息 
-- @param  _auths 角色的权限列表 结构为json数组 [{auth_id_fk=1,},{}]

--]]

function _M.add_role(_rolePro, _auths)
	  
	-- name = ngx.quote_sql_str(name) -- SQL 转义，将 ' 转成 \', 防SQL注入，并且转义后的变量包含了引号，所以可以直接当成条件值使用
	local mysql_cli = mysql:new() 
	if not mysql_cli then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin login mysql new mysql_cli is nil")
		return 	nil 
	end

	-- 执行事务开始
 	local srcSql = mysql_help.insert_help("t_role",_rolePro)  
	-- 如果是root用户,则系统需要未来主义,该账户只能在本地以及指定的IP上登陆 
	-- local srcSql = string.format("select * from t_menu_action;");  
	
	local res, err, errcode, sqlstate = mysql_cli:query(srcSql)
 
	if not res then
		--ngx.say(err)
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
	    return nil;
	end 
	if  _auths and #_auths > 0 then 
		local new_role_id = res.insert_id 
		for i=1,#_auths do
			_auths[i].role_id_fk = new_role_id
		end

		local sql = mysql_help.insert_multi_help("t_role_authority", _auths)
		local res, err, errcode, sqlstate = mysql_cli:query(srcSql)
 		if not res then
		--ngx.say(err)
			ngx.log(ngx.ERR,"bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
	    	return nil;
		end
	end  
	-- begin_time = ngx.now();
	-- 将结果进行一次数据结构调整 cjson.encode(res)
 	return res -- db_json_help.cjsonPFTable1(res,"id_pk","parent_id_fk")

end


--[[
-- _M.update_role 修改角色名称 
-- example

-- @param _role role 对象 

--]]

function _M.update_role(_role)
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
		id_pk = _role.id_pk
	}
	_role.id_pk = nil
	local srcSql = mysql_help.update_help("t_role",_role,_param) 

	local res, err, errcode, sqlstate = mysql_cli:query(srcSql) 
	mysql_cli:close()
	if not res then 
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
    	return nil;
	end
  
 	return res  

end

--[[
-- _M.update_role_auth 修改角色的权限关联表 
-- example

-- @param _role_id 角色外键
-- @param _auths  角色权限的数组

--]]

function _M.update_role_auth(_role_id, _auths)
	-- body 
	-- 登陆数据库操作
	-- name = ngx.quote_sql_str(name) -- SQL 转义，将 ' 转成 \', 防SQL注入，并且转义后的变量包含了引号，所以可以直接当成条件值使用
	local mysql_cli = mysql:new() 
	if not mysql_cli then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin login mysql new mysql_cli is nil")
		return 	nil 
	end
 	 	
    local res, err, errcode, sqlstate = mysql_cli:query("START TRANSACTION;") 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
        return res,err
    end  

	local srcSql = string.format("delete from t_role_authority where role_id_fk = %d;", _role_id )   
	local res, err, errcode, sqlstate = mysql_cli:query(srcSql)  
	if not res then 
		mysql_cli:query("ROLLBACK;") 
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
    	return nil;
	  end

	if _auths and #_auths > 0 then
		  
		local sql = mysql_help.insert_multi_help("t_role_authority", _auths)
		local res, err, errcode, sqlstate = mysql_cli:query(srcSql)
 		if not res then
		 	mysql_cli:query("ROLLBACK;") 
			ngx.log(ngx.ERR,"bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
	    	return nil;
		end  
	end
	local res, err, errcode, sqlstate = mysql_cli:query("commit;") 
    if not res then
        mysql_cli:query("ROLLBACK;") 
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
       return res,err 
    end  
 	return res  

end

--[[
-- _M.delete_role 删除角色, 一般没有子角色的角色可以删除,如果存在子角色,则该角色不可以删除,
					正常应删除系统中的角色与权限的对应关系
-- example

-- @param _role role 对象 

--]]

function _M.delete_role(_role_id) 
	-- name = ngx.quote_sql_str(name) -- SQL 转义，将 ' 转成 \', 防SQL注入，并且转义后的变量包含了引号，所以可以直接当成条件值使用
	local mysql_cli = mysql:new() 
	if not mysql_cli then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin login mysql new mysql_cli is nil")
		return 	nil 
	end
 	local srcSql = string.format("delete from t_role where id_pk = %d or parent_id_fk == %d", _role_id, _role_id) 
	local res, err, errcode, sqlstate = mysql_cli:query(srcSql)  
	mysql_cli:close()
	if not res then 
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
    	return nil
  	end
 	return res  
end

return _M