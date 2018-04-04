--[[
--  作者:Steven 
--  日期:2017-05-23
--  文件名:slot_machine.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  老虎机的算法实现,玩法封装
--   老虎机有三个玻璃框，里面有不同的图案，投币之后拉下拉杆，就会开始转，如果出现特定的图形（比如三个相同）就会吐钱出来，出现相同图型越多奖金则越高。1895年——查理·费(Charlie Fey ,Jzplay Com)发明第一台商业老虎机。它是由内部三个卷轴，一个投硬币的槽，外部一个把柄转动机器的铸铁制成。老虎机很快就成为酒吧、赌场，甚至许多零售店的主要商品。由于旧金山掏金热潮，许多人都怀着寻金梦。
	所以对这部让人可一夜致富的神奇机器，有极大的兴趣，不久机器便普遍开来。随着科技的进步，早已演化成为各种不同的机型 。

	押注在各个区域，随机到押注区域的时候返回倍率,当中奖之后可以进行一次或者多次猜大小
	当猜中之后,当前积分*2;
	当押注压到lucky,随机进行0-n(9)次,被押注过的对象,不会重复被选择,当押注到另外一个lucky
	继续添加循环次数,被押注的效果,主要包括有跳点,正反循环,交叉多闪等各种类型
	当jp出现对效果时,也有可能出现各种效果?
	
-- 	现出分=系统吃分*（1-抽水率）-系统出分 ③
	

--]]

--[[
水果机包含的包含的内容

local _SlotMachine = {
	-- betMap = {},	-- 用户押注区 存储在各个用户的对象中
	betResMap = {
		resType = DEFAULT,
		resResult = {1}, -- {2,2,2,2}

	},	-- 返回结果显示 显示当前哪些中奖哪些非中奖 
	randomNumber = 0,	-- 随机数字,用户押注产生的结果可以进行一次大小押注处理
	bigSmall = 0	,	-- 当前大小	
	
	rouldArray = {},	-- 主屏幕的图标数组,在该数据中进行遍历
	lastIndex = 0,		-- 默认的位置,每次循环从当前位置的下一个位置进行,当遇到luck则执行循环两次
						-- 但是不会影响上一次位置,绿色luck 可以再次走两次,红色走三次,累计三次的结果

	balance = 0,		-- 默认为 0,服务器重启从缓存中读取该数据,该数据作为作为重要的对比参数 当前参考线数据

	slotStatus = SLOT_STATUS.CHI_FENG,
	
}

]]

local cjson = require "cjson"
local _SlotMachine = {}

_SlotMachine.__index = _SlotMachine

-- 定义水果机的内容

-- 水果机包含以下几种内容
local BET_TYPE = {
	APPLE = 1,			-- 苹果apple
	ORANGE = 3,			-- 桔子orange
	PAPAYA = 5,			-- 木瓜 
	BELL = 7,			-- 铃铛
	WATERMELON = 9,		-- 西瓜
	STAR = 11,			-- 星星
	DOUBLE_SEVEN = 13,	-- 双7
	BAR = 15,			-- bar
}
_SlotMachine.BET_TYPE = BET_TYPE
 

_SlotMachine.ROULD_PROBABILITY_MAP = ROULD_PROBABILITY_MAP



local OFFSET_NUMBER = 1
-- 系统可能存在的奖项类型定义 结果类型,同时1-10，21-28是x3小元素的类型
local ROULD_TYPE = {
	-- 图标区域
	ROULD_APPLE = BET_TYPE.APPLE,			-- 苹果 apple
	ROULD_APPLE_L = BET_TYPE.APPLE + OFFSET_NUMBER,			-- 小苹果 apple
	ROULD_ORANGE = BET_TYPE.ORANGE,			-- 桔子 orange
	ROULD_ORANGE_L = BET_TYPE.ORANGE + OFFSET_NUMBER, 
	ROULD_PAPAYA = BET_TYPE.PAPAYA,	-- 木瓜  
	ROULD_PAPAYA_L = BET_TYPE.PAPAYA + OFFSET_NUMBER, 
	ROULD_BELL = BET_TYPE.BELL,			-- 铃铛 
	ROULD_BELL_L = BET_TYPE.BELL + OFFSET_NUMBER, 
	ROULD_WATERMELON = BET_TYPE.WATERMELON,		-- 西瓜
	ROULD_WATERMELON_L = BET_TYPE.WATERMELON + OFFSET_NUMBER, 
	ROULD_STAR = BET_TYPE.STAR,			-- 星星
	ROULD_STAR_L = BET_TYPE.STAR + OFFSET_NUMBER,  
	ROULD_DOUBLE_SEVEN = BET_TYPE.DOUBLE_SEVEN,	-- 双7 
	ROULD_DOUBLE_SEVEN_L = BET_TYPE.DOUBLE_SEVEN + OFFSET_NUMBER,  
	ROULD_BAR = BET_TYPE.BAR,  
	ROULD_BAR_L = BET_TYPE.BAR + OFFSET_NUMBER,	
	ROULD_GOOD_LUCKY_R = 17,	-- 红色lucky
	ROULD_GOOD_LUCKY_G = 18,	-- 绿色lucky
	ROULD_XIAOSANYUAN = 19, -- 小三元  葡萄  橘子 铃铛 
	ROULD_DASANYUAN = 20, -- 大三元  西瓜 双星 77 
	ROULD_FOURAPPLE = 21, -- 大四喜  苹果 
	ROULD_RANDOM_6 = 22, -- 天女散花 随机6个
	ROULD_RANDOM_8 = 23, -- 天龙八部 随机8个
	ROULD_RANDOM_9 = 24, -- 九莲宝灯 随机9个
}
_SlotMachine.ROULD_TYPE = ROULD_TYPE


-- 元素界面的数组坐标
local ELEMENT_ARRAY_MAP = {
	ROULD_APPLE = {5,11,17,23},			-- 苹果 apple
	ROULD_APPLE_L = {6},			-- 小苹果 apple
	ROULD_ORANGE = {1,13},			-- 桔子 orange
	ROULD_ORANGE_L = {12}, 
	ROULD_PAPAYA = {7,19},			-- 木瓜  
	ROULD_PAPAYA_L = {18}, 
	ROULD_BELL = {2,14},			-- 铃铛 
	ROULD_BELL_L = {24}, 
	ROULD_WATERMELON = {8},		-- 西瓜
	ROULD_WATERMELON_L = {9}, 
	ROULD_STAR = {20},			-- 星星
	ROULD_STAR_L = {21},  
	ROULD_DOUBLE_SEVEN = {16},	-- 双7 
	ROULD_DOUBLE_SEVEN_L = {15},  
	ROULD_BAR = {4},  
	ROULD_BAR_L = {3},

	ROULD_GOOD_LUCKY_R = {22},	-- 红色lucky
	ROULD_GOOD_LUCKY_G = {10},	-- 绿色lucky
	--------------------------------------------------
	-- ROULD_DASANYUAN = {1,13,7,19,2,14}			-- 小三元
	-- ROULD_XIAOSANYUAN = {8,16,20},	-- 大三元
	-- ROULD_FOURAPPLE = {5,11,17,23},
	ROULD_XIAOSANYUAN = {3,5,7},			-- 小三元
	ROULD_DASANYUAN = {9,11,13},	-- 大三元
	ROULD_FOURAPPLE = {4},
	ROULD_RANDOM_6  = {6},
	ROULD_RANDOM_8 = {8},
	ROULD_RANDOM_9 = {9},
}

_SlotMachine.ELEMENT_ARRAY_MAP = ELEMENT_ARRAY_MAP

-- 随机产生的结果,包含各种随机结果和可能性
-- goodluck的随机数组概率将从普通结果中随机结果中查询出来,
local ROULD_TYPE_MAP = {
	"ROULD_APPLE",			-- 苹果 apple
	"ROULD_APPLE_L",			-- 小苹果 apple
	"ROULD_ORANGE",			-- 桔子 orange
	"ROULD_ORANGE_L", 
	"ROULD_PAPAYA",	-- 木瓜  
	"ROULD_PAPAYA_L", 
	"ROULD_BELL",			-- 铃铛 
	"ROULD_BELL_L", 
	"ROULD_WATERMELON",		-- 西瓜
	"ROULD_WATERMELON_L", 
	"ROULD_STAR",			-- 星星
	"ROULD_STAR_L",  
	"ROULD_DOUBLE_SEVEN",	-- 双7 
	"ROULD_DOUBLE_SEVEN_L",  
	"ROULD_BAR",  
	"ROULD_BAR_L",	
	"ROULD_GOOD_LUCKY_R",	-- 红色lucky
	"ROULD_GOOD_LUCKY_G",	-- 绿色lucky
	"ROULD_XIAOSANYUAN", -- 小三元  木瓜  橘子 铃铛
	"ROULD_DASANYUAN", -- 大三元  西瓜 双星 77 
	"ROULD_FOURAPPLE", -- 大四喜  苹果 
	"ROULD_RANDOM_6", -- 天女散花 随机6个
	"ROULD_RANDOM_8", -- 天龙八部 随机8个
	"ROULD_RANDOM_9", -- 九莲宝灯 随机9个
}
_SlotMachine.ROULD_TYPE_MAP = ROULD_TYPE_MAP
  



-- 主屏幕 组合 内容 
local SCREEN_ROULD_ARRAY = {
	ROULD_TYPE.ROULD_ORANGE, 			-- 1
	ROULD_TYPE.ROULD_BELL, 		-- 2
	ROULD_TYPE.ROULD_BAR_L, 	-- 3
	ROULD_TYPE.ROULD_BAR,		-- 4
	ROULD_TYPE.ROULD_APPLE,		-- 5
	ROULD_TYPE.ROULD_APPLE_L,		-- 6
	ROULD_TYPE.ROULD_PAPAYA,		-- 7
	ROULD_TYPE.ROULD_WATERMELON,	-- 8
	ROULD_TYPE.ROULD_WATERMELON_L,	-- 9
	ROULD_TYPE.ROULD_GOOD_LUCKY_G,	-- 10
	ROULD_TYPE.ROULD_APPLE,			-- 11
	ROULD_TYPE.ROULD_ORANGE_L,		-- 12
	ROULD_TYPE.ROULD_ORANGE,		-- 13
	ROULD_TYPE.ROULD_BELL,			-- 14
	ROULD_TYPE.ROULD_DOUBLE_SEVEN_L,	-- 15
	ROULD_TYPE.ROULD_DOUBLE_SEVEN,	-- 16
	ROULD_TYPE.ROULD_APPLE,			-- 17
	ROULD_TYPE.ROULD_PAPAYA_L,		-- 18
	ROULD_TYPE.ROULD_PAPAYA,		-- 19
	ROULD_TYPE.ROULD_STAR,			-- 20
	ROULD_TYPE.ROULD_STAR_L,		-- 21
	ROULD_TYPE.ROULD_GOOD_LUCKY_R,	-- 22
	ROULD_TYPE.ROULD_APPLE,			-- 23
	ROULD_TYPE.ROULD_BELL_L,		-- 24
}

_SlotMachine.SCREEN_ROULD_ARRAY = SCREEN_ROULD_ARRAY

-- 主屏幕 组合 内容 
local SCREEN_ROULD_INDEX_ARRAY = {
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24
}
_SlotMachine.SCREEN_ROULD_INDEX_ARRAY = SCREEN_ROULD_INDEX_ARRAY

-- string key map 通过该 key 可以查询系统的
local SCREEN_ROULD_ARRAY_KMAP = {
	"ROULD_ORANGE", 			-- 1
	"ROULD_BELL", 		-- 2
	"ROULD_BAR_L", 	-- 3
	"ROULD_BAR",		-- 4
	"ROULD_APPLE",		-- 5
	"ROULD_APPLE_L",		-- 6
	"ROULD_PAPAYA",		-- 7
	"ROULD_WATERMELON",	-- 8
	"ROULD_WATERMELON_L",	-- 9
	"ROULD_GOOD_LUCKY_G",	-- 10
	"ROULD_APPLE",			-- 11
	"ROULD_ORANGE_L",		-- 12
	"ROULD_ORANGE",		-- 13
	"ROULD_BELL",			-- 14
	"ROULD_DOUBLE_SEVEN_L",	-- 15
	"ROULD_DOUBLE_SEVEN",	-- 16
	"ROULD_APPLE",			-- 17
	"ROULD_PAPAYA_L",		-- 18
	"ROULD_PAPAYA",		-- 19
	"ROULD_STAR",			-- 20
	"ROULD_STAR_L",		-- 21
	"ROULD_GOOD_LUCKY_R",	-- 22
	"ROULD_APPLE",			-- 23
	"ROULD_BELL_L",		-- 24
}
_SlotMachine.SCREEN_ROULD_ARRAY_KMAP = SCREEN_ROULD_ARRAY_KMAP
  

-- 老虎机赢的格式,根据系统结果从该表中获取结果,该结果进行后续的结果的随机获取
-- 由各种结果的随机id形成的数组,通过随机产生 -- 本地为测试序列
local ROULD_RES_RANDOM_ARRAY = {
	ROULD_TYPE.ROULD_APPLE ,			-- 苹果 apple
	ROULD_TYPE.ROULD_APPLE_L ,			-- 小苹果 apple
	ROULD_TYPE.ROULD_ORANGE ,			-- 桔子 orange
	ROULD_TYPE.ROULD_ORANGE_L , 
	ROULD_TYPE.ROULD_PAPAYA ,	-- 木瓜  
	ROULD_TYPE.ROULD_PAPAYA_L , 
	ROULD_TYPE.ROULD_BELL,			-- 铃铛 
	ROULD_TYPE.ROULD_BELL_L , 
	ROULD_TYPE.ROULD_WATERMELON ,		-- 西瓜
	ROULD_TYPE.ROULD_WATERMELON_L , 
	ROULD_TYPE.ROULD_STAR ,			-- 星星
	ROULD_TYPE.ROULD_STAR_L ,  
	ROULD_TYPE.ROULD_DOUBLE_SEVEN ,	-- 双7 
	ROULD_TYPE.ROULD_DOUBLE_SEVEN_L,  
	ROULD_TYPE.ROULD_BAR,  
	ROULD_TYPE.ROULD_BAR_L ,	
	ROULD_TYPE.ROULD_GOOD_LUCKY_R ,	-- 红色lucky
	ROULD_TYPE.ROULD_GOOD_LUCKY_G ,	-- 绿色lucky
	ROULD_TYPE.ROULD_XIAOSANYUAN , -- 大三元  西瓜 双星 77 
	ROULD_TYPE.ROULD_DASANYUAN , -- 小三元  葡萄  橘子 铃铛
	ROULD_TYPE.ROULD_FOURAPPLE , -- 大四喜  苹果 
	ROULD_TYPE.ROULD_RANDOM_6 , -- 天女散花 随机6个
	ROULD_TYPE.ROULD_RANDOM_8 , -- 天龙八部 随机8个
	ROULD_TYPE.ROULD_RANDOM_9 , -- 九莲宝灯 随机9个
}

_SlotMachine.ROULD_RES_RANDOM_ARRAY = ROULD_RES_RANDOM_ARRAY

local SLOT_ELEMENTS_SIZE_CHIFENG = {
	ROULD_APPLE = 86,			-- 苹果 apple
	ROULD_APPLE_L = 40,			-- 小苹果 apple
	ROULD_ORANGE = 50,			-- 桔子 orange
	ROULD_ORANGE_L = 42, 
	ROULD_PAPAYA = 50,	-- 木瓜  
	ROULD_PAPAYA_L = 42, 
	ROULD_BELL = 32,			-- 铃铛 
	ROULD_BELL_L = 40, 
	ROULD_WATERMELON = 25,		-- 西瓜
	ROULD_WATERMELON_L = 44, 
	ROULD_STAR = 15,			-- 星星
	ROULD_STAR_L = 44,  
	ROULD_DOUBLE_SEVEN = 11,	-- 双7 
	ROULD_DOUBLE_SEVEN_L = 43,  
	ROULD_BAR = 5,  
	ROULD_BAR_L = 1,	
	ROULD_GOOD_LUCKY_R = 15,	-- 红色lucky
	ROULD_GOOD_LUCKY_G = 5,	-- 绿色lucky
}

local SLOT_ELEMENTS_SIZE_NORMAL = {
	ROULD_APPLE = 86,			-- 苹果 apple
	ROULD_APPLE_L = 40,			-- 小苹果 apple
	ROULD_ORANGE = 50,			-- 桔子 orange
	ROULD_ORANGE_L = 42, 
	ROULD_PAPAYA = 50,	-- 木瓜  
	ROULD_PAPAYA_L = 42, 
	ROULD_BELL = 32,			-- 铃铛 
	ROULD_BELL_L = 40, 
	ROULD_WATERMELON = 25,		-- 西瓜
	ROULD_WATERMELON_L = 44, 
	ROULD_STAR = 15,			-- 星星
	ROULD_STAR_L = 44,  
	ROULD_DOUBLE_SEVEN = 11,	-- 双7 
	ROULD_DOUBLE_SEVEN_L = 43,  
	ROULD_BAR = 5,  
	ROULD_BAR_L = 1,	
	ROULD_GOOD_LUCKY_R = 15,	-- 红色lucky
	ROULD_GOOD_LUCKY_G = 5,	-- 绿色lucky
}

local SLOT_ELEMENTS_SIZE_TUFENG = {
	ROULD_APPLE = 86,			-- 苹果 apple
	ROULD_APPLE_L = 40,			-- 小苹果 apple
	ROULD_ORANGE = 50,			-- 桔子 orange
	ROULD_ORANGE_L = 42, 
	ROULD_PAPAYA = 50,	-- 木瓜  
	ROULD_PAPAYA_L = 42, 
	ROULD_BELL = 32,			-- 铃铛 
	ROULD_BELL_L = 40, 
	ROULD_WATERMELON = 25,		-- 西瓜
	ROULD_WATERMELON_L = 44, 
	ROULD_STAR = 15,			-- 星星
	ROULD_STAR_L = 44,  
	ROULD_DOUBLE_SEVEN = 11,	-- 双7 
	ROULD_DOUBLE_SEVEN_L = 43,  
	ROULD_BAR = 5,  
	ROULD_BAR_L = 1,	
	ROULD_GOOD_LUCKY_R = 15,	-- 红色lucky
	ROULD_GOOD_LUCKY_G = 5,	-- 绿色lucky
}

-- 押注大小的定义
local BIG_SMALL = {
	BIG = 1,			-- 押 大
	SMALL = 2,			-- 押 小
}
-- 当前老虎机, 的状态存储在redis系统
-- 如果不存在该信息,则根据当前系统资金池进行判断
local SLOT_STATUS = {
	CHI_FENG = 1,		-- 吃分阶段
	XU_FENG = 2,		-- 蓄分阶段
	SHA_FENG = 3,		-- 吐分阶段
}
_SlotMachine.SLOT_STATUS = SLOT_STATUS
-- 大循环 小循环
--[[
	大小循环主要根据时间, 蓄分 等参数约定当前是大循环还是小循环
	煽动程序:
	演示程序:
]]
local  CYCLE_STATUS = {
	MAJOR_CYCLE = 1, -- 大循环
	MINOR_CYCLE = 2, -- 小循环 
	INCITE_CYCLE = 3, --  煽动程序
	SHOW_CYCLE = 4,		-- 演示程序
}

_SlotMachine.CYCLE_STATUS = CYCLE_STATUS


-- 老虎机状态
_SlotMachine.SLOT_STATUS = SLOT_STATUS

local WINNING_TYPE = {
	DEFAULT = 1, -- 默认模式
	LUCKY_R = 2,	 -- 中了luck之后将会进行一次或多次循环,该循环将会产生以下结果
	LUCKY_G = 3,
	--		大三元,小四喜,

}

-- 老虎机状态
_SlotMachine.WINNING_TYPE = WINNING_TYPE


--[[
-- 	_SlotMachine:stake(bets) 
-- example 
    产生随机结果
-- @return 返回大的玩家
--]]
function _SlotMachine:stake(bets)
	-- 直接进行随机 
	local cur_index = math.random(1, table.getn(self.ROULD_RES_RANDOM_ARRAY)) 

	-- 首选选取奖项类型
	local resType = self.ROULD_RES_RANDOM_ARRAY[cur_index] 


	if bets then resType = bets end

	self.betResMap = {
					resType = resType,
					resResult = {}, -- {2,2,2,2}
				} 

	local lucks = 0
	if resType < ROULD_TYPE.ROULD_GOOD_LUCKY_R   then
		-- 普通模式
		-- 获得奖项key名称
		local keyName = ROULD_TYPE_MAP[resType]
		local elemArr = ELEMENT_ARRAY_MAP[keyName]
		 
		if table.getn(elemArr) == 1 then
			self.betResMap.resResult = {elemArr[1]} 
		else
			local index = math.random(1,table.getn(elemArr))
			self.betResMap.resResult = {elemArr[index]}  
		end 
		 
		return 
	end

	-- 中红色奖项,红色奖项进行0-3次 随机
	if resType == ROULD_TYPE.ROULD_GOOD_LUCKY_R or resType ==  ROULD_TYPE.ROULD_GOOD_LUCKY_G  then
		 -- 随机中奖 ,从rould 数组中根据随机结果进行
		 local maxRandomNum = 0
		 if resType == ROULD_TYPE.ROULD_GOOD_LUCKY_R  then 
		 	maxRandomNum = 3
		 else
		 	maxRandomNum = 5
		 end

		 local randomNum = math.random(0,maxRandomNum)
		 if randomNum == 0 then return end


		 local curlRould =  table.clone(SCREEN_ROULD_INDEX_ARRAY) 
		 -- 删除lucky 元素
		if resType == ROULD_TYPE.ROULD_GOOD_LUCKY_R  then 
		 	table.remove(curlRould,22)
		 	 -- self.betResMap.resType = ROULD_TYPE.ROULD_GOOD_LUCKY_R
		else
			table.remove(curlRould,10)
			 -- self.betResMap.resType = ROULD_TYPE.ROULD_GOOD_LUCKY_G
		end   
		 
		 for i=1,randomNum do
		 	local eleIndex = math.random(1,table.getn(curlRould))   
				table.insert(self.betResMap.resResult,curlRould[eleIndex])
				table.remove(curlRould,eleIndex)  
		  
		 end 

		 -- for i=1,randomNum do
		 -- 	local eleIndex = math.random(1,table.getn(curlRould)) 
		 -- 	ROULD_TYPE_MAP[curlRould[eleIndex]]
		 -- 	table.insert(self.betResMap.resResult,curlRould[eleIndex])
		 -- 	table.remove(curlRould,eleIndex)
		 -- end
		 return 
	end  

	-- 大奖到来 小三元  大三元  大四喜
	if resType >= ROULD_TYPE.ROULD_XIAOSANYUAN and  resType < ROULD_TYPE.ROULD_FOURAPPLE then
		self.betResMap.resType = resType 
	-- ROULD_DASANYUAN = {3,5,7}			-- 小三元
	-- ROULD_XIAOSANYUAN = {9,11,13},	-- 大三元
	-- ROULD_FOURAPPLE = {1},
		local dasamp = ELEMENT_ARRAY_MAP[ROULD_TYPE_MAP[resType]] 
 
		for i=1,table.getn(dasamp) do 
			local eleIndex = math.random(1,table.getn(ELEMENT_ARRAY_MAP[ROULD_TYPE_MAP[dasamp[i]]]))
			table.insert(self.betResMap.resResult,ELEMENT_ARRAY_MAP[ROULD_TYPE_MAP[dasamp[i]]][eleIndex]) 
		end

		return 
	elseif  resType == ROULD_TYPE.ROULD_FOURAPPLE then

		local fourApple = table.clone(ELEMENT_ARRAY_MAP.ROULD_APPLE) 
		 
		for i=1,4 do 
			 local eleIndex =  math.random(1,table.getn(fourApple))
			 table.insert(self.betResMap.resResult,fourApple[eleIndex])
			 table.remove(fourApple,eleIndex) 
		end 
		return 
	else
		-- 天女散花 九莲宝灯
		local randomNum =  ELEMENT_ARRAY_MAP[ROULD_TYPE_MAP[resType]][1]  
		local curlRould =  table.clone(SCREEN_ROULD_INDEX_ARRAY) 
		table.remove(curlRould,22)
	 	for i=1,randomNum do
	 		local eleIndex = math.random(1,table.getn(curlRould))   
			table.insert(self.betResMap.resResult,curlRould[eleIndex])
			table.remove(curlRould,eleIndex)  
		 end 
	end   
end

--[[
--  设置slot machine的随机数组表
-- 过程中需要系统一共存在三类表,吃分期,正常期,以及吐分期
-- @param _curStatus 当前状态 吃分期,正常期,以及吐分期
--]]

function _SlotMachine:initBetRadomArray(_curStatus)
	-- body
	self.ROULD_RES_RANDOM_ARRAY = {}

	local slotElementsSizeMap = nil


	if _curStatus == SLOT_STATUS.XU_FENG then
		slotElementsSizeMap = SLOT_ELEMENTS_SIZE_NORMAL
	elseif _curStatus == SLOT_STATUS.TU_FENG then
		slotElementsSizeMap = SLOT_ELEMENTS_SIZE_TUFENG
	else
		slotElementsSizeMap = SLOT_ELEMENTS_SIZE_CHIFENG
	end

	local curIndex = 1
	for k,v in pairs(slotElementsSizeMap) do
		for i = 1,v do
			self.ROULD_RES_RANDOM_ARRAY[curIndex] = ROULD_TYPE[k]
			curIndex = curIndex + 1
		end
	end
	ngx.say(curIndex)
end

-- 创建一个游戏对象 该游戏对象绑定对应的游戏空间
function _SlotMachine:new()
	local slotM = setmetatable({}, _SlotMachine)

	slotM.betResMap = {}	-- 返回结果显示 显示当前哪些中奖哪些非中奖 
	-- 默认显示区都为空
	-- for k,v in pairs(ROULD_TYPE) do
	-- 	slotM.betResMap[k] = false
	-- end 

	slotM.randomNumber = 0	-- 随机数字,用户押注产生的结果可以进行一次大小押注处理
	slotM.bigSmall = 0		-- 当前大小	
	slotM.lastIndex = 0		-- 上一次的图标位置
	slotM.slotStatus = SLOT_STATUS.CHI_FENG
	-- 初始化
	self:initBetRadomArray(slotM.slotStatus)

	return slotM
end

return _SlotMachine