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

--[[
    该类结构作为主继承类, 主要提供类的创建和初始化等资源
    由于语言结构问题, 系统需要处理配置属性类,  
]]
local _M = { 
     _instances_id = 0,
} 

_M.VERSION = '0.01'

-- 设置__index属性, 支持该表作为其他类 《继承》之用
_M.__index = _M
  
_M.version = function( _self )
    -- body
   return _self.VERSION
end
--[[
    类的初始化函数, 类似工厂类的创建, 前提是该类已经设置了支持 《继承》能力
    即 xxx.__index = xxx
    频繁创建的函数建议使用全局的new进行创建
]]
_M.new = function( _self, _init_data)
    if not _init_data then _init_data = {} end 
    return setmetatable(_init_data, _self)
end
  
--[[
    全局的类new 通过该new 可以进行类的初始化创建
    频繁创建的函数建议使用全局的new进行创建,
    切记 _tM_ __index 指向自己 即 _tM_
    _tM_ "继承于" clazz,可以直接通过:调用clazz_init 函数
    如  
-- @example
   local _tM = {}
    _tM.__index = _tM
    setmetatable(_tM,clazz)
    local tmImpl = new(_tM_,{name="zhang", sex="mail"}) -- 注意初始化对象需要为独立的或者新建的表
    
-- @param: _tM_ 功能父类, 该类可继承于 clazz 为了性能考虑 减少多级继承,一般两层最好,各个功能模块自己定义new 或者调用全局的 new函数
-- @return: 返回64进制处理的编码信息 
]]

local function new( _tM_, _init_data ) 
    -- body    
     if not _init_data then _init_data = {} end 
     return setmetatable(_init_data, _tM_) 
end

local function call(_self,_init_data)
   return new(_self, _init_data )
end

_M.__call = call

-- 拓展继承
local function clazz_extend(_init_table)
    local _tM = _init_table and _init_table or {}
    _tM.__index = _tM
--    _tM.__call = call 
    return setmetatable(_tM,_M)
end

_G.g_clazz_extend = clazz_extend
_G.new = new 
return _M
 
