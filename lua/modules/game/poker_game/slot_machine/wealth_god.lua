--[[
--  作者:Steven 
--  日期:2017-05-23
--  文件名:wealth_god.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  财神 水果机的算法实现与功能实现
--]]
--[[
	_wgod 结构包含以下主要信息
	-- 动态信息
	_WGod = {
		elementArray = {{},{},{},{},{}} , 	-- 存放序列的数组对象
		dealResArray = {{},{},{},{},{}},	-- 数组当前显示的三个对象
		linesMap = {}, --  多级组线对象
		linesArray = {{},{},{},{}}, -- 由线组合而成的素组组合列表,遍历该数组进行判断是否中奖,返回中奖的排序,该数组的元素为5个 nn mm 组成数组
		resLinesArray = {{},{},{},{}} -- 1线开始,3个以上的成结果的数组排列元素同样为 3个以上的 nn mm 的数组和当前是否为财神殿的组合牌
	}

]]

local cjson = require "cjson"
local _WGod = {}

_WGod.__index = _WGod
--[[
	-- 财神到类型游戏拥有5*13个数组
	-- 随机从左向右,每个数组的13个数字滚动随机,从左开始
	-- 如果连续中了,系统将返回返回指定的暴击结果
	local LABEL = {
		
	}
]]
--  标签类型
--  财神到拥有8个类型元素
local LABEL = {
		JACK = 1,
		QUEEN = 2,
		KING = 3,
		ACE = 4,
		GOLD_INGOT =5,	-- 金元宝
		LONGEVITY_PEACHES = 6,	-- 寿桃
		LION_HEAD = 7,	-- 狮头
		LOTUS = 8,		-- 莲花
		LANTERNS = 9,	-- 灯笼
		CARP = 10,		-- 鲤鱼
		THE_BES = 11,	-- 如意
		GOD = 12,		-- 玉帝 当出现3,4,5个玉帝,系统给予进入财神殿机会,由用户自己进行分配
		WEALTH_GOD = 13,-- 财神 
}	 
_WGod.LABLE = LABLE

local LABEL_INDEX = {
	1,2,3,4,5,6,7,8,9,10,11,12,13
} 
_WGod.LABEL_INDEX = LABEL_INDEX

-- 随机选择数组,该数据决定当前5*3的数组的显示情况和中奖概率
local LABEL_CHANCE_ARRAY1 = {
	{1,1,1,1,2,2,2,3,3,3,4,4,4,5,5,6,7,8,9,10,11,12},
	{1,1,1,1,2,2,2,3,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13},
	{1,1,1,1,2,2,2,3,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13},
	{1,1,1,1,2,2,2,3,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13},
	{1,1,1,1,1,2,2,2,3,3,3,4,4,5,5,6,6,7,8,9,10,11,12},
} 
local LABEL_CHANCE_ARRAY = {
	{1,1,1,1,2,2,2,3,3,3,4,4,4,5,5,6,7,8,9,10,11,12},
	{1,1,1,1,2,2,2,2,3,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13},
	{1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13},
	{1,1,1,1,1,2,2,2,2,3,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,12},
	{1,1,1,1,1,2,2,2,3,3,3,4,4,5,5,6,6,7,8,9,10,11,12,13,12},
} 
local LABEL_CHANCE_ARRAY3 = {
	{1,1,1,1,2,2,2,3,3,3,4,4,4,5,5,6,7,8,9,10,11,12},
	{1,1,1,1,2,2,2,3,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13},
	{1,1,1,1,2,2,2,3,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13},
	{1,1,1,1,2,2,2,3,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13},
	{1,1,1,1,1,2,2,2,3,3,3,4,4,5,5,6,6,7,8,9,10,11,12},
} 

_WGod.LABEL_CHANCE_ARRAY1 = LABEL_CHANCE_ARRAY1
_WGod.LABEL_CHANCE_ARRAY = LABEL_CHANCE_ARRAY
_WGod.LABEL_CHANCE_ARRAY3 = LABEL_CHANCE_ARRAY3
  
local LABEL_MAP = {
"JACK",
"QUEEN",
"KING",	
"ACE",		-- ace
"GOLD_INGOT",	-- 金元宝
"LONGEVITY_PEACHES", -- 寿桃
"LION_HEAD",	-- 狮头
"LOTUS",		-- 莲花
"LANTERNS", 	-- 灯笼
"CARP",		-- 鲤鱼
"THE_BES",	-- 如意
"GOD",		-- 玉帝 当出现3,4,5个玉帝,系统给予进入财神殿机会,由用户自己进行分配
"WEALTH_GOD",	-- 财神 
} 

_WGod.LABEL_MAP = LABEL_MAP


-- 中奖的倍率
-- 每种元素组成成3,4,5时候的暴击数量
-- 该数组使用默认的结构,系统可以从数据库中初始化
local BET_ODDS = {  
	{5,10,100},		-- 10
	{5,15,100},		-- 11
	{10,15,100},	-- 10
	{10,15,100},	-- 9
	{10,20,200},	-- 8
	{10,30,200},	-- 7
	{20,50,300},	-- 6
	{30,100,800},	-- 5
	{35,100,800},	-- 4
	{35,100,800},	-- 4
	{50,100,1000}, -- 11
	{1,1,1},	-- 进入财神殿,即倍率更高的区域n多次 1
	{0,0,0},	-- 三个财神,默认为最大倍击的查找最高倍数击的物品 2
}
_WGod.BET_ODDS = BET_ODDS

-- 5*n的数组布局
-- n表示标签数量,系统默认为13标签
_WGod.COLUMNS = 5
_WGod.SHOW_ROWS = 3
_WGod.ROWS = 13



--[[
-- 根据素组传递过来的nn mm 的数组中查询是否存在有效排列组合 如果存在则返回该数组有效部分
-- example
	local zuhe = {{1,1},{2,1},{3,1},{4,1},{5,1}}
	local res = _WGod:isValuedLines(zuhe) -- 结果可能如下 {{1,1},{2,1},{3,1}} or {{1,1},{2,1},{3,1},{4,1}} 以最大的为

-- @param _group  元素数组组合的数组 本游戏应为 5 个 
-- @param return 返回 有效的组合数组
]]
function _WGod:isValuedLines(_group) 

	-- ngx.say(cjson.encode(self.dealResArray))
	-- ngx.say(cjson.encode(_group))

	local firstElement = nil

	local eleSums = 0

	for i=1,table.getn(_group) do
		-- 如果是财神,直接累加   
		if self.dealResArray[_group[i][1]][_group[i][2]] == LABEL.WEALTH_GOD then
			eleSums = eleSums + 1
		else --  如果不是财神
			if firstElement == nil then -- 累计第一次进入 后续所有的新非财神的id与第一次不相同,则退出本次循环
				firstElement = self.dealResArray[_group[i][1]][_group[i][2]]
				eleSums = eleSums + 1
			else
				if firstElement == self.dealResArray[_group[i][1]][_group[i][2]] then
					eleSums = eleSums + 1
				else
					break;
				end

			end 
		end 
	end
	-- ngx.say(eleSums)
	-- if eleSums >= 3 返回当前有效值,如果小于3 则不返回 如果当前为玉帝,则返回所有进入财神殿标志
	if eleSums >= 3 then
		local res = {line = {}}
		for i=1,eleSums do 
			res.line[i] = _group[i]
		end
		--  返回当前有效数组,以及是否进入财神殿标志
		res.isGOD = (firstElement == LABEL.GOD and true or false);
		res.elementId = firstElement;
		-- ngx.say(cjson.encode(res))
		return res
	end

return nil 
end


--[[
-- 根据素组传递过来的nn mm 的数组中查询是否存在有效排列组合,并返回是否为财神信息
-- example
	local zuhe = {{1,1},{2,1},{3,1},{4,1},{5,1}}
	local res = _WGod:isValuedLines(zuhe) -- 结果可能如下 {{1,1},{2,1},{3,1}} or {{1,1},{2,1},{3,1},{4,1}} 以最大的为

-- @param _group  元素数组组合的数组 本处 为当前节点的有效数组 个 
-- @param return 返回 有效的组合数组和当前是全部为财神

]]
function _WGod:isValuedLinesEx(_group) 

	-- ngx.say(cjson.encode(self.dealResArray))
	-- ngx.say(cjson.encode(_group)) 
	local firstElement = nil 
	local eleSums = 0 
	local len = table.getn(_group)
	for i=1, len do
		-- 如果是财神,直接累加   
		if self.dealResArray[_group[i][1]][_group[i][2]] == LABEL.WEALTH_GOD then
			eleSums = eleSums + 1
		else --  如果不是财神
			if firstElement == nil then -- 累计第一次进入 后续所有的新非财神的id与第一次不相同,则退出本次循环
				firstElement = self.dealResArray[_group[i][1]][_group[i][2]]
				eleSums = eleSums + 1
			else
				if firstElement == self.dealResArray[_group[i][1]][_group[i][2]] then
					eleSums = eleSums + 1
				else 
					break;
				end
			end 
		end 
	end
	-- ngx.say(eleSums)
	-- if eleSums >= 3 返回当前有效值,如果小于3 则不返回 如果当前为玉帝,则返回所有进入财神殿标志
	local res = {
			line = _group,
			elementId = firstElement == nil and LABEL.WEALTH_GOD or firstElement,
			elementSize = eleSums , 
			isUniform = eleSums == len and true or false
	} 
 	return res;
end

--[[
-- 生成系统5*3的数组组合数组,系统初始化生成改数组,通过数组的组合列表进行用户中奖判断
-- 该函数作为初始化存在支持未来n*m的数组生成,该函数为递归函数

-- @param _colum_n   n 列
-- @param _row_m   m 行
-- @param _cDepth 当前深度,该深度对应x*y(n*m)的x 即列的位置
-- @param _last_Note 上一个节点数组

-- @param return 
]]

function _WGod:initLinesMap(_colum_n,_row_m,_cDepth,_lastNote)
	-- body
	if _cDepth > _colum_n then   
		return nil   
	end; 
	 
	for m = 1, _row_m do
		 _lastNote[""..m] = {}
		 _lastNote[""..m].n = _cDepth
		 _lastNote[""..m].m = m 
		 local newDepth = _cDepth + 1 
		 -- ngx.say("n ",_cDepth," m ",m," ",cjson.encode(_lastNote[""..m]))  
		 self:initLinesMap(_colum_n,_row_m,newDepth,_lastNote[""..m]) 
	 	 -- self.testSize = self.testSize + 1
	end 
end
--[[
-- 生成lines组合数组 
-- 
--]]

function _WGod:initLinesArray(_endDepth,_linesMap,_lastArray)
	 
	 for k,v in pairs(_linesMap) do

	 	if k ~= "n" and k ~= "m" then  
		 	if _lastArray == nil then
		 		_lastArray = {}
		 	end 
		 	local _curNode = {v.n, v.m}
		 	local nextArray = table.clone(_lastArray)   
		 	table.insert(nextArray,_curNode)  
		 	if v.n < _endDepth then
		 		self:initLinesArray(_endDepth, v, nextArray) 
		 	else
		 		table.insert(self.linesArray,nextArray)
		 	end
		 end 
	 end
end

--[[
-- 计算有效的线路,当前三个组合不能成为有效计算值,则无需进行计算,
-- 一直向下计算,一直计算到最大的数字进行写入
]]

function _WGod:computeLinesArray(_linesMap,_lastArray)
	 
	 local nn = _linesMap.n;
	 local isNeedAdd = 0;
	 local res
	 if nn > 1 then 
		-- 大于2的时候进行判断,是否存在该条支路有效,当支路有效,则进行下一次判断,如果当前有效
 		-- 而下一级不行成数组,则写入自身
		 res = self:isValuedLinesEx(_lastArray);	

		 -- 如果不是同花 则直接退出该条循环		
		 if not res.isUniform then  
		 	return true
		 end 

		 -- 第三列开始的信息 则需要在当前记录一次是否需要添加记录的标志
		 if nn >= 3 then
		 	isNeedAdd = 1 -- 默认三个形成记录,则可以添加,当后续出现记录时,则取消添加
		 end

 	 end

	 for k,v in pairs(_linesMap) do 
	 	if k ~= "n" and k ~= "m" then  
		 	if _lastArray == nil then
		 		_lastArray = {}
		 	end 
		 	local _curNode = {v.n, v.m}
		 	local nextArray = table.clone(_lastArray)   
		 	table.insert(nextArray,_curNode)  
		 	-- 如果自对象返回有一个写过,则本条记录不用写入
 			local nextline = self:computeLinesArray( v, nextArray)
 			if not nextline then
 				-- 叶子结点已经写入,则节点不用写入
 				isNeedAdd  = -1
 			end 
	 	 
		 end
	 end

	 -- 如果仍然等于1,表示后续返回没有可以形成写记录,则写入自身
	 -- 如果后续有写入,则可写的部分不用写入
	 -- 如果子类返回false 说明子类是可写的,直接返回false
	 if isNeedAdd == 1 then
	 	table.insert(self.resLinesArray,res)  
	 	return false 
	 elseif isNeedAdd == -1 then
	 	return false 
	 end

	 return true

end

--[[
-- 初始化完财神到数组空间后,进行deal操作,deal将进行一次随机数
-- 并且计算当前所有组合,并将结果返回给用户
	local wgod = require "game.slot_machine.wealth_god":new()
	local resultArray = wgod:deal()

-- @return 返回结果数组,该数组结构为
	resultArray = {
		{betType = 1,valueColumns = 1 , counts = 2},
	--   押注类型/牌型, 有效列数(取最大为主), 相同类型的数量,即产生多少线
	--   没有的结果直接为0即可
		{betType = 3,valueColumns = 0 , counts = 0},
	}
-- 
]]

function _WGod:deal()
 	 
	for i = 1,self.COLUMNS do
		if not self.dealResArray[i] then
			self.dealResArray[i] = {}
		end
		local tempcol = table.clone(LABEL_CHANCE_ARRAY[i])
		for j =1,self.SHOW_ROWS do
			local cur_index = math.random(1, table.getn(tempcol))
			-- 读取界面是按照顺序进行？
			self.dealResArray[i][j] = tempcol[cur_index]

			-- table.remove(tempcol,cur_index)
			table.removeElements(tempcol,self.dealResArray[i][j])
		end
	end 
 
	self.resLinesArray = {}  
	self:computeLinesArray(self.linesMap, nil) 
end


function _WGod:test()
	 -- 计算结果和回收期

	-- self.linesMap[1] = 
	local testmpa = cjson.decode("[[12,9,10],[3,12,6],[2,12,1],[7,13,8],[2,9,12]]")

	for i = 1,self.COLUMNS do
		if not self.dealResArray[i] then
			self.dealResArray[i] = {}
		end
		local tempcol = table.clone(LABEL_CHANCE_ARRAY[i])
		for j =1,self.SHOW_ROWS do
			-- local cur_index = math.random(1, table.getn(tempcol))
			-- 读取界面是按照顺序进行？
			self.dealResArray[i][j] =  testmpa[i][j]--tempcol[cur_index]

			-- table.remove(tempcol,cur_index)
			-- table.removeElements(tempcol,self.dealResArray[i][j])
		end
	end 
  
	self.resLinesArray = {}  
	self:computeLinesArray(self.linesMap, nil) 
end


-- 测试版本进行显示全部按照随机初始化

--[[
-- new 创建财神到框架,多个用户共享该引擎,该系统需要的参数由当前计算出来,所以财神到模块要
-- 进行锁处理!!!!!
-- example
    local WGOD = require "game.poker.Poker"
    local wgod = WGOD.new(1,false);
 
-- @return 返回 财神到对象 ,该对象进行一次随机,并返回当前随机产生的随机数量信息
]]
function _WGod:new()
	local god = setmetatable({}, _WGod)
	 

	 -- 初始化数组对象
	 self.linesMap = {n = 0,m = 0}
	 self.linesArray = {}
	 self.testSize = -1

	 self:initLinesMap(self.COLUMNS,self.SHOW_ROWS,1,self.linesMap);
	 self:initLinesArray(5,self.linesMap,nil)

	 --
	 self.dealResArray = {} 

	return god
end

return _WGod