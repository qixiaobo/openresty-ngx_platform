--[[
-- 
-- 定义卡牌组合的类型,卡牌的大小比较,以及赔率倍数等
-- 同时修改该扑克牌的状态防止系统被攻击或者串改
]]--
local cjson = require "cjson"
local poker = require "game.poker.Poker"
--[[ -- 测试1
local poker = require "game.poker.Poker"

local pokercards = poker:new(1,false);
-- 卡牌数据集合生成
ngx.say(table.getn(pokercards.Cards),cjson.encode(pokercards.Cards))
]]
--[[ test2


local thPoker = require "game.TexasHoldem.TexasHoldem" :new()

ngx.say(table.getn(thPoker.PokerCardsSet),type(thPoker.PokerCardsSet.dealPublicCard),"  ",cjson.encode(thPoker.PokerCardsSet))

]]
--[[
-- 德州判断

local thPoker = require "game.TexasHoldem.TexasHoldem" :new()

local _ap = {betTypeSet={RoyalFlush={Money=1000,Odds=6} ,StrainghtFlush={Money=1000,Odds=5} } } 
local _bp = {win={Money=1000,Odds=6},lose={Money=1000,Odds=5}}
local _cp = {win={Money=1000,Odds=6},lose={Money=1000,Odds=5}}
local _dp = {win={Money=1000,Odds=6},lose={Money=1000,Odds=5}}
thPoker:allinmodel(_ap,_bp,_cp,_dp,true,52);

local test = {_ap,_bp,_cp,_dp}
--ngx.say(cjson.encode(test))
]]

--[[
牛牛判断
]]
local exmark = false
for si = 1,1 do 
	local nnPoker = require "game.niuniu.niuniu" :new()

	local _ap = {betTypeSet={RoyalFlush={Money=1000,Odds=6} ,StrainghtFlush={Money=1000,Odds=5} } } 
	local _bp = {win={Money=1000,Odds=6},lose={Money=1000,Odds=5}}
	local _cp = {win={Money=1000,Odds=6},lose={Money=1000,Odds=5}}
	local _dp = {win={Money=1000,Odds=6},lose={Money=1000,Odds=5}}

	local _ap = {}
	local _bp = {}
	local _cp = {}
	local _dp = {}
	nnPoker:allinmodel(_ap,_bp,_cp,_dp,false,52);

	local test = {_ap,_bp,_cp,_dp}
	local resT = {}
	 
	for i = 1,4 do
		resT[i] = {};
		resT[i].cardsType = nnPoker.CARDS_TYPE_DESCRIPTION[test[i].cardsType]; 
		resT[i].cardsstr = "cards: " 
		for j=1,5 do  
				resT[i].cardsstr = resT[i].cardsstr ..poker.SUIT_TYPE_MAP[test[i].cards[j].cardSuit] .." "..test[i].cards[j].cardId
		end
		if test[i].cardsType > 10 then
			ngx.say('---------------------------出现啦---------------------',resT[i].cardsType)
	 	end
		resT[i].cardsstr = resT[i].cardsstr .. resT[i].cardsType	
		 
		ngx.say(resT[i].cardsstr)
	end
	if exmark then break; end 
end



--[[
local CardTemp = require "game.poker.Card"
local cards = {
CardTemp:new(1,13,13),
CardTemp:new(1,11,11),
CardTemp:new(1,7,7),
	CardTemp:new(1,6,6),
	CardTemp:new(1,4,4),
}
local nnPoker = require "game.niuniu.niuniu" :new()

local cardType, cardsRes = nnPoker:getCardsMaxType(cards)
ngx.say(nnPoker.CARDS_TYPE_DESCRIPTION[cardType],cjson.encode(cardsRes))

]]

-- 测试
--[[ 
local testT = {a="abc"}
testT.__index = testT;


local resultTable = setmetatable({}, testT);
function testT:testfunction()
	ngx.say(self.a) 
end

resultTable:testfunction();
resultTable.a = 123
resultTable:testfunction();
]]
 
