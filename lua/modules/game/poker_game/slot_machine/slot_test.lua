
local SLOT =  require "game.slot_machine.slot_machine"
local cjson = require "cjson"
local slotImp = SLOT:new()

slotImp:stake(nil)



-- 押注测试 

ngx.say(cjson.encode(slotImp.betResMap))