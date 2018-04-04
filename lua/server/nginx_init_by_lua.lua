--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:system_init.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  系统的初始化脚本,该脚本用作nginx的 init_by_lua_file 的引用,
--	主要包括系统扩展函数,系统配置和系统状态的相关的初始化.
--  
--]]


--[[
--	当前系统的版本号
--]]
local _VERSION = "0.01"
ngx.log(ngx.ERR, "\n\n============================================== nginx start")

--[[
--	系统扩展函数相关
--	version: 0.01
--  日期:2017-3-26
--]]
require "common.lua_ex.lua_func_ex"


--[[
--	用户自定义require引入
--	version:0.01
--  日期:2017-03-26
--]]
require "common.lua_ex.require_ex"


require "conf.pre_config"

require "common.clazz.clazz"

-- 机器最大服务器数量
MAX_SERVERS = 0x5
-- 当前机器的id
SERVER_ID = 00


--[[
--	执行系统初始化过程 ,遍历指定的文件夹,遍历所有的功能模块下的初始化文件
--	version:0.01
--  日期:2017-03-26
--]]
--	系统初始化文件的文件名称
--	系统初始化进行文件夹下的功能文件初始化,如果没有则跳过该初始化
local initFile = "system_init"

local cjson = require "cjson"


local SystemStatus = require "server.server_status"
SystemStatus.setDebug(true)
--[[

local ok, app = pcall(require, "core.app")
 
if ok then
    app:run()
else
    local rootPath = ngx.var.document_root
 
    if not (package.path:find(rootPath)) then
        package.path = package.path .. ";" .. rootPath .. "/?.lua;;"
    end
 
    if not (package.cpath:find(rootPath)) then
        package.cpath = package.cpath .. ";" .. rootPath .. "/?.so;;"
    end
 
    require("core.app"):run()
end

]]
--[[
local lfs = require "lfs"
local fileSys = require "common.lua_file_help"

-- 系统 各个模块 nginx 初始化
local _M = {}; 

local sys_str = "/lua"
-- 获得当前目录功能,
local project_dir = fileSys.getCurPath()

_M.system_init = function (_init_file,_method)
	-- body
	-- 遍历文件,类似java中的遍历过滤能力
	local system_str = project_dir..sys_str;
	local tJson = {}; 
	local index = 1;
  	for file in lfs.dir(system_str) do 
	    local p = system_str..'/'..file  
	    if file ~= "." and file ~= '..' then
	      if fileSys.isDir(p) then
	      	-- 遍历文件夹 进行文件初始化
	      	local _moduleName = p..'/'.._init_file;
	      	 
	      	if not fileSys.isDir(_moduleName..".lua") then
	      		-- 尝试引入模块，不存在则报错
	      		local _moduleFile = "system_init."..file..'.'.._init_file;
				local ret, ctrl, err = pcall(require, _moduleFile) 
				 
				if ret then
				    -- 尝试获取模块方法，不存在则报错
					local req_method = ctrl[_method] 
					if req_method then
					    req_method()
					end
				end
	      	end

	      end
	        
	    end 
	end
end
_M.system_init("nginx_init","init")
]]
--[[
function mytest(  )
	-- body
	return "mytest"
end

--]]