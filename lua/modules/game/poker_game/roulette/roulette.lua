--[[
--  作者:Steven 
--  日期:2017-05-23
--  文件名:dice.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  轮盘算法,玩法的封装
--  美式轮盘共有38个数字，包括1至36号、0号以及00号，欧式轮盘则共有37个数字，包括1至36号以及0号。
--  除红黑两色外，0及00号在轮上则是绿色的。此外，还有一种法式轮盘，只有25个数字，包括1至24号以及0号。
--  共有37个号码，包括0号，直接以现金码投注。
-- 	法式轮盘共有25个号码，包括0号（也有以其他图案代替）。

-- 	轮盘的投注区分为外围（Outside Bet）和内围（Inside Bet）,
-- 	0至36号属于内围，其他则属于外围，通常为打珠一刻前截止投注（庄荷必会声明之）阅读。
--]]

--[[
	_Roulette 的结构包含如下数据

	_Roulette = {
		curChannel = 0
		betTypeResMap = {},	--  
	} 
]]

local _Roulette = {}

_Roulette.__index = _Roulette

local _Roulette.channelNum = 37

-- 押注的类型
local ROULETTE_BET_TYPE = {
	SINGLE_NUM = 1,
	DOUBLE_NUM = 2,
	THREE_NUM = 3,
	FOUR_NUM = 4,
	SIX_NUM = 5,
	LINE_1 = 6,
	LINE_2 = 7,
	LINE_3 = 8, 
	GROUP_1 = 9,
	GROUP_2	= 10,
	GROUP_3 = 11, 
	RED = 12,
	BLACK = 13,
	DOUBLE = 14,
	SINGLE = 15,
	BIG = 16,
	SMALL = 17,  
}

-- 押注类型将对应各自的结构
--[[
	比如压1,2,3,4数字的将 其押注有效比较区为
		{CHANNEL_ID = 0, COLOR=CHANNEL_COLOR.GREEN} ,
	当用户押注为第一组,第二组,第三组的 则只需要约定1-12 ,13-24 , 25-36
	同样押单数,双数,红黑,大小则用户需要在用户自己的押注类型map添加对应的押注数据即可
]]



_Roulette.ROULETTE_BET_TYPE = ROULETTE_BET_TYPE

-- 押注倍率
local ROULETTE_BET_OBBS = {
	SINGLE_NUM = 35,
	DOUBLE_NUM = 17,
	THREE_NUM = 11,
	FOUR_NUM = 8,
	SIX_NUM = 5,
	LINE_1 = 2,
	LINE_2 = 2,
	LINE_3 = 2, 
	GROUP_1 = 2,
	GROUP_2	= 2,
	GROUP_3 = 2, 
	RED = 1,
	BLACK = 1,
	DOUBLE = 1,
	SINGLE = 1,
	BIG = 1,
	SMALL = 1, 
}
_Roulette.ROULETTE_BET_OBBS = ROULETTE_BET_OBBS

local ROULETTE_BET_OBBS_MAP = {
	"SINGLE_NUM",
	"DOUBLE_NUM",
	"THREE_NUM",
	"FOUR_NUM",
	"SIX_NUM",
	"LINE_1",
	"LINE_2",
	"LINE_3", 
	"GROUP_1",
	"GROUP_2",
	"GROUP_3", 
	"RED",
	"BLACK",
	"DOUBLE",
	"SINGLE",
	"BIG",
	"SMALL", 
	 
} 
_Roulette.ROULETTE_BET_OBBS_MAP = ROULETTE_BET_OBBS_MAP

-- 轮盘颜色map
local CHANNEL_COLOR={
	GREEN = 1,	--	绿色 0
	RED = 2,	--	红色
	BLACK = 3,	-- 	黑色
}
_Roulette.CHANNEL_COLOR = CHANNEL_COLOR

-- 轮盘轨道的定义,包含轨道ID 和轨道颜色信息
local ROULETTE_CHANNEL_ARRAY = {
	{CHANNEL_ID = 0, COLOR=CHANNEL_COLOR.GREEN} ,
	{CHANNEL_ID = 1, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 2, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 3, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 4, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 5, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 6, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 7, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 8, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 9, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 10, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 11, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 12, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 13, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 14, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 15, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 16, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 17, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 18, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 19, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 20, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 21, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 22, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 23, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 24, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 25, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 26, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 27, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 28, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 29, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 30, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 31, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 32, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 33, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 34, COLOR=CHANNEL_COLOR.RED} ,
	{CHANNEL_ID = 35, COLOR=CHANNEL_COLOR.BLACK} ,
	{CHANNEL_ID = 36, COLOR=CHANNEL_COLOR.RED} ,
} 
_Roulette.ROULETTE_CHANNEL_ARRAY = ROULETTE_CHANNEL_ARRAY


local LINE_1_ARRAY ={
	false,
	true,false,false,true,false,false,true,false,false,true,false,false,
	true,false,false,true,false,false,true,false,false,true,false,false,
	true,false,false,true,false,false,true,false,false,true,false,false,
}
_Roulette.LINE_1_ARRAY = LINE_1_ARRAY

local LINE_2_ARRAY ={
	false,
	false,true,false,false,true,false,false,true,false,false,true,false,
	false,true,false,false,true,false,false,true,false,false,true,false,
	false,true,false,false,true,false,false,true,false,false,true,false,
}
_Roulette.LINE_2_ARRAY = LINE_2_ARRAY

local LINE_3_ARRAY ={
	false,
	false,false,true,false,false,true,false,false,true,false,false,true,
	false,false,true,false,false,true,false,false,true,false,false,true,
	false,false,true,false,false,true,false,false,true,false,false,true,
}
_Roulette.LINE_3_ARRAY = LINE_3_ARRAY
 

local GROUP_1_ARRAY ={
	false,
	true,true,true,true,true,true,true,true,true,true,true,true,
	false,false,false,false,false,false,false,false,false,false,false,false,
	false,false,false,false,false,false,false,false,false,false,false,false,
}
_Roulette.GROUP_1_ARRAY = GROUP_1_ARRAY

local GROUP_2_ARRAY ={
	false,
	false,false,false,false,false,false,false,false,false,false,false,false,
	true,true,true,true,true,true,true,true,true,true,true,true,
	false,false,false,false,false,false,false,false,false,false,false,false,
}
_Roulette.GROUP_2_ARRAY = GROUP_2_ARRAY

local GROUP_3_ARRAY ={
	false,
	false,false,false,false,false,false,false,false,false,false,false,false,
	false,false,false,false,false,false,false,false,false,false,false,false,
	true,true,true,true,true,true,true,true,true,true,true,true,
}
_Roulette.GROUP_3_ARRAY = GROUP_3_ARRAY


function _Roulette:reset() 
	self.curChannel = 0
	for i=1,table.getn(ROULETTE_BET_OBBS_MAP) do
		self.betTypeResMap[ROULETTE_BET_OBBS_MAP[i]] = false
	end

end
--[[
-- 重新随机滚轮盘,返回当前点数,通过点数进行游戏动画控制
-- example
    local roulette = require "game.roulette.roulette":new()
    local result = roulette:deal() 
-- @param   
-- @return  当前点数
--]]

function _Roulette:deal() 
	math.randomseed(tostring(os.time()):reverse():sub(1, 7)) 	
  	local cur_index = math.random(1, self.channelNum)

  	local channel = ROULETTE_CHANNEL_ARRAY[cur_index]

  	-- 双单 判断
  	if channel.CHANNEL_ID ~= 0 then
  		if channel.CHANNEL_ID % 2 == 0  then
  			-- 双
  			self.betTypeResMap.DOUBLE_NUM = true
  		else
  			-- 单
  			self.betTypeResMap.SINGLE_NUM = true
  		end
  	end
  	-- 颜色 判断
  	if channel.COLOR == CHANNEL_COLOR.RED then
  		self.betTypeResMap.RED =  true
  	elseif channel.COLOR == CHANNEL_COLOR.BLACK then
  		self.betTypeResMap.BLACK =  true
  	end
  	
  	-- 判断大小
  	if channel.CHANNEL_ID >= 19 then
  		self.betTypeResMap.BIG = true
  	elseif channel.CHANNEL_ID >=1 and channel.CHANNEL_ID < 19
  		self.betTypeResMap.SMALL = true
  	end

  	-- 判断在那一组
  	if channel.CHANNEL_ID  >= 1 and channel.CHANNEL_ID <= 12 then
  		self.betTypeResMap.GROUP_1 = true
  	elseif channel.CHANNEL_ID  >= 13 and channel.CHANNEL_ID <= 24 then
  		self.betTypeResMap.GROUP_2 = true
  	elseif channel.CHANNEL_ID  >= 25 and channel.CHANNEL_ID <= 36 then
  		self.betTypeResMap.GROUP_3 = true
  	end

  	-- 判断在那条线内
  	if GROUP_1_ARRAY[channel.CHANNEL_ID] == true then
  		self.betTypeResMap.LINE_1 = true
  	elseif GROUP_2_ARRAY[channel.CHANNEL_ID] == true then
  		self.betTypeResMap.LINE_2 = true
  	elseif GROUP_3_ARRAY[channel.CHANNEL_ID] == true then
  		self.betTypeResMap.LINE_3 = true
  	end

  	return cur_index
end

--[[
-- 创建轮盘实例对象,轮盘 
-- example
    local roulette = require "game.roulette.roulette":new()
    local result = roulette:deal() 
-- @param   
-- @return  返回骰宝游戏对象
--]]
function _Roulette:new()
	local roulette. = setmetatable({}, _Roulette)
	roulette.betTypeResMap = {}
	for i=1,table.getn(ROULETTE_BET_OBBS_MAP) do
		roulette.betTypeResMap[ROULETTE_BET_OBBS_MAP[i]] = false
	end

	return roulette
end

return _Roulette