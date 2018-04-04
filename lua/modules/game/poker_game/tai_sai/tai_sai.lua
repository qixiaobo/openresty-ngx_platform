
--[[
--  作者:Steven 
--  日期:2017-05-23
--  文件名:dice.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  骰宝游戏玩法的定义与封装
--  关于塞子的相关定义与约束

--]]


local Dice = require "game.dice.dice"


--[[
	_TaiSai 的结构包含如下数据

	_TaiSai = {
		totalPoints = 0,	-- 当前三个骰子的点数
		dices = {},			-- 骰子的数组,包含三个骰子的对象
		diceTypeResMap = {},		-- 骰子的结构对象 包含当前牌的是否为豹子,大或者小,或者其他押注的类型
		-- 三军出现的数量
		pointNum = {},
	} 
]]

local _TaiSai = {}
_TaiSai.__index = _TaiSai
--  骰宝使用3个骰子进行游戏
local _TaiSai.DICENUM = 3

--  骰宝的押注类型
--[[
一点  ace
二点  deuce
三点  trey
四点  cater
五点  cinque
六点  sice
]]
local DICE_BET_TYPE = { 
	SHAI_ACE = 1 ,		-- 1点的 豹子
	SHAI_DEUCE = 2 ,
	SHAI_TREY = 3 ,
	SHAI_CATER = 4 ,
	SHAI_CINQUE = 5 ,
	SHAI_SICE = 6 , 
	THREE_KIND = 7 ,		--	3 颗骰子都一样1 赔 24

	BIG = 8,			--  大 : 总点数 11 至 17 ( 遇围骰庄家通吃 )	1 赔 1
	SMALL = 9 ,			--	小 : 总点数为 4 至 10 ( 遇围骰庄家通吃 )1 赔 1
	DOUBLE = 10,			--  双 1:1 总点数为 5, 7, 9, 11, 13, 15, 17 点 ( 遇围骰庄家通吃 )
	SINGLE = 11,			--	单 1:1	4, 6, 8, 10, 12, 14, 16 点 ( 遇围骰庄家通吃 )
	WEI_SHAI = 12,  	--	投注指定的围骰 ( 如 1 围骰 ) ，一定开出 3 颗所投注的骰子 1 赔 150

	--下注在单一个点数 ( 三军 )
	POINT_ONE = 13 ,	-- 	出现单骰投注每颗骰子 1 至 6 中指定的点数，点数出现 1 次 1 赔 1
	POINT_TWO = 14 ,	--	出现双骰投注每颗骰子 1 至 6 中指定的点数，点数出现 2 次 1 赔 2
	POINT_THREE = 15 ,	--	出现全骰投注每颗骰子 1 至 6 中指定的点数，点数出现 3 次 1 赔 3
	POINT_FOUR = 16 ,
	POINT_FIVE = 17 ,
	POINT_SIX = 18 ,   

	TWO_PAIRE = 19,		-- 对子 ( 双骰、长牌 )投注指定的双骰 ( 如双 1 点 ) ，至少开出 2 颗所投注的骰子1 赔 8 
	PAI_JIU	= 20,		-- 牌九式 ( 骨牌、短牌 )投注 15 种 2 颗骰子可能出现的组合 ( 如 1 ， 2)1 赔 5
	--点数总和
	POINT_4 = 21,	-- 总和为 4 或 17 点 1 赔 50
	POINT_5 = 22,	-- 总和为 5 或 16 点 1 赔 18
	POINT_6 = 23,	-- 总和为 6 或 15 点 1 赔 14
	POINT_7 = 24,	-- 总和为 7 或 14 点 1 赔 12
	POINT_8 = 25,	-- 总和为 8 或 13 点 1 赔 8
	POINT_9 = 26,	-- 总和为 9 ， 10 ， 11 或 12 点 1 赔 
	POINT_10 = 27,	-- 总和为 9 ， 10 ， 11 或 12 点 1 赔 
	POINT_11 = 28,	-- 总和为 9 ， 10 ， 11 或 12 点 1 赔 
	POINT_12 = 29,	-- 总和为 9 ， 10 ， 11 或 12 点 1 赔 
	POINT_13 = 30,	-- 总和为 8 或 13 点 1 赔 8
	POINT_14 = 31,	-- 总和为 7 或 14 点 1 赔 12
	POINT_15 = 32,	-- 总和为 6 或 15 点 1 赔 14
	POINT_16 = 33,	-- 总和为 5 或 16 点 1 赔 18
	POINT_17 = 34,	-- 总和为 4 或 17 点 1 赔 50

}
-- 押注类型的key name
local DICE_BET_TYPE_MAP = { 
	"SHAI_ACE",		-- 1点的 豹子
	"SHAI_DEUCE" ,
	"SHAI_TREY" ,
	"SHAI_CATER" ,
	"SHAI_CINQUE" ,
	"SHAI_SICE" , 
	"THREE_KIND" ,		--	3 颗骰子都一样1 赔 24

	"BIG",			--  大 : 总点数 11 至 17 ( 遇围骰庄家通吃 )	1 赔 1
	"SMALL" ,			--	小 : 总点数为 4 至 10 ( 遇围骰庄家通吃 )1 赔 1
	"DOUBLE",			--  双 1:1 总点数为 5, 7, 9, 11, 13, 15, 17 点 ( 遇围骰庄家通吃 )
	"SINGLE",			--	单 1:1	4, 6, 8, 10, 12, 14, 16 点 ( 遇围骰庄家通吃 )
	"WEI_SHAI",  	--	投注指定的围骰 ( 如 1 围骰 ) ，一定开出 3 颗所投注的骰子 1 赔 150

	--下注在单一个点数 ( 三军 )
	"POINT_ONE" ,	-- 	出现单骰投注每颗骰子 1 至 6 中指定的点数，点数出现 1 次 1 赔 1
	"POINT_TWO" ,	--	出现双骰投注每颗骰子 1 至 6 中指定的点数，点数出现 2 次 1 赔 2
	"POINT_THREE" ,	--	出现全骰投注每颗骰子 1 至 6 中指定的点数，点数出现 3 次 1 赔 3
	"POINT_FOUR" ,
	"POINT_FIVE" ,
	"POINT_SIX" ,   

	"TWO_PAIRE",		-- 对子 ( 双骰、长牌 )投注指定的双骰 ( 如双 1 点 ) ，至少开出 2 颗所投注的骰子1 赔 8 
	"PAI_JIU",		-- 牌九式 ( 骨牌、短牌 )投注 15 种 2 颗骰子可能出现的组合 ( 如 1 ， 2)1 赔 5
	--点数总和
	"POINT_4",	-- 总和为 4 或 17 点 1 赔 50
	"POINT_5",	-- 总和为 5 或 16 点 1 赔 18
	"POINT_6",	-- 总和为 6 或 15 点 1 赔 14
	"POINT_7",	-- 总和为 7 或 14 点 1 赔 12
	"POINT_8",	-- 总和为 8 或 13 点 1 赔 8
	"POINT_9",	-- 总和为 9 ， 10 ， 11 或 12 点 1 赔 
	"POINT_10",	-- 总和为 9 ， 10 ， 11 或 12 点 1 赔 
	"POINT_11",	-- 总和为 9 ， 10 ， 11 或 12 点 1 赔 
	"POINT_12",	-- 总和为 9 ， 10 ， 11 或 12 点 1 赔 
	"POINT_13",	-- 总和为 8 或 13 点 1 赔 8
	"POINT_14",	-- 总和为 7 或 14 点 1 赔 12
	"POINT_15",	-- 总和为 6 或 15 点 1 赔 14
	"POINT_16",	-- 总和为 5 或 16 点 1 赔 18
	"POINT_17",	-- 总和为 4 或 17 点 1 赔 50

}

local DICE_BET_ODDS = { 
	SHAI_ACE = 180 ,		-- 投注指定的围骰 ( 如 1 围骰 ) ，一定开出 3 颗所投注的骰子 1 赔 180
	SHAI_DEUCE = 180,
	SHAI_TREY = 180 ,
	SHAI_CATER = 180 ,
	SHAI_CINQUE = 180 ,
	SHAI_SICE = 180 , 
	THREE_KIND = 24 ,		--	3 颗骰子都一样1 赔 24

	BIG = 1,			--  大 : 总点数 11 至 17 ( 遇围骰庄家通吃 )	1 赔 1
	SMALL = 1 ,			--	小 : 总点数为 4 至 10 ( 遇围骰庄家通吃 )1 赔 1
	DOUBLE = 1,			--  双 1:1 总点数为 5, 7, 9, 11, 13, 15, 17 点 ( 遇围骰庄家通吃 )
	SINGLE = 1,			--	单 1:1	4, 6, 8, 10, 12, 14, 16 点 ( 遇围骰庄家通吃 )
	WEI_SHAI = 12,  	--	投注指定的围骰 ( 如 1 围骰 ) ，一定开出 3 颗所投注的骰子 1 赔 150

	--下注在单一个点数 ( 三军 )
	POINT_ONE = 1 ,	-- 	出现单骰投注每颗骰子 1 至 6 中指定的点数，点数出现 1 次 1 赔 1
	POINT_TWO = 2 ,	--	出现双骰投注每颗骰子 1 至 6 中指定的点数，点数出现 2 次 1 赔 2
	POINT_THREE = 3 ,	--	出现全骰投注每颗骰子 1 至 6 中指定的点数，点数出现 3 次 1 赔 3
	POINT_FOUR = 16 ,
	POINT_FIVE = 17 ,
	POINT_SIX = 18 ,   

	TWO_PAIRE = 8,		-- 对子 ( 双骰、长牌 )投注指定的双骰 ( 如双 1 点 ) ，至少开出 2 颗所投注的骰子1 赔 8 
	PAI_JIU	= 5,		-- 牌九式 ( 骨牌、短牌 )投注 15 种 2 颗骰子可能出现的组合 ( 如 1 ， 2)1 赔 5
	--点数总和
	POINT_4 = 50,	-- 总和为 4 或 17 点 1 赔 50
	POINT_5 = 18,	-- 总和为 5 或 16 点 1 赔 18
	POINT_6 = 14,	-- 总和为 6 或 15 点 1 赔 14
	POINT_7 = 12,	-- 总和为 7 或 14 点 1 赔 12
	POINT_8 = 8,	-- 总和为 8 或 13 点 1 赔 8
	POINT_9 = 1,	-- 总和为 9 ， 10 ， 11 或 12 点 1 赔 
	POINT_10 = 1,	-- 总和为 9 ， 10 ， 11 或 12 点 1 赔 
	POINT_11 = 1,	-- 总和为 9 ， 10 ， 11 或 12 点 1 赔 
	POINT_12 = 1,	-- 总和为 9 ， 10 ， 11 或 12 点 1 赔 
	POINT_13 = 8,	-- 总和为 8 或 13 点 1 赔 8
	POINT_14 = 12,	-- 总和为 7 或 14 点 1 赔 12
	POINT_15 = 14,	-- 总和为 6 或 15 点 1 赔 14
	POINT_16 = 18,	-- 总和为 5 或 16 点 1 赔 18
	POINT_17 = 50,	-- 总和为 4 或 17 点 1 赔 50 
}



_TaiSai.DICE_BET_TYPE = DICE_BET_TYPE
--  骰子的组合类型定义
local DICE_TYPE = {
	SMALL = 1,			-- 	骰子的组合, 小
	BIG = 2,			--	大
	THREE_KIND = 3,		--	豹子,都是豹子的情况单独比点
}

--[[
	重置当前骰宝系统的各类记录数据
]]
function _TaiSai:reset()
	self.totalPoints = 0
	for i=1,table.getn(DICE_BET_TYPE_MAP) do
		local keyStr = DICE_BET_TYPE_MAP[i]
		diceTypeResMap[keyStr] = false
	end

end

--[[
-- 创建一副骰宝游戏,其中包含三个骰子,每局进行一次只骰子,根据骰子的样式和点数进行结果比对
-- 总点数为4至10称作小，11至17为大，围骰除外
-- example
    local taisai = require "game.tai_sai.tai_sai":new()
    local result = taisai:deal() 
-- @param  无
-- @return 当前结果数组
--]]
function _TaiSai:deal()
	-- 首先只骰子每一个骰子的结果,然后对比骰子的类型和点数等
	local totalPoints = 0
	local bzMap = {}
	local pointType = 0
	for i=1,3 do
		local dice = self.dices[i]
		dice:deal()
		if not bzMap[""..dice.curPoint] then
			bzMap[""..dice.curPoint] = 0 
			pointType = pointType + 1
		end
		bzMap[""..dice.curPoint] = bzMap[""..dice.curPoint] + 1
		totalPoints = totalPoints + dice.curPoint;
	end

	if pointType == 1 then
		-- 豹子
		self.diceTypeResMap[DICE_BET_TYPE_MAP[self.dices[1].curPoint]] = true
		self.diceTypeResMap.THREE_KIND = true
	elseif pointType == 2
		-- 对子
		self.diceTypeResMap.TWO_PAIRE = true
	end
	-- 总点数
	self.totalPoints = totalPoints 
	-- 返回当前的各种状态,有效的为true
	-- 判断当前点数 是否为大
	if self.totalPoints >= 11 and self.totalPoints =< 17 then
		self.diceTypeResMap.BIG = true
	end
	-- 判断当前点数  是否为小
	if self.totalPoints >= 4 and self.totalPoints <= 10 then
		self.diceTypeResMap.SMALL = true
	end

	-- 判断是否为双
	if self.totalPoints % 2 == 0 then
		self.diceTypeResMap.DOUBLE = true
	else
		self.diceTypeResMap.SINGLE = true
	end

	-- 判断三军
	for k,v in pairs(bzMap[""..dice.curPoint]) do
		local _point = tonumber(k)
		self.pointNum[_point] = v 								-- 一共有几军
		self.diceTypeResMap[DICE_BET_TYPE_MAP[12+_point]] = true	-- 猜中的军点
	end

	-- 猜总和点数的状态判断
	self.diceTypeResMap[DICE_BET_TYPE_MAP[17+totalPoints]] = true
 
end

--[[
-- 创建一副骰宝游戏,其中包含三个骰子,每局进行一次只骰子,根据骰子的样式和点数进行结果比对
-- 总点数为4至10称作小，11至17为大，围骰除外
-- example
    local taisai = require "game.tai_sai.tai_sai":new()
    local result = taisai:deal() 
-- @param   
-- @return  返回骰宝游戏对象
--]]
function _TaiSai:new()
	local taisai = setmetatable({}, _TaiSai)
	-- 骰子数组 创建三个🎲
	taisai.dices  = {}
	for i=1,self.DICENUM do
		taisai.dices[i] = Dice:new()
	end
	self.diceTypeResMap = {}
	for i=1,table.getn(DICE_BET_TYPE_MAP) do
		local keyStr = DICE_BET_TYPE_MAP[i]
		diceTypeResMap[keyStr] = false
	end
	self.pointNum = {}
	for i=1,6 do
		self.pointNum[i] = 0
	end 
end

return _TaiSai
