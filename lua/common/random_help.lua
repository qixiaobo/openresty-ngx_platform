--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:random_help.lua
--	版本号: 0.1 
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  lua的随机数计算,该计算主要涉及给予指定比例权重的数组，返回选择随机值的对象index

--]]
local str = require "resty.string"
local uuid_help = require "common.uuid_help"
local _M = {}

_M.__index = _M

math.randomseed(os.time()) 
--[[
-- _M.random(_weightArr)
-- 返回当前指定权重下的, 随机返回的权重对象位置 
-- example
	local _weightArr = {1,1,2,6} -- 权重的大小为总大小为10,4个对象的比例分别为10%,10%,20%,60%
	local randomHelp = require "common.random_help"
	local weiIndex = randomHelp.random(_weightArr)	-- 返回值即为有效的对象值

-- @param _weightArr 当前权重数组
-- @return 返回当前权限下面的随机到的权重对象的index
]]
_M.random = function(_weightArr)
	local MAX_NUMBER = 1000000
	local thresholdMap = {} -- 阀值map
	local maxWeight = 0
	local len = table.getn(_weightArr)
	for i=1,len  do 
		maxWeight = maxWeight + _weightArr[i]
		thresholdMap[i] = maxWeight
	end

	local randomIndex = math.random(1,MAX_NUMBER)
	for i=1,len do 
		local threshold =  thresholdMap[i] / maxWeight
		if randomIndex <= threshold*MAX_NUMBER then
			return i
		end
	end

	return len
end

--[[
-- _M.random_by_len( _len )
-- 返回当前指定权重下的, 随机返回的权重对象位置 
-- example
	 

-- @param _len 验证码的有效长度
-- @return 返回验证码,string 类型
]]
_M.random_by_len = function( _len )
	if not _len then _len = 6 end
	local maxWeight = math.pow(10,_len)
	local tWeight = math.pow(10,_len-1)
	maxWeight = maxWeight - tWeight - 1
	local randomIndex = math.random(tWeight,maxWeight)
	return randomIndex
end


-- 随机字符串
local CHARS_ARRAY="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$_"
local CHARS_ARRAY_LEN = string.len(CHARS_ARRAY)

-- 或得随机字符串
-- _M.randomchar_by_len = function ( _bits  )
--     -- body
--     -- 为了防止出现唯一,系统默认追加64 进制的uuid 字符串 
--     local uuid_str64 = uuid_help:get64()
--     if not _bits then return uuid_str64 end

--     local str_len = string.len(uuid_str64) 
--     if _bits < str_len then
--     	return string.sub(uuid_str64,1,_bits)
--     end
--     local leftBits = _bits - str_len
--     for i=1,leftBits do 
--     	local rIndex = math.random(1,CHARS_ARRAY_LEN) 
--     	uuid_str64 = uuid_str64..string.sub(CHARS_ARRAY,CHARS_ARRAY_LEN,1)
--     end
--     return uuid_str64
-- end

-- 或得随机字符串
_M.randomchar_by_len = function ( _bits  )
    -- body
	-- 为了防止出现唯一,系统默认追加64 进制的uuid 字符串  
	local uuid_str64 = ""
    for i=1, _bits do
		local index = math.random(1,CHARS_ARRAY_LEN) 
		uuid_str64 = uuid_str64..string.sub(CHARS_ARRAY, index, index)
	end
	ngx.log(ngx.ERR, "================================", uuid_str64, ": ", _bits)
    return uuid_str64
end


-- 随机数字字符串
local NUMBER_ARRAY="0123456789"
local NUMBER_ARRAY_LEN = string.len(NUMBER_ARRAY)
 

-- 获得随机数字字符串
_M.randomnumber_by_len = function ( _bits  )
    -- body 
    if not _bits then _bits = 6 end
    local res = {}
    for i=1, _bits do
		local index = math.random(1,NUMBER_ARRAY_LEN) 
		res[i] = NUMBER_ARRAY[index]
	end
	return res
end



return _M