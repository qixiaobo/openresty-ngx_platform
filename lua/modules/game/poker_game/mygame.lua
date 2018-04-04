


local baccarat = require "game.baccarat.baccarat"
local Poker = require "game.poker.Poker"
local cjson = require "cjson"
 
-- ngx.say(cjson.encode(baccaratPoker.PokerCards))
-- ngx.say(table.getn(baccaratPoker.PokerCards.Cards))

 

local bitHelp = require("common.bit_help")
 
local tt = bitHelp:new(2)
ngx.say(tt:toHexStr())
tt:setBit(1) 
tt:setBit(3) 
ngx.say(tt:toHexStr())
ngx.say(tt:getBit(1),tt:getBit(2),tt:getBit(3))



-- local res1,res2 = baccarat:getCardsType(testcards1,testcards2)

-- ngx.say(cjson.encode(testcards1))
-- ngx.say(cjson.encode(testcards2))
-- baccaratPoker:deal()
-- local t1 = {a = "a"}
-- -- t1.__index = t1;

-- local t2 = {b = "b"}
-- t2.__index = t2;
-- setmetatable(t2, t1); 

-- local t3 = {c = "c"} 
-- setmetatable(t3, t2); 
-- ngx.say(t3.c,t3.b,t3.a)

-- 德州扑克测试

 

