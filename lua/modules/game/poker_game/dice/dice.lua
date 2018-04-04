--[[
--  作者:Steven 
--  日期:2017-05-23
--  文件名:dice.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  骰子定义
--  关于骰子的相关定义与约束
--]]

local _Dice = {
}

_Dice.__index = _Dice

--[[
	骰子的点数,骰子默认点数为1-6点
]]
local DICE_POINT = {
	SIX = 6,
	FIVE = 5,
	FOUR = 4,
	THREE = 3,
	TWO = 2,
	ONE = 1,
}

_Dice.DICE_POINT = DICE_POINT
_Dice.curPoint = DICE_POINT.ONE

--[[
-- _Dice:deal() 只骰子,随机产生 1-6 点 
-- 包括以下字段 
    -- cardSB    
]]
math.randomseed(tostring(os.time()):reverse():sub(1, 7)) 
function _Dice:deal()
   local cur_index = math.random(1, 6)
   self.curPoint = cur_index;
end

--[[
-- _Dice:new() 创建一个骰子对象出来
-- 包括以下字段
    -- curPoint 当前点数为1点
    
]]
function _Dice:new()
	-- body
	local dice = setmetatable({}, _Dice)
	dice.curPoint = DICE_POINT.ONE
	return dice
end

return _Dice