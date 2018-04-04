--[[
--  作者:Steven 
--  日期:2017-05-23
--  文件名:dragon_tiger.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  龙虎纸牌游戏规则和玩法的封装定义
--  龙虎斗是由百家乐游戏衍出的一种最简单易学的博彩游戏，
-- 	游戏投注方式同百家乐一样，游戏使用八副扑克牌，龙和虎仅派出一张牌就可以定输赢。
-- 	龙虎斗中K为最大，A为最小。若龙虎都为K，视为平局，玩家输一半。牌面大小不比花色，只比点数
--  定义卡牌组合的类型,卡牌的大小比较,以及赔率倍数等 
--]]
local Poker = require "game.poker.Poker"
local cjson = require "cjson"
local _DTPoker = {};
_DTPoker.VERSION = "0.1"

-- 继承poker
_DTPoker.__index = _DTPoker
setmetatable(_DTPoker, Poker);

-- 龙虎游戏默认使用八张牌
_DTPoker.PokerNum = 8
 


--[[
---1  -----*********************************
-- _DTPoker:deal(  )  发牌,要牌： 龙虎,龙和虎每局只发一张牌
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param 无 
-- @return  无
--]]
function _DTPoker:deal() 

	local surplus = self:surplusCards()
	--  还剩下10张牌的时候从新构造卡牌
	if surplus < 10 then 
		self.Cards = self:newCards(self.PokerNum,false);
	end

 	self.dragon.cards[1] = self:getCard() 
 	self.tiger.cards[1] = self:getCard()
end
--[[
---1  -----*********************************
-- _DTPoker:dealDragon(  )  发牌,要牌： 给龙(闲)家发一张牌 先发龙牌
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param 无 
-- @return  无
--]]
function _DTPoker:dealDragon() 

	local surplus = self:surplusCards()
	--  还剩下10张牌的时候从新构造卡牌
	if surplus < 10 then 
		self.Cards = self:newCards(self.PokerNum,false);
	end 
 	self.dragon.cards[1] = self:getCard()  
end
--[[
---1  -----*********************************
-- _DTPoker:dealTiger(  )  发牌,要牌： 虎(庄)家发一张牌 后发虎牌
-- example
    -- 前提是需要new一次创建卡牌对象 该对象 卡牌不足100 换牌
-- @param 无 
-- @return  无
--]]
function _DTPoker:dealTiger() 

	local surplus = self:surplusCards()
	--  还剩下10张牌的时候从新构造卡牌
	if surplus < 10 then 
		self.Cards = self:newCards(self.PokerNum,false);
	end 
 	self.tiger.cards[1] = self:getCard()  
end

--[[
---1  -----*********************************
-- _DTPoker:getResult( ) 获取
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
    发完牌之后就可以进行牌局结果的获取
-- @param 无
-- @return  返回 当前牌局的结果,结果 1 表示龙赢 0 表示和  -1  表示虎赢
--]]

local CARDS_COMPARE =  Poker.CARDS_COMPARE;
function _DTPoker:getResult()
	-- body
	if not self.dragon.cards[1] or not self.tiger.cards[1] then 
		return nil
	end	 
 	local dCard = self.dragon.cards[1]
 	local tCard = self.tiger.cards[1]

 	if dCard.cardPoint == tCard.cardPoint then
 		return CARDS_COMPARE.EQUAL

	else 
		return dCard.cardPoint > tCard.cardPoint and   CARDS_COMPARE.OVER or   CARDS_COMPARE.UNDER
	end 
end


--[[
--	_DTPoker:new() 龙虎扑克牌对象的创建，包含8副牌,龙虎的发牌，龙虎的扑克牌的比较

-- @return 当局龙虎扑克的对象,系统将会在卡牌不足时提醒用户
--  		 
]]

function _DTPoker:new()
 	local dtImpl =  setmetatable({}, _DTPoker);
    -- 创建poker 对象,每局卡牌进行数据new
    dtImpl.Cards = dtImpl:newCards(self.PokerNum,false);

    -- 龙牌定义
	dtImpl.dragon = {
		cards = {}
	}
	-- 虎牌定义
	dtImpl.tiger = {
		cards = {} 
	}

    return dtImpl;
end

return _DTPoker