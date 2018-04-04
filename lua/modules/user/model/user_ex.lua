--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_ex.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  用户扩展信息的模型类, 包含昵称,头像 等各类信息
--  User = {
		id_pk = '1',
		user_code_fk = 'xxxxx',	-- 用户唯一编号
		nick_name = 'xxxxxx',	-- 昵称
		head_image = 'xxxxxxx', -- 用户密码使用 sha256+useruuid 转94进制的数据进行存储和比较
		sex = 'xxxxxx',			-- 性别
		signature = 'xxxxx',	-- 签名
		regional_code = 'xxxx', -- 地址编号
		adress = '',			-- 详细地址
		company_code = '',		-- 企业编号
		education = '',			-- 学历
		birthday = '',			-- 生日
		profession_code = '',	-- 学历编号
		blood_type = '',		-- 血型
		marriaged = '',			-- 婚否
-- }
--]]

local clazz = require "common.clazz.clazz"
local _M = {
	-- _properties = {}
		user_code_fk = 'xxxxx',	-- 用户唯一编号
		nick_name = 'xxxxxx',	-- 昵称
		head_image = 'xxxxxxx', -- 用户密码使用 sha256+useruuid 转94进制的数据进行存储和比较
		sex = 'xxxxxx',			-- 性别
		signature = 'xxxxx',	-- 签名
		regional_code = 'xxxx', -- 地址编号
		adress = '',			-- 详细地址  
		birthday = '',			-- 生日
		education = '',			-- 学历
		profession_code = '',	-- 职业编号
		company_code = '',		-- 企业编号
		blood_type = '',		-- 血型
		marriaged = '',			-- 婚否 
}
_M.__index = _M 
 

setmetatable(_M,clazz)  -- _M 继承于 clazz

--[[
    用来定义类似c++ 中 通过构筑函数 构造新类 类  Clazz  local clazz = Clazz()
    相似的方式通过 new 创建
]]
_M.__call = function(_self, ...)
    -- body
     -- ngx.log(ngx.ERR,'2222')
    local impl = _self:new(...)  -- new(_self, ...)  --
    return impl
end
-- 创建一个新类,使之支持 __call 元表操作即 CTest("zhang",'1.12')
local UserEx = setmetatable({},_M) -- 创建一个新类 继承于原 _M
UserEx.__index = UserEx 			-- 使 UserEx 类支持创建新类的功能

return UserEx
