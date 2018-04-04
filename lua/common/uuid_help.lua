--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:uuid_help.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  关于uuid的简单封装,主要用于各式各样的uuid唯一键值的场合,可用于其他多进制的数据转化形成唯一编码信息的输出情形
	根据系统多个版本进行升级使用
	uuid_help.lua  依赖jit-uuid , lua-resty-UUID( 扩展了64进制和94进制, 94进制作为系统唯一code存储使用,不作为用户级使用,
	用户等级使用64进制
--]]
local sha1 =  require "resty.sha1"
local sha224 =  require "resty.sha224"
local sha256 =  require "resty.sha256"
local sha384 =  require "resty.sha384"
local sha512 =  require "resty.sha512"
local str = require "resty.string"

local jit_uuid = require 'resty.jit-uuid'
local uuid = require 'resty.uuid'


--[[
_M = {
	uuid_str = "",		-- 该结构默认包含自动渲染uuid对象,用于sha1等值的新的uuid生成	
}

]]

local _M = {

}

_M.__index = _M

--[[
-- 用语uuid创建最新的新的uuid,可用于生成唯一code,该code可以转换为各类进制,
-- 常用的为64进制,94进制减少系统长度功能,当用户通过uuidstr创建,则系统不用通过uuid.seed 随机生成uuid种子
	local uuid_help = require "common.uuid_help"
	local file_uuid = "8a4072bd-03bc-4694-b2dd-55f028f16f37"
	local uuid_help_imp = uuid_help:new(file_uuid);
	uuid_help:get64();--返回当前64进制,如果没有uuid_str则系统通过随机址产生唯一id
-- ]]
function _M:new(uuid_str)
	-- body
	local uuid_impl =  setmetatable({uuid_str = uuid_str}, _M);   
 
	
	return uuid_impl;
end


--[[
-- 获得64进制的uuid的组成格式 一般用于文件命名,网页地址或其他区域 长度一般为21-22字节
-- @param: _str 数据的sha1的hash值或者普通字符串
-- @return: 返回64进制处理的编码信息 
]]
function _M:get64( _str )
	-- body 
	local newuuid 
	if self.uuid_str and _str then
		-- local newuuid = uuid.generate_v5(self.uuid_str,_str)
		newuuid = jit_uuid.generate_v5(self.uuid_str,_str)
	else
    -- local u1 = uuid()             ---> __call metamethod
    -- local u2 = uuid.generate_v4()
		newuuid = jit_uuid.generate_v4()
	end
	 
	return uuid.gen64hex(newuuid);

end

--[[
-- 获得94进制的uuid的组成格式 一般用于系统唯一性的id处理长度一般在20-21字节
-- @param: sha1_str 数据的sha1的hash值
-- @return: 返回94进制处理的编码信息 
]]

function _M:get94( _str )
	-- body
	local newuuid 
	if self.uuid_str and _str then
		-- local newuuid = uuid.generate_v5(self.uuid_str,_str)
		newuuid = jit_uuid.generate_v5(self.uuid_str,_str) 
	else
		-- jit_uuid.seed()
		newuuid = jit_uuid.generate_v4() 
	end 
	
	return uuid.gen94hex(newuuid);
end



--[[
-- 生成系统uuid信息对象,该对象格式一般为 "8a4072bd-03bc-4694-b2dd-55f028f16f37"
-- @param: 无
-- @return: 返回当前uuid编码的
]]
function _M.get()
	-- body
	-- jit_uuid.seed()
	return jit_uuid.generate_v4()
end




return _M


