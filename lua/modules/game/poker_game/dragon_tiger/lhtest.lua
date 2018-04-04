

local dt = require "game.dragon_tiger.dragon_tiger"

local longhu = dt:new()

ngx.say(table.getn(longhu.Cards))
longhu:deal()
local result = longhu:getResult()
 
ngx.say("龙牌:",longhu.SUIT_TYPE_MAP[longhu.dragon.cards[1].cardSuit] .." "..longhu.dragon.cards[1].cardId," 虎牌:"
	,longhu.SUIT_TYPE_MAP[longhu.tiger.cards[1].cardSuit] .." "..longhu.tiger.cards[1].cardId)
 
local resultMap = {
	"虎赢(庄赢)",
	"和局",
	"龙赢(闲赢)",
}
ngx.say(resultMap[result + 2])

		 