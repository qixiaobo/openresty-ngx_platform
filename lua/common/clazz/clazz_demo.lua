--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:clazz.lua
--  version:1.0.0.1
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  系统基类对象,系统各个类的继承对象,该类主要定义了各个元素的方法管理,和其他通用脚本
--  lua中没有类的概念, 故系统采用lua 表, 元表等技术特征, 模拟类的概念
--  
--]]
 
-- 类构造定义的demo
local CTest = g_clazz_extend()

local cjson = require "cjson"
local cjson_encode = cjson.encode
local cjson_decode = cjson.decode



--CTest.__call = function(_self,_init_data )
--    -- body
--    local impl = _self:new( _init_data ) -- CTest:new( _init_data )
--    return impl
--end
 -- 方法1
local myTest1 = CTest({'zhang','1.10'})
 ngx.say(cjson_encode(myTest1))

-- 方法2 建议使用第二种 继承产生的对象为普通表,可以直接进行json相关的序列化
local myTest2 = CTest:new ({'zhang','1.10'})
 ngx.say(cjson_encode(myTest2)) 

-- 方法3
local myTest3 = new(CTest,{'zhang','1.10'})
 ngx.say(cjson_encode(myTest3)) 
ngx.say(myTest3[1])

-- 定义元方法__call
local tt = {
}
tt.__index = tt
tt.__call = function(_self, newtable)
    return newtable
  end
local mytable = setmetatable({10},tt)
-- 
--CTest1.__call = function(_self, newtable)
--    return newtable
--end
 
local _tM = {}
_tM.__index = _tM
_tM.__call = function(_self, newtable)
    return newtable
end 
 
local newtable = {10,20,30}

local tres = CTest(newtable)
ngx.say(tres.VERSION)
 