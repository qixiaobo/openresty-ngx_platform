 


local baccarat = require "game.baccarat.baccarat" 
local cjson = require "cjson"
local poker = require "game.poker.Poker"
local request = require "common.request_args"
local card = require "game.poker.Card"
local baccaratPoker = baccarat:new(3);
-- local res = baccaratPoker:deal()
 

local args = request.getUriArgs();

if not args then
	ngx.say("参数错误")
	return
end 

baccaratPoker.PlayerCards = { }
	baccaratPoker.PlayerCards[1] = card:new(math.random(1,4),args.card1,baccarat.CARD_POINT[baccarat.CARD_ID_KEY_MAP[tonumber(args.card1)]],false)
	baccaratPoker.PlayerCards[2] = card:new(math.random(1,4),args.card2,baccarat.CARD_POINT[baccarat.CARD_ID_KEY_MAP[tonumber(args.card2)]],false)
 	if args.card5 then
 		baccaratPoker.PlayerCards[3] = card:new(math.random(1,4),args.card5,baccarat.CARD_POINT[baccarat.CARD_ID_KEY_MAP[tonumber(args.card5)]],false)
 	end

baccaratPoker.DealerCards = {}
	baccaratPoker.DealerCards[1] = card:new(math.random(1,4),args.card3,baccarat.CARD_POINT[baccarat.CARD_ID_KEY_MAP[tonumber(args.card3)]],false)
	baccaratPoker.DealerCards[2] = card:new(math.random(1,4),args.card4,baccarat.CARD_POINT[baccarat.CARD_ID_KEY_MAP[tonumber(args.card4)]],false)
 
local res1,res2 = baccaratPoker:preTestDPCards_test(baccaratPoker.DealerCards,baccaratPoker.PlayerCards)
	 
local res1 = baccaratPoker:jugeCards(baccaratPoker.DealerCards,baccaratPoker.PlayerCards)
 
local res = {
	compareRes = res1,-- 比较大小 >0 庄家打,<0表示闲家大 =0 表示和
	dealerCardsType = baccaratPoker.dealerCardsType,
	playerCardsType = baccaratPoker.playerCardsType,
	dealerCards = baccaratPoker.DealerCards,
	playerCards = baccaratPoker.PlayerCards,
}
 

 ngx.say("闲家牌:")
local dealStr = ""
for j=1,table.getn(res.playerCards) do  
	dealStr = dealStr ..baccaratPoker.SUIT_TYPE_MAP[res.playerCards[j].cardSuit] .." "..res.playerCards[j].cardId
end
ngx.say(dealStr," 闲家点数: ",baccaratPoker.playerPoints)

ngx.say("庄家牌:")
local dealStr = ""
for j=1,table.getn(res.dealerCards) do  
	dealStr = dealStr ..baccaratPoker.SUIT_TYPE_MAP[res.dealerCards[j].cardSuit] .." "..res.dealerCards[j].cardId
end
ngx.say(dealStr," 庄家点数: ",baccaratPoker.dealerPoints)


if res.compareRes > 0 then 
	ngx.say("庄赢"," 庄家牌型: ",baccarat.BET_KEYS_MAP[res.dealerCardsType]," 闲家牌型: ",baccarat.BET_KEYS_MAP[res.playerCardsType])
elseif res.compareRes == 0 then
	ngx.say("和"," 庄家牌型: ",baccarat.BET_KEYS_MAP[res.dealerCardsType]," 闲家牌型: ",baccarat.BET_KEYS_MAP[res.playerCardsType])
else
	ngx.say("闲赢"," 庄家牌型: ",baccarat.BET_KEYS_MAP[res.dealerCardsType]," 闲家牌型: ",baccarat.BET_KEYS_MAP[res.playerCardsType])
end

