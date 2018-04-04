

local wg = require "game.slot_machine.wealth_god":new()
local cjson = require "cjson"
local _weightArr = {1,1,2,6} -- 权重的大小为总大小为10,4个对象的比例分别为10%,10%,20%,60%
local randomHelp = require "common.random_help"
-- local weiIndex = randomHelp.random(_weightArr)	-- 返回值即为有效的对象值
-- local resMap = {}
-- for i=1,10000 do
-- 	local weiIndex = randomHelp.random(_weightArr)	-- 返回值即为有效的对象值
-- 	if not resMap[weiIndex] then resMap[weiIndex] = 0 end
-- 	resMap[weiIndex] = resMap[weiIndex] + 1
-- end
-- for i=1,4 do
-- 	ngx.say(resMap[i]/10000)
-- end
-- ngx.say(cjson.encode(resMap))

wg:test();
ngx.say(cjson.encode(wg.dealResArray))
ngx.say(cjson.encode(wg.resLinesArray))


-- wg:test()
-- wg:deal();

-- local cjson = require "cjson"
-- local template = require "resty.template"
-- -- ngx.say(cjson.encode(wg.elementArray))
-- -- ngx.say(cjson.encode(wg.dealResArray))
-- -- ngx.say(cjson.encode(wg.linesMap))
-- -- ngx.say(cjson.encode(wg.linesArray))
-- -- ngx.say(table.getn(wg.linesArray))

-- ngx.say(cjson.encode(wg.resLinesArray))
-- -- ngx.say(table.getn(wg.resLinesArray))
-- -- wg:test();
 
-- local tSrc1 = {1,1,2,2,4,4,5,5,4,3,3};
 
-- -- table.removeElements(tSrc1,4) -- nil
-- -- tmap = {2,2,3,3}
-- -- ngx.say(cjson.encode(tSrc1))


-- -- template.render("wg_show.html", { dealResArray = wg.dealResArray,resLinesArray = wg.resLinesArray})
-- -- ngx.say(cjson.encode({ dealResArray = wg.dealResArray,resLinesArray = wg.resLinesArray}))
-- -- ngx.say(cjson.encode(wg.dealResArray))
--  for y = 1,3 do
--  	-- for x = 1, 5 do
--  	local str1 = ""
--  	for x = 1,5 do 
--  		local ele = wg.dealResArray[x][y] 
--  		if ele == 13 then
--  			str1 = str1 .."  百"
--  		elseif ele < 10 then
--  			str1 = str1 .."  0".. ele
--  		else
--  			str1 = str1 .."  ".. ele
--  		end
--  	end 
--  	ngx.say(str1) 
--  end
-- -- 结果如下
-- ngx.say("结果如下: ")
-- if table.getn(wg.resLinesArray) == 0 then
-- 	ngx.say("未中奖")
-- end

-- local resIndex = 1
-- for index = 1,table.getn(wg.resLinesArray) do
-- local resLines = wg.resLinesArray[index]
--  for y = 1,3 do
--  	-- for x = 1, 5 do
--  	local str1 = ""
--  	for x = 1,5 do 
--  		local ele = wg.dealResArray[x][y]  
--  		if resLines.line[x] then 
--  			if resLines.line[x][1] == x and resLines.line[x][2] == y then 
--  				if ele == 13 then
--  					str1 = str1 .."    百搭"
--  				else
--  					str1 = str1 .."    中"..resLines.elementId 
--  				end
--  			else
--  				if ele == 13 then
-- 	 			str1 = str1 .."      百"
-- 		 		elseif ele < 10 then
-- 		 			str1 = str1 .."     0".. ele
-- 		 		else
-- 		 			str1 = str1 .."     ".. ele
-- 		 		end
--  			end
--  		else
--  			if ele == 13 then
--  			str1 = str1 .."      百"
-- 	 		elseif ele < 10 then
-- 	 			str1 = str1 .."     0".. ele
-- 	 		else 
-- 	 			str1 = str1 .."     ".. ele
-- 	 		end
-- 	 		str1 = str1  
--  		end 
--  	end 
--  	ngx.say(str1) 
--  end
--  ngx.say(" 第"..resIndex.."连线")
--  resIndex = resIndex + 1
-- end
