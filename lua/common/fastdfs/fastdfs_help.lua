--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:fastdfs_help.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
-- 	fastdfs 帮助类封装
--]]

local tracker = require('resty.fastdfs.tracker')
local storage = require('resty.fastdfs.storage')
local utils = require('resty.fastdfs.utils')
  
local _M = {} 
_M.__index = _M 
_M.VERSION = "0.01"

--[[
	创建 fastdfs  对象
	调用方式为:new({})
	_fastdfs = {
		host='192.168.1.201',port=22122
	}
]]
function _M:new(_fastdfs)
    local impl = setmetatable({}, self)  
	local tk = tracker:new()
	tk:set_timeout(3000)
	local ok, err = tk:connect(_fastdfs)
 	
 	if not ok then return nil end

	
	local res, err = tk:query_storage_store()
	if not res then
	    ngx.log(ngx.ERR,"query storage error:" .. err)
	    return nil
	end
 
	local st = storage:new()
	st:set_timeout(3000)
	local ok, err = st:connect(res)
	if not ok then
	    ngx.log(ngx.ERR,"connect storage error:" .. err)
	   	return nil
	end

	impl.tk = tk 
	impl.st = st 

    return impl
end


--[[
-- _M:add() 添加文件
	 {"group_name":"group1","file_name":"M00\/00\/00\/wKgByVodlA-ADPJcAAAADBLdVOE083.txt"}
-- @param _data 文件二进制数据 
-- @param _ex 文件拓展类型
-- @return 返回数据上传文件的系统编号,fastdfs不去重,注意!!!
--]]
function _M:add_file(_data,_ex)
	local res, err = self.st:upload_by_buff(_data,_ex)
	if not res then
		 ngx.log(ngx.ERR,"add_file error:" .. err)
	   	return nil 
	end 
	return res
end

function _M:append_file1(_data,_ex)
	local res, err = self.st:upload_appender_by_buff(_data,_ex)
	if not res then
		 ngx.log(ngx.ERR,"append_file error:" .. err)
	   	return nil 
	end 
	return res  
end

function _M:append_file2(_file_info,_data)  
	local res, err = self.st:append_by_buff(_file_info.group_name,_file_info.file_name,_data)
	if not res then
		 ngx.log(ngx.ERR,"append_file error:" .. err)
	   	return nil 
	end 
	return res  
end


-- build append request
  
--[[
-- _M:get_file() 获得文件
	
-- @param _fdfs_name _fastdfs 文件名称
-- @return 返回数据 文件错误则返回空
--]]
function _M:get_file(_fdfs_name)
	local res, err = self.st:download_file_to_buff1(_fdfs_name)
	if not res then
		ngx.log(ngx.ERR,"query storage error: ",_fdfs_name) 
	   	return nil  
	end
	return res

	-- local size = string.len(buff)
 --    local req, err = build_append_request(STORAGE_PROTO_CMD_APPEND_FILE, group_name, file_name, size)
 --    if not req then
 --        return nil, err
 --    end
 --    table.insert(req, buff)
 --    -- send request
 --    local ok, err = self:send_request(req)
 --    if not ok then
 --        return nil, err
 --    end
 --    return self:read_update_result("append_by_buff")


end

--[[
-- _M:query_file()  查询文件信息
	{"group_name":"group1","port":23000,"host":"192.168.1.201"}
-- @param _fdfs_name _fastdfs 文件名称
-- @return 返回数据 文件错误则返回空
--]]
function _M:query_file(_fdfs_name)
	local res, err = self.tk:query_storage_update1(_fdfs_name)
	if not res then
		ngx.log(ngx.ERR,"query storage error: ",_fdfs_name) 
	   	return nil  
	end
	return res
end


--[[
-- _M:delete_file(_fdfs_name) 删除文件
	
-- @param _fdfs_name _fastdfs 文件名称
-- @return 返回true 表示成功 nil or false 表示失败
--]]
function _M:delete_file(_fdfs_name)
	if not _fdfs_name then return nil end
	local ok, err = self.st:delete_file1(_fdfs_name)
	if not ok then
	    ngx.log(ngx.ERR,"self.st:delete_file1 ",_fdfs_name)
	else
	    return ok
	end 
end

function _M:test()
	local st = self.st
	local tk = self.tk
	local cjson = require "cjson"

	local res, err = st:upload_by_buff('abcdedfg','txt')
	if not res then
	    ngx.say("upload error:" .. err)
	    ngx.exit(200)
	end  


	local fs_name = res.group_name.."/"..res.file_name

	local fs_1 = fs_name

	ngx.say(self:get_file(fs_name))
	ngx.say(fs_1)

	-- local res = self:append_file1('','jpg')
	-- self:append_file2(res,'dddddd')
	-- self:append_file2(res,'cccccc')


	-- local fs_name = res.group_name.."/"..res.file_name
	-- ngx.say(fs_name)
	-- ngx.say('---------'..self:get_file(fs_name))	


	-- local res, err = st:upload_appender_by_buff('eeeeee','txt')
	-- if not res then
	--     ngx.say("upload error:" .. err)
	--     ngx.exit(200)
	-- end
	-- local fs_name = res.group_name.."/"..res.file_name
	-- ngx.say(self:get_file(fs_name))

	 

	local res, err = self.tk:query_storage_update1(fs_1)
	if not res then
		ngx.log(ngx.ERR,"query storage error: ",fs_1) 
	    
	end
	ngx.say(cjson.encode(res))

	local ok, err = st:append_by_buff1(fs_1,"abcdedfg\n")
	if not ok then
	    ngx.say("Fail:")
	else
	    ngx.say("OK")
	end
	ngx.say(self:get_file(fs_name))

	local res, err = tk:query_storage_update1("group1/M01/00/00/wKgByVodlHaAVkeUAAAADBLdVOE466.txt")
	if not res then
	    ngx.say("query storate error:" .. err)
	    ngx.exit(200)
	end

end


return _M