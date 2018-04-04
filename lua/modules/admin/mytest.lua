
--[[
	测试获取菜单
]]
local cjson = require "cjson"

local adminMenu = require "admin.model.menu"
local roleS = require "admin.model.role"

-- ngx.say(adminMenu.getMenuList())
-- ngx.say(roleS.getRoles())
local function makeMenu(_tmenu)
 	if not _tmenu then 
 		ngx.log(ngx.ERR,"-------------error      ")
 		return ""
 	end
 	if table.getn(_tmenu) < 1 then  return "" end

    local str = "<li>"
    -- ngx.log(ngx.ERR,"-------------length      ",table.getn(_tmenu))
    for i=1,table.getn(_tmenu) do
        local menuTemp = _tmenu[i]
        if not menuTemp then 
			ngx.log(ngx.ERR,"+++++++++++++++++++++menu is error")
        end
        if menuTemp.childList then
            -- 有子菜单的格式
            str = str ..  string.format('<a href="#"><i class="fa fa-home"></i><span class="nav-label">%s</span><span class="fa arrow"></span></a>',menuTemp.menu_name)

            str = str .. '<ul class="nav nav-second-level">' 
           
           	str = str .. makeMenu(menuTemp.childList)
           
            str = str .. '</ul>'
        else
            str = str ..  string.format('<a class="J_menuItem" href="layouts.html"><i class="fa fa-columns"></i>  <span class="nav-label">%s</span></a>',menuTemp.menu_name)
            ngx.log(ngx.ERR,menuTemp.menu_name)
        end

    end
    str = str.."</li>"
    return str
end

local menustr = makeMenu(adminMenu.getMenuList())
ngx.say(menustr)
-- local mysql = require "common.db.db_mysql"

-- for i=0,2 do

-- local mysqlT = mysql:new();
-- if not mysqlT then
	
-- 	mysql.errorCount = mysql.errorCount + 1
-- 	ngx.log(ngx.ERR,"mysqlT is nil -----------",mysql.errorCount," ",mysql.okCount )

-- 	local mysqlT1 = mysql:new();
-- 	if mysqlT1 then
-- 		ngx.log(ngx.ERR,"mysqlT is nil ---------++++++++++++++++++--") 
-- 		mysqlT1:close();
-- 	end
-- else
-- 	mysql.okCount = mysql.okCount + 1
-- 	mysqlT:close();
-- end 
--  -- ngx.say("close===========",i);


-- end
-- local cjson = require "cjson"
 
-- local header = ngx.req.get_headers();
--  local cardsSize = 52;
--  local cards = {}
-- 	for icard = 1,52 do
-- 		cards[icard] = icard;
-- 	end

-- local function mycards()
	
-- 	 -- 测试随机数
-- 	local resultCards = {};
-- 	ngx.say("cur cards size: ",table.getn(cards));
-- 	for i=1,5 do 
-- 		local redomIndex = math.random(cardsSize);
-- 		resultCards[i] = cards[redomIndex];
-- 		table.remove(cards,redomIndex)
-- 		cardsSize = cardsSize - 1;
-- 	end
-- 	return resultCards;
-- end

-- for i=1,5 do
-- ngx.say(cjson.encode(mycards()))
-- end