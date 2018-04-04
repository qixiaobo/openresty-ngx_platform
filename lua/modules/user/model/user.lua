--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  用户user相关的数据库访问数据库访问功能,包括用户的相关主账户属性
--  User = {
		id_pk = '1',
		user_code = 'xxxxx',
		user_name = 'xxxxxx',
		password = 'xxxxxxx', 用户密码使用 sha256+useruuid 转94进制的数据进行存储和比较
		phone = 'xxxxxx',
		email = 'xxxxx',
		area_code = 'xxxx',
-- }
--]]

local clazz = require "common.clazz.clazz"
local _M = {
	-- _properties = {}
}
_M.__index = _M

-- 用户数据库 表主键
_M.id_pk = 0

-- 用户唯一编号 64 进制 uuid
_M.user_code = ""

-- 用户名
_M.user_name = ""

_M.password = ""

_M.phone = ""

_M.email = ""

_M.area_code = "0086"


setmetatable(_M,clazz)  -- _M 继承于 clazz

--[[
    用来定义类似c++ 中 通过构筑函数 构造新类 类  Clazz  local clazz = Clazz()
    相似的方式通过 new 创建
]]
_M.__call = function(_self, ...) 
    local impl = _self:new(...)  -- new(_self, ...)  --
    return impl
end
-- 创建一个新类,使之支持 __call 元表操作即 CTest("zhang",'1.12')
local User = setmetatable({},_M) -- 创建一个新类 继承于原 _M
User.__index = User 			-- 使 User 类支持创建新类的功能

return User
