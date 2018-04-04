--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:player.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  二十一点游戏 玩家/庄家的功能封装
--  玩家的基础信息,玩家的操作,玩家的状态等,历史等
--]]

local bitHelp = require("common.bit_help")

local _MPlayer = {}
_MPlayer.__index = _MPlayer


_MPlayer.userCode = ""


_MPlayer.PLAYER_STATUS = {
	SITTING_OUT = 1,		-- 旁观
	WAITING = 2,		-- 玩家刚进场,等待状态 
	NOT_BET = 3,		-- 未押注
	BET = 4,			-- 已经押注  
	BUST = 5,			-- 胀死
	DOUBLEOPT = 6,		-- 双倍-- 某些状态下双倍只能再拿一张牌	keepStatus
	SPLIT = 7,			-- 分牌 分牌之后返回分别补一张牌,然后分别补一张牌 keepStatus
	STAND = 8, 			-- 停牌 
	SURRENDER = 9,		-- 投降 
	INSURANCE = 10,		-- 保险 keepStatus
	CARDSTYPE = 11,		-- 押注牌型,对子作为特殊形式 keepStatus
	LOSS = 13,			-- 输掉 
	HE = 14,			-- 和
	WIN = 15,			-- 胜利
	WIN_BLACKJACK = 16,		-- 胜利 天生21点 
}


local PLAYER_STATUS =  _MPlayer.PLAYER_STATUS



--[[
-- 创建一个新玩家,使用玩家的唯一编号,玩家的登录状态,信号通知同时也传递进来
-- 玩家包含以下必须的游戏属性
	-- playStatus 游戏状态
	-- cardsType 牌型
	-- cardsPoints 点数
	-- 
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param  _userCode 用户唯一标识
-- @param  _userInfo 用户登录信息,主要的信号量等信息需要传递进来
-- @return 返回新创建的玩家
--]]
function _MPlayer:new( _userCode , _userInfo)
	-- body
	local player = setmetatable({}, _MPlayer);
	player.userCode = _userCode
	player.userInfo = _userInfo 
	player.roundCode = ""		--轮次 

	-- 玩家将会存在一个保持状态,和唯一状态
	player.keepStatus = bitHelp.new(0)
	player.playStatus = PLAYER_STATUS.SITTING_OUT

	player.bets = {
		betForCardsType = 0,	-- 押注信息
		bet = 0,				-- 标准押注 标准押注包含了分牌,双倍的值,计算的时候需要根据当前分牌的结果进行动态计算

	}		
	-- 押注主要包括标准押注和牌型押注

	-- 默认初始化 1 个数组的bit状态 --分牌的时候将增加多个牌信息
	-- 如果用户分牌,则使用扩展数组结构来存粗，相关操作也将放入其中
	player.cards = {}
	player.cardsType = bitHelp:new(0)

	return player
end
