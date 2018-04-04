local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"

local user_dao = require "user.model.user_dao"

local _M = {}
_M.VERSION = '1.0'

--[[
    @brief: 
            获取用户地址信息 
    @param: 
            [_user_id:string] 用户唯一ID
    @return: 
            返回用户地址信息; false: 失败  
]]
function _M.get_user_address(_user_id)
	if not _user_id or _user_id == '' then
		return false, "参数 [_user_id] 错误."
	end

	--检查是否存在该用户
	local res, errcode, errmsg = user_dao.get_user(nil, nil, nil, _user_id)
	if not res then
		return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
	end
	if not res[1] then
		return false,  ("参数错误, 不存在id: ".._user_id.." 的用户.")
	end

	local sql = string.format("SELECT * from t_address WHERE user_id_fk='%s';", _user_id)
    return mysql_db:exec_once(sql)
end

--[[
    @brief: 
            新增用户地址信息 
    @param: 
            [_param:table] 用户地址信息参数，包含user_id
    @return: 
            true: 成功; false: 失败  
]]
function _M.add_user_address(_param)
	if not _param or type(_param) ~= 'table' then
		return false, '参数 [_param] 错误.'
	end

	if not _param.user_id or _param.user_id == '' then
		return false, "参数 [_param.user_id] 错误."
	end

	--检查是否存在该用户
	local res, errcode, errmsg = user_dao.get_user(nil, nil, nil, _param.user_id)
	if not res then
		return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
	end
	if not res[1] then
		return false,  ("参数错误, 不存在id: ".._param.user_id.." 的用户.")
	end

	-- local sql = string.format("SELECT * from t_address WHERE user_id_fk='%s';", _param.user_id)
 --    local res, errcode, errmsg = mysql_db:exec_once(sql)
 --    if not res then
 --    	return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
 --    end

 --    if #res == 3 then
 --    	return false,  '用户地址信息已达到最大数量.'
 --    end

 	--检查地址是否重复
 	local res, errcode, errmsg = _M.get_user_address(_param.user_id)
	if not res then
		return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
	end

	for i = 1, #res do
		if res[i].address == _param.address then
			return false, "地址已经存在, 请不要重复添加."
		end
	end


    local address_tbl = {}
 	address_tbl.user_id_fk = _param.user_id
 	address_tbl.accept_name = _param.accept_name
 	address_tbl.phone_number = _param.phone_number
 	address_tbl.mobile_number = _param.mobile_number
 	address_tbl.zip_code = _param.zip_code
 	address_tbl.area_no = _param.area_no
 	address_tbl.address = _param.address
 	address_tbl.is_default = _param.is_default

 	--设置默认地址
 	if address_tbl.is_default then
 		address_tbl.is_default = 1
 		local sql = string.format("SELECT * from t_address WHERE user_id_fk='%s' and is_default = 1;", _param.user_id)
	    local res, errcode, errmsg = mysql_db:exec_once(sql)
	    if not res then
	    	return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
	    end

	    if res[1] then
	    	local db = mysql_db:new_db()
	    	if not db then
	    		return false,  '系统错误, mysql err.'
	    	end
	    	--开启事务
	    	mysql_db:db_begin_transaction(db)

	    	--将其它默认地址标记更新为非默认地址
	    	local sql = "update t_address set is_default=0 where user_id_fk='".._param.user_id.."' and is_default = 1;"
	    	local res, errcode, errmsg = mysql_db:exec_query(sql, db)
		    if not res then
		    	mysql_db:db_rollback(db)
		    	mysql_db:db_set_keepalive(db)
		        return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
		    end

		    --插入默认地址
		    local sql = mysql_help.insert_help("t_address", address_tbl)
		    local res, errcode, errmsg = mysql_db:exec_query(sql, db)
		    if not res then
		    	mysql_db:db_rollback(db)
		    	mysql_db:db_set_keepalive(db)
		        return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
		    end

		    --提交
	    	res, errcode, errmsg = mysql_db:db_commit(db)
	    	if not res then 
	    		mysql_db:db_rollback(db)
		    	mysql_db:db_set_keepalive(db)
		    	return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
	    	end

	    	mysql_db:db_set_keepalive(db)
	    else
	    	--没有默认地址, 直接插入
			local sql = mysql_help.insert_help("t_address", address_tbl)
		    local res, errcode, errmsg = mysql_db:exec_once(sql)
		    if not res then
		        return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
		    end
	    end
	else
		address_tbl.is_default = 0
		--没有默认地址, 直接插入
		local sql = mysql_help.insert_help("t_address", address_tbl)
	    local res, errcode, errmsg = mysql_db:exec_once(sql)
	    if not res then
	        return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
	    end
 	end
 
    return true, "添加地址成功."
end

--[[
    @brief: 
            更改用户地址信息 
    @param: 
            [_param:table] 用户地址信息参数，包含user_id
    @return: 
            true: 成功; false: 失败  
]]
function _M.update_user_address(_param)
	if not _param or type(_param) ~= 'table' then
		return false, '参数 [_param] 错误.'
	end

	if not _param.user_id or _param.user_id == '' then
		return false, "参数 [_param.user_id] 错误."
	end

	if not _param.index or _param.index == '' then
		return false, "参数 [_param.index] 错误."
	end

	--检查是否存在该用户
	local res, errcode, errmsg = user_dao.get_user(nil, nil, nil, _param.user_id)
	if not res then
		return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
	end

	if not res[1] then
		return false,  ("参数错误, 不存在id: ".._param.user_id.." 的用户.")
	end

	--检查地址是否重复
	local res, errcode, errmsg = _M.get_user_address(_param.user_id)
	if not res then
		return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
	end

	for i = 1, #res do
		if res[i].address == _param.address then
			return false, "地址已经存在, 请不要重复添加."
		end
	end

	--判断偏移参数
	local index = tonumber(_param.index)
    if index == nil or index <= 0 then
    	return false, "参数 [_param.index] 错误. index: ".._param.index
    end
    _param.index = nil

	local sql = string.format("SELECT * from t_address WHERE user_id_fk='%s';", _param.user_id)
    local res, errcode, errmsg = mysql_db:exec_once(sql)
    if not res then
    	return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
    end

    --判断偏移index是否大于总记录数量
    if #res < index then
    	return false, ("参数 [_param.index] 错误. total: "..#res.." index: "..index)
    end

    --更新
    local address_tbl = {}
 	address_tbl.user_id_fk = _param.user_id
 	address_tbl.accept_name = _param.accept_name
 	address_tbl.phone_number = _param.phone_number
 	address_tbl.mobile_number = _param.mobile_number
 	address_tbl.zip_code = _param.zip_code
 	address_tbl.area_no = _param.area_no
 	address_tbl.address = _param.address
 	address_tbl.is_default = _param.is_default

    local condition = {}
    condition.user_id_fk = _param.user_id
    condition.id_pk = res[index].id_pk

    if address_tbl.is_default == '1' or address_tbl.is_default == 'true' 
    	or address_tbl.is_default == 1 then
    	address_tbl.is_default = 1
    	local db = mysql_db:new_db()
	    if not db then
	    	return false,  '系统错误, mysql err.'
	    end

	    --开启事务
	    mysql_db:db_begin_transaction(db)
    	
    	for i = 1, #res do
    		if res[i].is_default then
    			local tbl = {}
    			tbl.is_default = 0

    			--将其它信息的默认地址标志改为非默认
    			local condition = {}
			    condition.user_id_fk = _param.user_id
			    condition.id_pk = res[i].id_pk
    			local sql = mysql_help.update_help('t_address', tbl, condition)
		    	local res, errcode, errmsg = mysql_db:exec_query(sql, db)
			    if not res then
			    	mysql_db:db_rollback(db)
			    	mysql_db:db_set_keepalive(db)
			        return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
			    end
    		end
    	end

    	--更新记录
    	local sql = mysql_help.update_help('t_address', address_tbl, condition)
    	local res, errcode, errmsg = mysql_db:exec_query(sql, db)
	    if not res then
	    	mysql_db:db_rollback(db)
			mysql_db:db_set_keepalive(db)
	        return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
	    end

    	--提交
		res, errcode, errmsg = mysql_db:db_commit(db)
		if not res then 
		    mysql_db:db_rollback(db)
			mysql_db:db_set_keepalive(db)
			return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
		end
		mysql_db:db_set_keepalive(db)
    else
    	address_tbl.is_default = 0
    	local sql = mysql_help.update_help('t_address', address_tbl, condition)
    	local res, errcode, errmsg = mysql_db:exec_once(sql)
	    if not res then
	        return false,  '系统错误, err: '..(errmsg and errmsg or 'nil')
	    end
    end
    
    return true, "更新地址成功."
end

return _M