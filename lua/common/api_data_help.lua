--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:err_redirect.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
-- 本文件主要用于初始化系统api的数据返回接口数据的初始化
-- 比如系统默认返回的数据为json格式，本格式主要用于包含返回编号
-- 解释信息，以及需要返回的数据结体
--]]
  
require "conf.error_conf"

local cjson = require "cjson"

local WS_EVENT = require "common.event".WS_EVENT

local _M = {}
local _SUCCESS_DATA = {code = ZS_ERROR_CODE.RE_SUCCESS, msg = "data success",data = {}};
local _FAILED_DATA = {code = ZS_ERROR_CODE.RE_FAILED,	msg = "data failed",data = {}};


--[[
-- _M.new(_msg, _data ) 创建一个用于api级别的返回数据结构
--  如果不存在指定文件,将结果加入返回的数据表中
-- example

-- @param _err_code 系统错误编号 参考init.error_ex.lua 文件的预定义,用户可以自定义自己的参数,起始数字为444
-- @param _data 	返回消息的主体
-- @param _msg 	描述信息

--]]
function _M.new(_err_code , _msg , _data)
	local tDes = {};
	-- if err_code == ZS_ERROR_CODE.RE_SUCCESS then
	-- 	tDes = table.clone( _SUCCESS_DATA );
	-- else
	-- 	tDes = table.clone( _FAILED_DATA );
	-- end  
	if _err_code then tDes.code = _err_code; end
	if _data then tDes.data = _data; end
	if _msg  then tDes.msg = _msg; end 
	return cjson.encode(tDes)  
end

--[[
-- _M.new_success(_data , _msg ) 创建一个用于api级别的返回成功的数据结构
--  如果不存在指定文件,将结果加入返回的数据表中
-- example
 
-- @param _data 	返回消息的主体
-- @param _msg 	描述信息

--]]
function _M.new_success(_data , _msg )
	local tDes = table.clone( _SUCCESS_DATA );
	if _data then tDes.data = _data; end
	if _msg  then tDes.msg = _msg; end 
	return cjson.encode(tDes)  
end

--[[
-- _M.new_failed(err_code,_data , _msg ) 创建一个用于api级别的返回标准错误的数据结构
--  如果不存在指定文件,将结果加入返回的数据表中
-- example
 

-- @param _msg 	描述信息
-- @param _err_code  错误编号
-- @param _data 返回消息的主体
-- @param tDes  json化的字符串结果,用户输出
--]]
function _M.new_failed(_msg, _err_code, _data)
	local tDes = table.clone( _FAILED_DATA ); 
	if _msg  then tDes.msg = _msg; end
	if _data then tDes.data = _data; end
	if _err_code then tDes.code = _err_code end 
	return cjson.encode(tDes)  
end
 
function _M.simple_result( _res )
	if not _res then 
		return _M.new_failed()
	else
		return _M.new_success()
	end
end


--[[
-- _M.new_failed(_data , _msg ) 创建一个用于api级别的返回标准错误的数据结构
--  如果不存在指定文件,将结果加入返回的数据表中
-- example
 
-- @param _data 返回消息的主体
-- @param _msg 	描述信息
-- @param tDes  json化的字符串结果,用户输出
--]]
function _M.new_media(_err_code , _msg , data_type, _data)
	local tDes = table.clone( _FAILED_DATA );
	if not data_type then tDes.data_type = WS_EVENT.IMAGE end
	if _err_code then tDes.code = _err_code end 
	if _msg  then tDes.msg = _msg; end
	if _data then tDes.data = _data; end
	return cjson.encode(tDes)  
end

function _M.system_error()
	-- body
	return _M.new(ZS_ERROR_CODE.SYSTEM_ERR,'system error ,please try after a moment!')

end
		

--[[
-- _M.get_data(_json_str) 创建一个用于api级别的返回数据结构
--  如果不存在指定文件,将结果加入返回的数据表中
-- example

-- @param _err_code 系统错误编号 参考init.error_ex.lua 文件的预定义,用户可以自定义自己的参数,起始数字为444
-- @param _data 	返回消息的主体
-- @param _msg 	描述信息

--]]
function _M.get_data(_json_str)
	local json_obj = cjson.decode(_json_str)
	return json_obj.data 
end


return _M	