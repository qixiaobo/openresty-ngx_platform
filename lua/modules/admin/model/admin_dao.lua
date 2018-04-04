--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:admin.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  admin 后台管理对象封装，用于管理员用户登录，密码修改，个人密码找回以及权限初始化等
--  
--]]

local  cjson = require "cjson"

local  mysql = require "common.db.db_mysql" 
local  mysql_help = require "common.db.mysql_help"
local  db_json_help = require "common.db.db_json_help"
local  role_dao = require "admin.model.role_dao"
local  menu_dao = require "admin.model.menu_dao"
local  authority_dao = require "admin.model.authority_dao"

local log = ngx.log

local _M = {}
  
--[[
-- menuShowPre 	递归函数,用于子节点显示,其父节点必须显示的判断,默认应该由配置时,父节点自动变成选择
-- 如果算法没有进行有效管理,可以调用该函数进行循环处理
-- example

-- @param _parenId 
-- @param _menuMap 	返回消息的主体 

--]]
local function menuShowPre(_parenId,_menuMap)
	if _parenId == 0 or _parenId == nil then 
		return 
	end
	local indexId = _parenId
	while true do
		local menu = _menuMap[""..indexId]
		if not menu then
			break
		end
		_menuMap[""..indexId].isShow = true

		if menu.parent_id_fk ~= 0 then 
			indexId = menu.parent_id_fk ;
		else
			break
		end
	end

end
local function parseMapStr(_str,mapstrmap)
	if not _str or not mapstrmap or _str=="" then return end
	-- ngx.log(ngx.ERR,"parseMapStr----------",_str)
	local strArr = cjson.decode(_str)

	for i = 1, table.getn(strArr) do
		mapstrmap[strArr[i]] = true
	end
end

--[[
-- _M.login 登陆一个管理员用户,默认显示未登陆状态,
-- 通过该对象用户可以进行登陆,登出,权限初始化,等操作
-- example

-- @param _adminName 
-- @param _password 	返回消息的主体 

--]]


function _M.login( _adminName , _password )
 -- 登陆数据库操作
	-- name = ngx.quote_sql_str(name) -- SQL 转义，将 ' 转成 \', 防SQL注入，并且转义后的变量包含了引号，所以可以直接当成条件值使用
	local mysql_cli = mysql:new() 
	if not mysql_cli then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin login mysql new mysql_cli is nil")
		return 	nil 
	end

 -- 	local srcSql = " select t_admin_account.id_pk,t_admin_account.name,t_admin_account.nick_name,t_admin_role.admin_id_fk,t_admin_role.role_id_fk ,t_admin_account.status , t_role.*,t_role_authority.action_str as action_str, t_authority.id_pk as auth_id from t_admin_account "
	-- srcSql = srcSql .. " left join t_admin_role on t_admin_role.admin_id_fk = t_admin_account.id_pk "
	-- srcSql = srcSql .. " left join t_role on t_role.id_pk = t_admin_role.role_id_fk "
	-- srcSql = srcSql .. " left join t_role_authority on t_role_authority.role_id_fk = t_role.id_pk "
	-- srcSql = srcSql .. " left join t_authority on t_authority.id_pk = t_role_authority.auth_id_fk " 
	local _sql_pre = " select t_admin_account.id_pk, t_admin_account.nick_name, t_admin_account.email, t_admin_account.sex from t_admin_account "
	local param = {
	    	admin_name = _adminName,
	    	password = _password, 
		}  
	if _adminName ~= "root" then 
	 	param.status = "enabled" 
	end	


	local sql = mysql_help.select_help(_sql_pre, param, "and")
	ngx.log(ngx.ERR, "SQL = ".. sql)
 	-- local sql = "select t_manager_account.* , t_role.*,t_authority.* from t_manager_account  left join t_role on t_role.id_pk = t_manager_account.role_id_fk left join t_role_authority on t_role_authority.role_id_fk = t_role.id_pk left join t_authority on t_authority.id_pk = t_role_authority.auth_id_fk where t_manager_account.id_pk = 1"
	-- 如果是root用户,则系统需要未来主义,该账户只能在本地以及指定的IP上登陆 
	local res, err, errno, sqlstate = mysql_cli:query(sql)  
	if not res or #res ~= 1 then
		ngx.log(ngx.ERR,"管理员账户登录失败, 请检查账号与密码是否正确")
		return nil
	end

	local srcSql = [[ select t_role.*,t_role_authority.action_str as action_str, t_authority.id_pk as auth_id from t_admin_role 
					left join t_role on t_role.id_pk = t_admin_role.role_id_fk
					left join t_role_authority on t_role_authority.role_id_fk = t_role.id_pk 
					left join t_authority on t_authority.id_pk = t_role_authority.auth_id_fk
					where t_admin_role.admin_id_fk = %d;
				]] 
	srcSql = string.format(srcSql, res[1].id_pk)
	
	local res, err, errno, sqlstate = mysql_cli:query(srcSql)  
	if not res then
		ngx.log(ngx.ERR,"查询角色与菜单错误, 请稍后再试",err," ",srcSql)
		return nil
	end 
	
	-- 权限以 id为key的map 用于初始化menu,只包含角色拥有的权限
	local authMap = {}
	-- 权限以 str为key的map 用于str页面或者页面的管理,只包含开发的权限
	local authStrMap = {}
	for i = 1,table.getn(res) do 
		authMap[''..res[i].auth_id] = res[i]
		parseMapStr(res[i].action_str,authStrMap)
	end

	local authStrMap = authStrMap; 
	local menuList = menu_dao.initMenuList()
	if not menuList then
		ngx.log(ngx.ERR,"菜单列表获取为空",err)
		return nil
	end
  
	local menuMap = {}
	for i = 1,table.getn(menuList) do 
		menuMap[''..menuList[i].id_pk] = menuList[i]
	end

  -- 初始化结果 根据权限打开是否需要显示的菜单
  	for i = 1,table.getn(menuList ) do
  		if authMap[""..menuList [i].auth_id_fk] then
  			menuList[i].isShow = true;
  			-- 初始化权限 str ,用于各个html的页面或者api 相关的权限控制,即页面访问也将通过类似的方式进行管理
  			menuShowPre(menuList[i].parent_id_fk, menuMap)
  		end
  	end
 	-- 排序形成菜单的父子关系
  	menuList = db_json_help.cjsonPFTable(menuList,"id_pk","parent_id_fk")
  	-- ngx.log(ngx.ERR,"error------  ",cjson.encode(authStrMap)) 
  	-- 生成auth 权限接口 主要用于系统的中角色效果的处理 
  
	return res, menuList,authStrMap;
end 
 
--[[
-- _M.getAdmins 获取所有管理员列表
-- example

-- @param _adminName 
-- @param _password 	返回消息的主体 

--]]
function _M.getAdmins( _self )
	-- body
	local db = mysql:new() 
	if not db then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin getAdmins mysql new db is nil")
		return 	nil 
	end

 	-- local srcSql = "select t_admin_account.* ,t_role.role_name from t_admin_account left join t_role on t_admin_account.role_id_fk = t_role.id_pk  " 
     
	 local srcSql = "select t_admin_account.*  from t_admin_account where t_admin_account.admin_name !='root';  " 
     
	 
	-- 如果是root用户,则系统需要未来主义,该账户只能在本地以及指定的IP上登陆 
	local res, err, errno, sqlstate = db:query(srcSql)
	if not res  then
		ngx.log(ngx.ERR,"t_admin_account insert false,err code ",err)
	    return nil;
	end  

	db:close()
	 
	return res
	
end

--[[
-- _M.get_admin  获得admin 对象
-- example

-- @param _id_pk 管理员主键 root 账户的修改权限不在管理员修改范围之内 


--]]
function _M.get_admin( _id_pk )
	-- body
	local db = mysql:new() 
	if not db then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"admin getAdmins mysql new db is nil")
		return 	nil 
	end

 	-- local srcSql = "select t_admin_account.* ,t_role.role_name from t_admin_account left join t_role on t_admin_account.role_id_fk = t_role.id_pk  " 
     
	 local srcSql = string.format("select t_admin_account.*  from t_admin_account where id_pk='%s' ;", _id_pk) 
     
	 
	-- 如果是root用户,则系统需要未来主义,该账户只能在本地以及指定的IP上登陆 
	local res, err, errno, sqlstate = db:query(srcSql)
	if not res  then
		ngx.log(ngx.ERR,"t_admin_account insert false,err code ",err)
	    return nil;
	end  
	db:close()
	
	return res[1]
	
end

--[[
-- _M.admin_add 添加管理员
-- example

-- @param _admin 管理员结构体 包含管理员名称,管理员邮箱,管理员手机号,管理员状态, SHA256之后的密码 
-- @param _role_id 选择的用户角色id 为空不需要添加, 不为空则添加新用户账户-角色关联表中
--]]
_M.admin_add = function ( _admin, _role_id )
	-- body
	local mysql_cli = mysql:new() 
	if not mysql_cli then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"mysql new mysql_cli is nil")
		return 	nil 
	end


 	local srcSql = mysql_help.insert_help("t_admin_account",_admin)
	
	-- 如果是root用户,则系统需要未来主义,该账户只能在本地以及指定的IP上登陆 
	local res, err, errno, sqlstate = mysql_cli:query(srcSql)
	
	if not table.isnull(res)  then
		ngx.log(ngx.ERR,"t_admin_account insert false,err code ",err)
	    return nil;
	end  
	if _role_id then
		local _admin_role = {
			admin_id_fk = res.inser_id,
			role_id_fk = _role_id,
		}
		local srcSql = mysql_help.replace_help("t_admin_role",_admin,_admin)
		local res, err, errno, sqlstate = mysql_cli:query(srcSql)
		if not table.isnull(res)  then
			ngx.log(ngx.ERR,"t_admin_role replace_help false,err code ",err)
		    return nil;
		end  
	end

	mysql_cli:close()   
	return res 

end

--[[
-- _M.admin_update 修改管理员
-- example

-- @param _admin 管理员结构体 包含管理员名称,管理员邮箱,管理员手机号,管理员状态, SHA256之后的密码 
-- @return 返回结果  如果失败则为nil 
--]]
_M.admin_update = function ( _admin )
	-- body
	local db = mysql:new() 
	if not db then 
		-- 写入错误日志
		ngx.log(ngx.ERR,"mysql new db is nil")
		return 	nil 
	end

	local param = { id_pk = _admin.id_pk }
	_admin.id_pk = nil

 	local srcSql = mysql_help.update_help("t_admin_account",_admin,param)
	
	local res, err, errno, sqlstate = db:query(srcSql)
	db:close()
	 
	if not table.isnull(res)  then
		ngx.log(ngx.ERR,"t_admin_account insert false,err code ",err)
	    return nil;
	end  
	return res
end

local uuid_help = require "common.uuid_help":new(ZS_USER_NAME_SPACE)
local redis_help = require "common.db.redis_help"
function _M.create_token( name)
	local token = uuid_help:get64()
	if not name then 
        ngx.log(ngx.ERR,"name 未设置")
        return nil
    end

	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 
    
    local key = "ADMIN_TOKEN"
    local res, err = redis_cli:hset(key, name, token)
    if not res then
        ngx.log(ngx.ERR, "REDIS failed：" .. name.. ":" .. token .. ", " .. err)
        return nil
    end
	redis_cli:expire(key, token, 86400)   
	return token
end

function _M.check_token(name, token)
	if not name or not token then 
        return false, "参数错误: [name] 或 [token] is nil"
    end

	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR, "REDIS异常: new failed");
        return false, "REDIS异常: new failed"
    end 

    local keys = "ADMIN_TOKEN"
	local res = redis_cli:hget(keys, name);
	if not res then
		return false, "TOKEN 不存在, name=" .. name
	end
    if res ~= token then
        return false, "TOKEN 异常 : " .. res
    end
	return true, "TOKEN 正确"
end

return _M