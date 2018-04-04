--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:message_temp.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  验证码模版,本模块涉及多语言问题,不同语言需要提供不同的版本处理
--]]

local _M = {
	temps = {}
}

--[[
	该结构主要包括如下结构
	_M = { 
		temps = {模块名称1 = xxxxx , 模块名称2 = xxxxx}
	}

	该模块第一次缓存的时候进行一次系统初始化
--]]

_M.init = function(  )
	-- body
	-- ngx.log(ngx.ERR,"message_temp init ok!")
	-- 消息模版中读取消息体 初始化 temps{}

end

--[[
	模版信息中必须预留#000000 ,编辑模版的时候需要添加验证功能,防止验证码生成时短信错误
-- @param _tmp_name 模版名称

]]
_M.get_message_temp = function( _tmp_name )
	-- body
	-- ngx.log(ngx.ERR,"get message_temp ",_tmp_name)
	if _tmp_name then
		if _M.temps[_tmp_name] then
			return _M.temps[_tmp_name]
		end
	end
	return "【流年】验证码为 #000000, 请输入验证码完成验证,请勿泄漏短信验证码,系统不会要求用户提供密码,二级密码等各种信息,谨防诈骗。"
end
--[[
	模版信息中必须预留#000000 ,编辑模版的时候需要添加验证功能,防止验证码生成时短信错误
-- @param _tmp_name 模版名称

]]
_M.get_email_message_temp = function( _tmp_name )
	-- body
	-- ngx.log(ngx.ERR,"get message_temp ",_tmp_name)
	if _tmp_name then
		if _M.temps[_tmp_name] then
			return _M.temps[_tmp_name]
		end
	end
	return "【流年】验证码为 #000000, 请输入验证码完成验证,请勿泄漏邮箱验证码,系统不会要求用户提供密码,二级密码等各种信息,谨防诈骗。"
end

--[[
	get_phone_msg_temp
	模版信息中必须预留#000000 ,编辑模版的时候需要添加验证功能,防止验证码生成时短信错误
-- @param _tmp_name 模版名称

]]
_M.get_phone_msg_temp = function( _tmp_name )
	-- body
	-- ngx.log(ngx.ERR,"get message_temp ",_tmp_name)
	if _tmp_name then
		if _M.temps[_tmp_name] then
			return _M.temps[_tmp_name]
		end
	end
	return "【流年】验证码为 #000000, 请输入验证码完成验证,请勿泄漏短信验证码,系统不会要求用户提供密码,二级密码等各种信息,谨防诈骗。"
end


-- 系统初始化执行, 但是注意加锁进行初始化状态,防止初次多人访问造成问题
_M.init()
return _M
