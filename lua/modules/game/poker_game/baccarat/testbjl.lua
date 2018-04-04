--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:baccarat.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  百家乐游戏的测试代码 
--]]

local baccarat = require "game.baccarat.baccarat" 
local cjson = require "cjson"
local request = require "common.request_args"

local baccaratPoker = baccarat:new(3);
local res = baccaratPoker:deal()





ngx.say("庄家牌:")
local dealStr = ""
for j=1,table.getn(res.dealerCards) do  
	dealStr = dealStr ..baccaratPoker.SUIT_TYPE_MAP[res.dealerCards[j].cardSuit] .." "..res.dealerCards[j].cardId
end
ngx.say(dealStr)

ngx.say("闲家牌:")
local dealStr = ""
for j=1,table.getn(res.playerCards) do  
	dealStr = dealStr ..baccaratPoker.SUIT_TYPE_MAP[res.playerCards[j].cardSuit] .." "..res.playerCards[j].cardId
end
ngx.say(dealStr)
if res.compareRes > 0 then 
	ngx.say("庄赢"," 庄家牌型: ",baccarat.CARDS_TYPE_DESCRIPTION[res.dealerCardsType]," 闲家牌型: ",baccarat.CARDS_TYPE_DESCRIPTION[res.playerCardsType])
elseif res.compareRes == 0 then
	ngx.say("和"," 庄家牌型: ",baccarat.CARDS_TYPE_DESCRIPTION[res.dealerCardsType]," 闲家牌型: ",baccarat.CARDS_TYPE_DESCRIPTION[res.playerCardsType])
else
	ngx.say("闲赢"," 庄家牌型: ",baccarat.CARDS_TYPE_DESCRIPTION[res.dealerCardsType]," 闲家牌型: ",baccarat.CARDS_TYPE_DESCRIPTION[res.playerCardsType])
end

