
--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:/lua/modules/game/lottery/ssc_lot.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  时时彩彩 彩注 对象 该对象
--  
--]]


local cjson = require "cjson"
local clazz = require "common.clazz.clazz"
 




-- 彩票对象
local _M = {
	-- 局次 标题, 该数据为对应游戏的期数
	innings_no_title = "", 

	-- 平台游戏 局编号
	innings_no = "xx", 

	-- 彩票押注数字序列 不同游戏对象不同
	bet_numbers = {},

	play_way = nil,
}

-- 继承
_M.__index = _M 
  
 -- 玩法定义
local PLAY_WAY = {
	FIVE_STAR = 0x01,
	FOUR_STAR = 0x02,
	FRONT_THREE = 0x03,
	MID_THREE = 0x04,
	END_THREE = 0x05,
	FRONT_TWO = 0x06,
	END_TWO = 0x07,
	ONE_STAR = 0x08,

	
}

_M.PLAY_WAY = PLAY_WAY

local PLAY_WAY_FUNC = {
	"five_star" ,
	"four_star" ,
	"front_three" ,
	"mid_three" ,
	"end_three" ,
	"front_two" ,
	"end_two" ,
	"one_star" ,
}
_M.PLAY_WAY_FUNC = PLAY_WAY_FUNC





--[[ 
	five_star 五星的判断
-- example 
    
-- @param  _lot_res 开奖结果
-- @param _bet_lot 玩家押注的结果
--]]
local function five_star(_lot_res,_bet_lot)
	if not _lot_res or not _bet_lot then 
		local res = ""..nil
		return nil end
	for i = 1,5 do
		if _lot_res[i] ~= _lot_res[i] then
			return false
		end
	end
	return true

end

local function four_star(_lot_res,_bet_lot)
	if not _lot_res or not _bet_lot then 
		local res = ""..nil
		return nil end
	for i = 2,5 do
		if _lot_res[i] ~= _lot_res[i] then
			return false
		end
	end
	return true
end


local function front_three(_lot_res,_bet_lot)
	if not _lot_res or not _bet_lot then 
		local res = ""..nil
		return nil end
	for i = 1,3 do
		if _lot_res[i] ~= _lot_res[i] then
			return false
		end
	end
	return true

end


local function mid_three(_lot_res,_bet_lot)
	if not _lot_res or not _bet_lot then 
		local res = ""..nil
		return nil end
	for i = 2,4 do
		if _lot_res[i] ~= _lot_res[i] then
			return false
		end
	end
	return true
end

local function end_three(_lot_res,_bet_lot)
	if not _lot_res or not _bet_lot then 
		local res = ""..nil
		return nil end
	for i = 3,5 do
		if _lot_res[i] ~= _lot_res[i] then
			return false
		end
	end
	return true
end

local function front_two(_lot_res,_bet_lot)
	if not _lot_res or not _bet_lot then 
		local res = ""..nil
		return nil end
	for i = 1,2 do
		if _lot_res[i] ~= _lot_res[i] then
			return false
		end
	end
	return true
end

local function end_two(_lot_res,_bet_lot)
	if not _lot_res or not _bet_lot then 
		local res = ""..nil
		return nil end
	for i = 4,5 do
		if _lot_res[i] ~= _lot_res[i] then
			return false
		end
	end
	return true
end

local function one_star(_lot_res,_bet_lot)
	if not _lot_res or not _bet_lot then 
		local res = ""..nil
		return nil end
	for i = 1,5 do
		if _bet_lot[i] ~= '-' then
			if _lot_res[i] ~= _lot_res[i] then
				return false
			end
		end 
	end
	return true
end



--[[ 
	is_lot 开奖操作 获得5位 随机数字字符串来匹配玩家中奖情况
	
-- example 
-- @param _lot_bet 开奖数组
			[{bet_num=[1,2,3],play_way=}]
   
--]]
function _M:new(_lot_way, _bet_numbers, _innings_no, _innings_no_title)

	local lot_imp = setmetatable({},self)

	lot_imp.innings_no = _innings_no
	lot_imp.innings_no_title = _innings_no_title
	lot_imp.play_way = _lot_way
	lot_imp.bet_numbers = _bet_numbers
 
	return lot_imp
end

--[[ 
	is_lot 开奖操作 获得5位 随机数字字符串来匹配玩家中奖情况
	
-- example 
-- @param _lot_bet 开奖数组 [,,,,]
-- @return 返回中奖结果 nil 表示未中奖 
					  true 表示中奖 返回中奖的奖项 
					  其他奖项可能会返回本身的中奖信息
   
--]]
function _M:is_lot(_lot_bet)
	 local way_index = self.play_way 
	 return PLAY_WAY_FUNC[way_index]( _lot_bet,self.bet_numbers ), self.play_way
end
 

return _M