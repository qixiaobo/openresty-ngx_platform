--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:blackjack.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  二十一点游戏主逻辑框架
--  通过扑克牌集合封装类进行发牌等基础操作
--  百家乐卡牌的玩法预定义
--  定义卡牌组合的类型,卡牌的大小比较,以及赔率倍数等
--  同时修改该扑克牌的状态防止系统被攻击或者串改
--]]

local Poker = require "game.poker.Poker"
local Player = require "game.21.player"
local cjson = require "cjson"
local bitHelp = require("common.bit_help")

local CARD_ID_TYPE = Poker.CARD_ID_TYPE
local PLAYER_STATUS =  Player.PLAYER_STATUS



local _Blackjack = {}  
_Blackjack.__index =  _Blackjack
setmetatable(_Blackjack, Poker)
 
 -- very import 

_Blackjack.CARD_POINT =  table.clone(Poker.CARD_POINT);
_Blackjack.CARD_POINT.KING 	= 10;
_Blackjack.CARD_POINT.QUEEN 	= 10;
_Blackjack.CARD_POINT.JACK 	= 10;

_Blackjack.CARDS_TYPE = { 
	BLACKJACK = 5,	-- 黑jack
	BLACKJACK_SWITCH = 4,	-- 换牌21点
	BLACKJACK_ORDINARY = 3,	-- 普通21点
	ORDINARY = 2,	-- 普通牌 
	BUST = 1,	-- 爆牌 
 
	PAIRS = 17, 				-- 对子 
	THREE_OF_KIND = 18, 		-- 豹子 
	THREE_OF_KIND = 19, 		-- 4张 
	THREE_OF_KIND = 20, 		-- 5张 

}

-- 游戏状态预定义
_Blackjack.GAME_STATUS = {
	WAIT_PLAYERS = 1,	-- 等待玩家进场
	START_STATUS = 2,	-- 游戏开始,还未第一轮发牌 等待用户下注
	BET = 3	,			-- 押注结束
	FIRST_SHUFFLE = 4,	-- 第1轮手牌发送完毕 2
	SENCOND_SHUFFLE = 5	-- 第2轮手牌发送完毕 3
	THREE_SHUFFLE = 6,	-- 第3轮手牌发送完毕 4
	FOUR_SHUFFLE = 7,	-- 第4轮手牌发送完毕 5
	THEOPEN = 8 ,	-- 庄家开牌,同时根据需要进行补牌 
	SETTLEMENT = 9 ,	-- 庄家开牌,同时根据需要进行补牌 
	DEALERHIT = 10,		-- 庄家决定是否拿牌状态,超时则不拿牌,直接结算
	CARDSCOUNTING = 11, -- 结算 结算之后进入开始状态 2
}

_Blackjack.GAME_STATUS_DES_MAP = {
	"WAIT_PLAYERS",	-- 等待玩家进场
	"START_STATUS",	-- 游戏开始,还未第一轮发牌 等待用户下注
	"BET",			-- 押注结束
	"FIRST_SHUFFLE",	-- 第1轮手牌发送完毕 2
	"SENCOND_SHUFFLE",	-- 第2轮手牌发送完毕 3
	"THREE_SHUFFLE",	-- 第3轮手牌发送完毕 4
	"FOUR_SHUFFLE",		-- 第4轮手牌发送完毕 5
	"THEOPEN",			-- 庄家开牌,同时根据需要进行补牌
	"SETTLEMENT",	-- 庄家开牌,同时根据需要进行补牌 
	"DEALERHIT",		-- 庄家决定是否拿牌状态,超时则不拿牌,直接结算
	"CARDSCOUNTING", -- 结算 结算之后进入开始状态 2
}



local GAME_STATUS = _Blackjack.GAME_STATUS 
local CARDS_TYPE = _Blackjack.CARDS_TYPE 
local PLAYER_STATUS = Player.PLAYER_STATUS
local GAME_STATUS_DES_MAP = _Blackjack.GAME_STATUS_DES_MAP
--
-- [[
-- 加入游戏,为玩家创建一个局内玩家角色
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param  _userCode 用户唯一标识
-- @param  _userInfo 用户登录信息,主要的信号量等信息需要传递进来
-- @return 返回新创建的玩家
--]]
function _Blackjack:JoinGame( _userCode , _userInfo)
	-- body
	self.players[_userCode] = Player:new(_userCode , _userInfo) 
end


-- [[
-- 判断的当前点数,当前只返回当前有效点数,不需要
-- example
    -- 前提是需要new一次创建卡牌对象 该对象 
-- @param  _cards 扑克牌素组
-- @return 返回扑克牌类型以及当前点数
--]]
function _Blackjack:getCardsType(_cards)
	-- body
	local ilen = table.getn(_cards)
	-- 累加的点数结果
	local pointsTemp = 0
	-- 当前扑克牌中的ace 的数量
	local aceNum = 0
	for i=1,ilen do
		local card = _cards[i]
		if card.cardId == CARD_ID_TYPE.Ace then 
			aceNum = aceNum + 1
		end
		pointsTemp = pointsTemp + card.cardPoint
	end

	-- 然后根据当前有效点数和ace数量进行判断是否达到21点
 
	-- 首先判断是否爆牌
	if pointsTemp > 21 then return CARDS_TYPE.BUST,pointsTemp,false end

	-- 如果没有爆牌,进行判断ace的判断
	if ilen == 2 then
		if aceNum == 1 and pointsTemp == 11 then
			-- 说明该牌是黑杰克,最大
			return CARDS_TYPE.BLACK_JACK,21,false
		end
	end
	
	-- 判断是否普通21点
	if pointsTemp == 21 then return CARDS_TYPE.BLACKJACK_ORDINARY,pointsTemp end

	-- 判断是否 换牌21 点 
	-- 如果有ace 系统将进行一次11计算，返回当前可能最大 点数

	if aceNum ~= 0 then 
		local pointsTemp1 = pointsTemp + 10
		-- 换牌21点 返回
		if pointsTemp1 == 21 then return CARDS_TYPE.BLACKJACK_SWITCH,pointsTemp,true end 
		-- 否则直接返回当前有效点数,以及包含ace的标志
		return CARDS_TYPE.BLACKJACK_SWITCH,pointsTemp,true end 
	end
	-- 返回当前普通牌
	return CARDS_TYPE.ORDINARY,pointsTemp,false

end
-- [[
-- _Blackjack:getCardsTypeEx(_cards) 获得卡牌的扩展牌型
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param  _userCode 用户唯一标识
-- @param  _userInfo 用户登录信息,主要的信号量等信息需要传递进来
-- @return 返回新创建的玩家
--]]
function _Blackjack:getCardsTypeEx(_cards)
	-- body
	local ilen = table.getn(_cards)
	-- 累加的点数结果
	local pointsTemp = 0
	-- 当前扑克牌中的ace 的数量
	local cardIdMap ={}
	for i=1,ilen do
		local card = _cards[i]
		if not cardIdMap.[""..card.cardId] then cardIdMap.[""..card.cardId] = 0 end 
		cardIdMap.[""..card.cardId] = cardIdMap.[""..card.cardId]  +  1 
	end 
 	
 	local iSize = 0
 	for k,_ in pairs(cardIdMap) do 
 		iSize = iSize + 1
 	end
 	
 	if iSize == 1 then 
 		return PAIRS + ilen - 2
 	end
 	return nil
end
--[[
---1  -----*********************************
-- 押注时间内进行一次结尾操作,如果玩家在等待状态,没有下注,则自动下注
-- 
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param _players 玩家数组,按照顺时针存放,最后一位为庄家
-- @return  
--]]
function _Blackjack:bet( _players )

	if self.gameType ~= GAME_STATUS.START_STATUS then
		return 
	end

	for _,v in pairs(_players) do
		local player = v
		if player.playStatus == PLAYER_STATUS.WAITING or 
			player.playStatus == PLAYER_STATUS.NOT_BET then
			------------------- 最下下注的额度
			player.bet = 10
			-- 支付成功,修改状态
			player.playStatus = PLAYER_STATUS.BET
		end
	end

	self.gameType == GAME_STATUS.BET

end

--[[
---1  -----*********************************
-- _Blackjack:deal1( _players )  发牌,要牌：当庄家向所有闲家按顺时针方向派发2张牌后，庄家就以顺时 针方向逐位闲家询问是否要牌。
-- 当一位闲家决定不要牌后，庄 家才向下一位闲家询问是否要牌。
-- 停牌：不再要牌。加倍：当庄家询问闲家是否要牌时，闲家可进行加倍操作， 闲家加倍后，庄家向其派发一张明牌，此时闲家不能再进行要 牌、停牌、分牌等其他操作。
-- 分牌：A只能分一次牌。爆牌：若果闲家要牌后，其手上拥有的牌的总点数超过21点，俗称爆牌，该闲家的注码会归庄家。
-- 反之若其手上拥有的牌的总点数不超过21 点，该闲家可决定是否继续要牌。如果庄家爆牌的话，便向原来没 有爆牌的闲家，赔出该闲家所投住的同等的注。
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param _players 玩家数组,按照顺时针存放,最后一位为庄家
-- @return  
--]]
function _Blackjack:deal1( _players )
	-- body
	-- 首先判断的当前牌局状态,错误的状态执行直接返回 
	if self.gameType ~= GAME_STATUS.BET then
		ngx.log(ngx.ERR,"room code: ",self.roomCode,"cur game status is error , ",GAME_STATUS_DES_MAP[self.gameType])
		return 
	end

	-- 第一步发四张牌，1,3 闲家, 2,4庄家
	local cardsType 
	for _,v in pairs(_players) do
		-- 只有押注状态的用户才可以发牌
		local player = v
		if player.playStatus == PLAYER_STATUS.BET then
			player.handCards={} 
			local cardsTemp = { self:getCard() ,self:getCard() }
			player.handCards[1] = { }
			player.handCards[1].cards = cardsTemp
			player.handCards[1].cardsType, player.cardsPoints[1]= self:getCardsType(cardsTemp)  

			-- 根据当前牌型状态设置 
			-- 设置玩家当前的状态
			self.playStatus:setBit(player.handCards[1].cardsType)

			-- 可能为对子,默认只有对子作为
			local cardsTypeEx = self:getCardsTypeEx(player.handCards)   
			if cardsTypeEx then
				self.playStatus:setBit(cardsTypeEx)
				-- 直接进行结算 
				---------------------------------
			end
		end
	end  

	-- 庄家发牌
	self.dealer.handCards = self:getMutiCards(2)
	-- 庄家名牌为ace 则可以买保险
	if self.dealer.handCards[2].cardId == CARD_ID_TYPE.ACE then
		self.enInsurance = true;
	end

	-- 当前牌局状态修改,当前为第一轮发牌结束
 
	-- 判断一下是否存在黑杰克
	for _,v in pairs(_players) do
		-- 只有押注了的用户才可以进行后续处理
		local player = v
		if player.playStatus == PLAYER_STATUS.BET then 
			if player.handCards[1].cardsType == CARDS_TYPE.BLACKJACK then
				-- 玩家直接胜利
				player.playStatus == PLAYER_STATUS.WIN_BLACKJACK  
			end 

		end
	end  

	-- 第一轮发牌结束 设置为第一轮发牌状态
	self.gameType == GAME_STATUS.FIRST_SHUFFLE
end


--[[
---1  -----*********************************
-- _Blackjack:dealN( _players )  发放多轮的牌局,根据上一次发牌的状态进行,不得超过4轮,
-- 当一位闲家决定不要牌后，庄 家才向下一位闲家询问是否要牌。超时为决定,则自动停牌 
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param _players 玩家数组,按照顺时针存放,最后一位为庄家
-- @return  
--]]
-- function _Blackjack:dealN( _players )
-- 	if self.gameStatus == GAME_STATUS.FOUR_SHUFFLE then
-- 		ngx.log(ngx.ERR,"room code: ",self.roomCode,"cur game status is error  ,",GAME_STATUS_DES_MAP[self.gameType])
-- 		return 
-- 	end
-- 	local betPlayers = 0
-- 	if self.gameStatus >= GAME_STATUS.FIRST_SHUFFLE then
-- 		for _,v in pairs(_players) do 
-- 			local player = v
-- 			-- 所有的停牌,胀死,双倍,分牌的用户不可以进行发牌
-- 			if player.playStatus == GAME_STATUS.BET then 
-- 				-- 如果 累加正常可以要牌的用户,如果没有用户了,则直接准备庄家开牌了
-- 				betPlayers = betPlayers + 1

-- 			end
-- 		end
-- 	end

-- 	if betPlayers == 0  then
-- 		self.gameStatus = GAME_STATUS.THEOPEN -- 设置准备开牌
-- 	end

-- end
--[[
---2 -----*********************************
--  _Blackjack:hit( _player ) 该函数根据用户自行进行要牌进行调用,当玩家还要要牌,则发一张牌放入玩家手牌
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param _player 玩家数组,按照顺时针存放
-- @return  
--]]
function _Blackjack:hit( _player ,_handIndex)
	-- body 
	if  self.gameStatus < GAME_STATUS.FIRST_SHUFFLE 
		or self.gameStatus > GAME_STATUS.FOUR_SHUFFLE then
		ngx.log(ngx.ERR,"room code: ",self.roomCode,"cur game status is error  ,",GAME_STATUS_DES_MAP[self.gameType])
		return 
	end

	if _player.playStatus ~= PLAYER_STATUS.BET then
		return
	end

	-- 向指定手牌发数据
	local len = table.getn(_player.handCards[_handIndex].cards)
	_player.handCards[_handIndex].cards[len+1] = self:getCard()
	_player.handCards[_handIndex].cardsType ,_player.handCards[_handIndex].cardsPoints= self:getCardsType(_player.handCards[_handIndex].cards)
	
	-- 玩家没有分牌的情况
	if not _player.keepStatus:getBit(PLAYER_STATUS.SPLIT) then  
		if _player.handCards[1].cardsType == CARDS_TYPE.BUST then 
			-- 如果当前爆牌,直接设置用户状态为失败状态,后续无需进行其他操作
			_player.playStatus = PLAYER_STATUS.BUST
		elseif _player.cardsType == CARDS_TYPE.BLACKJACK_SWITCH  or
		_player.cardsType == CARDS_TYPE.BLACKJACK_ORDINARY then
		-- 必须停牌了
 		_player.playStatus =  PLAYER_STATUS.STAND
 		end
 	else -- 玩家有分牌的情况
 		-- 如果玩家分牌 除非所有的牌都爆掉,才会将用户设置为失败状态
 		local bustSize = 0
 		local len = table.getn(_player.handCards)
  		for i=1,len do 
  			local cards = _player.handCards[i]
  			if cards.cardsType == CARDS_TYPE.BUST then
  				bustSize = bustSize + 1
  			end 
  		end
  		if bustSize == len then
  			_player.playStatus = PLAYER_STATUS.BUST
  		end

	end
	 
end

--[[
---2 -----*********************************
--  _Blackjack:stand( _player ) 用户停牌操作
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param _player 玩家数组,按照顺时针存放
-- @return  
--]]
function _Blackjack:stand( _player )
	-- body
	-- 停牌,不需要牌
	_player.playStatus = PLAYER_STATUS.STAND
end


--[[
---2 -----*********************************
-- _Blackjack:doubleOpt( _player )用户加倍操作
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param _player 玩家数组,按照顺时针存放
-- @return  
--]]
function _Blackjack:doubleOpt( _player )
	-- body
	-- 第一步发四张牌，1,3 闲家, 2,4庄家
	-- 将用户的押注翻倍操作
	_player.bets = _player.bets * 2 
	-- 同时要一张牌
	self:hit(_player)
	-- 用户状态添加一个doubleopt的标识,再次发牌的用户可以判断用户状态,
	-- 应为如果双倍爆牌的时候,用户标志就变成了爆牌了
	_player.keepStatus:setBit(PLAYER_STATUS.DOUBLEOPT)
end

--[[
---2 -----*********************************
--  _Blackjack:split( _player )用户分牌操作,分牌的操作也只能在第一次发牌之后进行,
-- 第一次发牌之后,系统等待一个开启一个定时器,用户在该时间段进行分牌,加倍,等各类操作
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param _player 玩家数组,按照顺时针存放
-- @param _player _handIndex 指定的手牌id
-- @return  
--]]
function _Blackjack:split( _player,_handIndex )

	-- 首先判断的当前牌局状态,错误的状态执行直接返回 
	if self.gameType ~= GAME_STATUS.BET then
		ngx.log(ngx.ERR,"room code: ",self.roomCode,"cur game status is error , ",GAME_STATUS_DES_MAP[self.gameType])
		return 
	end

	-- body
	if _player.playStatus == PLAYER_STATUS.BET then
		-- 如果当前是对子,才可以进行分牌
		if _player.keepStatus:getBit(PLAYER_STATUS.PAIRS) and _player.handCards[_handIndex] then
			-- 对牌 进行分牌
			if _player.handCards[_handIndex].cardsType == CARDS_TYPE.PAIRE and table.getn(_player.handCards[_handIndex].cards) == 2 then
				local handCardsLen = table.getn(_player.handCards)
				handCardsLen = handCardsLen + 1
				_player.handCards[handCardsLen] = {}
				_player.handCards[handCardsLen].cards = {}
				_player.handCards[handCardsLen].cards[1] = _player.handCards[_handIndex].cards[2] 
				_player.handCards[handCardsLen].cards[2] = self:getCard()

				_player.handCards[_handIndex].cards[2]  = self:getCard() 
				-- 计算一次牌型
				_player.handCards[_handIndex].cardsType, _player.cardsPoints[_handIndex] = self:getCardsType(_player.handCards[_handIndex].cards)  
				_player.handCards[handCardsLen].cardsType, _player.cardsPoints[handCardsLen] = self:getCardsType(_player.handCards[handCardsLen].cards)  
 			--------------------------分牌成功 需要添加一次基础押注.(加倍)


			end
		end
	end
	
end
 
--[[
---2 -----*********************************
-- _Blackjack:surrender( _player ) 用户投降操作,失去一半赌注
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param _player 玩家数组, 
-- @return  
--]]
function _Blackjack:surrender( _player )
	-- body
	 _player.playStatus = PLAYER_STATUS.SURRENDER
	 -- 输掉一半的押注
	--------------------------------------------------------


end

--[[
---2 -----*********************************
-- _Blackjack:surrender( _player ) 购买保险
如果玩家选择保险：
　　庄家是黑杰克时，庄家只蠃得保险金。
　　庄家不是黑杰克，庄家首先收走保险金，然后进行要牌、比较的程序，与前述相同。
　　如果玩家拿到21点，仍能拿到全部的酬金。
.如果玩家不选择保险：
　　庄家是黑杰克时，收走玩家赌金。
　　庄家不是黑杰克,仍然进行要牌、比较等程序，与前述相同。
　　
	对子：闲家可以选择在自己或其他闲家上下注押对子，如果所压的闲家获得对子（即两张相同种类的牌），则下注闲家胜，庄家赔11倍的筹码。
　　分牌：若玩家获得对子，则可以选择分牌，将这两张牌分成两手牌，由这个玩家一人操作，每手牌的赌注与开始的赌注相同。分牌后不能“加倍”，拿到BlackJack牌型也只算普通的21点。
　　

牌型比较
　　所有闲家都与庄家比较。
　　黑杰克为特殊牌型，比其他所有牌型都大。除黑杰克，其他牌型都以点数比较大小。
　　庄家和闲家点数相同，或都拿到黑杰克，则为平局。
　　庄家和闲家都爆牌，系统判断庄家赢。
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param _player 玩家数组, 
-- @return  
--]]
function _Blackjack:enInsurance( _player )
	-- body
	if not self.enInsurance  then
		ngx.log(ngx.ERR,"room code: ",self.roomCode,"enInsurance is false !")
		return 
	end
	 -- 购买保险
	 -- 输掉一半的押注
	--------------------------------------------------------
	_player.keepStatus:setBit(PLAYER_STATUS.INSURANCE)

end


--[[
	判断庄家当前是否发牌
]]
function   _Blackjack:dealerTheOpenPre(  )

	local len = table.getn(dealer.handCards)
	if len  == 5 then
		return false
	end
	-- body
	local hsACE
	dealer.cardsType ,dealer.cardsPoints,hsACE = self:getCardsType(player.handCards)
	-- 如果庄家牌大于等于17点 

	if dealer.cardsPoints >= 17 or dealer.cardsType == CARDS_TYPE.BLACKJACK then 
		dealer.playStatus = PLAYER_STATUS.STAND
		return false
	elseif not hsACE then
		-- 小于17点,且没有ace 必须要牌  
		return true
	else
		return nil
	end
end
--[[
---3-----*********************************
-- _Blackjack:dealerTheOpen( ) 庄家开牌
-- 庄家持牌总点数少于17，则必须要牌，直到超过16，
-- 如果庄家的总点数等于或多于17点，则必须停牌,
-- 如果庄家手中有A，且A作11点时大于16点，做1点时小于或等于16点，则由庄家自己选择是否要牌。
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param _player 玩家数组, 
-- @return  
--]]
function _Blackjack:dealerTheOpen( )
	-- body 
	if self.gameStatus ~= GAME_STATUS.FOUR_SHUFFLE then
		ngx.log(ngx.ERR,"room code: ",self.roomCode,"cur game status is error  ,",GAME_STATUS_DES_MAP[self.gameType])
		return 
	end
	
	while true do
		local isNeed = self:dealerTheOpenPre()
	 	if isNeed == false then
	 		-- 不需要发牌了

	 		break;
 		elseif isNeed == nil then
 			-- 系统状态为庄家是否要牌

 			break;
 		end
	end
	
 
end

--[[
-- _Blackjack:setGameStatus( _status) 设置当前牌局状态,状态为_Blackjack.GAME_STATUS的变量之一
-- example
    
-- @param _status 当前需要设置的状态
-- @return  
--]]
function _Blackjack:setGameStatus( _status)
	-- 系统
	self.gameStatus = _status
end



--[[
-- 算牌结算
-- example
    
-- @param 无
-- @return  
--]]

function _Blackjack:cardsCount( )
	-- 系统

end

--[[
-- 过程判断主逻辑函数,该函数主要涉及牌局当前的状态处理
-- example
    
-- @param 无
-- @return  
--]]

function _Blackjack:mainloop( )
	-- 系统

end

--[[
-- 洗牌,重新组织牌
-- example
    
-- @param _pokerNums 扑克牌数量
-- @return  
--]]
function _Blackjack:shuffleCards(_pokerNums)
	 self.Cards = self:newCards(_pokerNums,false) 
end 
 
--[[
-- 创建二十一点游戏实例,
-- 使用4副，每副52张纸牌，洗在一起，置於发牌盒中，由荷官从其中分发。
-- 在二十一点游戏中，拥有最高点数的玩家获胜，其点数必须等于或低于21点；超过21点的玩家称为爆牌。
-- 2点至10点的牌以牌面的点数来相加，J、Q、K 每张为10点。A可记为1点或为11点，若玩家会因A而爆牌则A可算为1点。
-- 当一手牌中的A算为11点时，这手牌便称为软牌，因为除非玩者再拿另一张牌，不然不会出现爆牌。
-- 每位玩家的目的是要取得最接近21点数的牌来击败庄家，但同时要避免爆牌。要注意的是，若玩家爆牌在先即为输，就算随后庄家爆牌也是如此。
-- 若玩家和庄家拥有同样点数，玩家和庄家皆不算输赢。
-- 每位玩者和庄家之间的游戏都是独立的，因此在同一局内，庄家有可能会输给某些玩家，但也同时击败另一些玩家。
-- example
    local texasHoldem = require "game.TexasHoldem.TexasHoldem":new()
    local poker = texasHoldem.PokerImpl

-- @param   _room_code 编号 扑克牌数量
-- @param   _pokerNums 扑克牌数量
-- @return 返回二十一点游戏实例对象
--]] 

function _Blackjack:new(_room_code,_pokerNums) 
 	 local blackjackImpl =  setmetatable({players = {}}, _Blackjack); 
     -- 创建poker 对象,每局卡牌进行数据new

    blackjackImpl:shuffleCards(_pokerNums)
   	blackjackImpl.roomCode = _room_code
   	-- 庄家 使用房间编号,默认账户金币为 0
   	blackjackImpl.dealer = Player:new(_room_code ,nil) 
   	blackjackImpl.gameStatus = self.GAME_STATUS.WAIT_PLAYERS
   	blackjackImpl.enInsurance = false  -- 是否可以买保险 默认为不可以

    return blackjackImpl
end


--[[

]]
 