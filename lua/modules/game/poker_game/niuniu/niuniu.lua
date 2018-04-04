--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:niuniu.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  牛牛的封装,棋牌房间调用时需要首先调用一次new对象,创建新对象之后,对象中包含棋牌的扑克牌集合
--  通过扑克牌集合封装类进行发牌等基础操作
--  牛牛卡牌的玩法预定义
--  定义卡牌组合的类型,卡牌的大小比较,以及赔率倍数等
--  同时修改该扑克牌的状态防止系统被攻击或者串改
--]]
 

local Poker = require "game.poker.Poker"
local cjson = require "cjson"
local _NNPoker = {};
_NNPoker.VERSION = "0.1"

-- 继承poker
_NNPoker.__index = _NNPoker
setmetatable(_NNPoker, Poker);

-- 牛牛的牌的大小定义
--[[
十小 > 炸弹 >  五花 > 四花 > 牛牛 > 有分 > 没分；
]]
_NNPoker.CARDS_TYPE = {
	LESS_TEN = 15,  -- 10小
    BOMB = 14 ,   -- 炸弹
    FIVE_JINHUA = 13, -- 五金花
    FOUR_JINHUA = 12, -- 银花
    TEN_NIU = 11, 
    NINE_NIU = 10,
    EIGHT_NIU = 9,
    SEVEN_NIU = 8,
    SIX_NIU = 7,
    FIVE_NIU = 6,
    FOUR_NIU = 5,
    THREE_NIU = 4,
    TWO_NIU = 3,
    ONE_NIU = 2,
    NO_NIU = 1,      -- 没牛
}



_NNPoker.CARDS_TYPE_DESCRIPTION = 
{
    "普通牌",
    "一牛", "二牛", "三牛", "四牛", "五牛", "六牛", "七牛", "八牛", "九牛","牛牛"
    ,"银花","金花","炸弹","10小" 
}


_NNPoker.CARDS_TYPE_MAP = {
"ONE_NIU", "TWO_NIU", "THREE_NIU","FOUR_NIU","FIVE_NIU","SIX_NIU","SEVEN_NIU","EIGHT_NIU","NINE_NIU",
}


local CARDS_TYPE = _NNPoker.CARDS_TYPE;
local CARDS_TYPE_MAP = _NNPoker.CARDS_TYPE_MAP;
--[[
	赔率定义
]]
_NNPoker.CARD_TYPE_ODDS = {
    BOMB = 6 ,   -- 炸弹
    LESS_TEN = 5,   -- 10小
    FIVE_JINHUA = 5, -- 五金花
    FOUR_JINHUA = 4, 
    NINE_NIU = 2,
    EIGHT_NIU = 2,
    SEVEN_NIU = 2,
    SIX_NIU = 1,
    FIVE_NIU = 1,
    FOUR_NIU = 1,
    THREE_NIU = 1,
    TWO_NIU = 1,
    ONE_NIU = 1,
    NO_NIU = 1,     -- 没牛
}


--[[
--	牛牛扑克炸弹,排序对比函数
card1 = {
	 cardCounts = 1,
}	 cards = {}
-- @param card1 一个包含相同数字的数量以及卡牌的数组的对象
-- @param card2 一个包含相同数字的数量以及卡牌的数组的对象 通过size进行排行
-- @return 返回当前卡牌的组合的最大类型
]]

function _NNPoker.niuniu_comp(card1,card2)
	return card1.cardCounts > card2.cardCounts
end

function _NNPoker.niuniu_removeOpt(card1,card2)
	 if card1.cardId == card2.cardId and card1.cardSuit == card2.cardSuit then
	 	-- 说明存在 则返回nil
	 	return nil;
	 end
	 return card1;
end

--[[
	返回所有3+2的牌,如果3 不为牛,则不需要不加入数组
	牌为5张
 
-- @param cards 用户5张卡牌的数组 扑克牌必须排序
-- @return 返回当前卡牌的组合的最大类型
]]
function  _NNPoker.C_M_3(srcTable)
    -- body
    local m = table.getn(srcTable);
    local n = 3;
    local index = 1;
    local tDes = {};
    local tDes2 = {};
    
    for index1 = 1, m-n+1 , 1 do
        for index2 = index1 + 1, m-1, 1 do
            for index3 = index2 + 1, m, 1 do 
                tDes[index] =  {
                   srcTable[index1],srcTable[index2],srcTable[index3]
                };  
                local arrayIndexs = {1,2,3,4,5} 
                arrayIndexs[index1] = nil;
                arrayIndexs[index2] = nil;
                arrayIndexs[index3] = nil;
                local tDes2Index = 1;

               	tDes2[index] = {};
                		 
                for i = 1,5,1 do
                	if arrayIndexs[i] then 
                		tDes2[index][tDes2Index] = srcTable[i];
                		tDes2Index = tDes2Index + 1;
                	end 
                end
                
                index = index + 1;
            end
        end
    end
    return tDes, tDes2;
end 

--[[
	计算牌的大小,返回最大组合的牛牌组合
	牌为5张
 
-- @param cards 用户5张卡牌的数组 扑克牌必须排序
-- @return 返回当前卡牌的组合的最大类型
]]

function _NNPoker:getCardsMaxType(_cards)

    -- 排序依次poker牌
    local cards = table.clone(_cards)
    table.sort(cards,self.card_comp);
	-- 首先删除卡牌中的10以上的卡牌
	local tenCards = 0; 
	local newCards = {};
	-- 牛牌记录
	local niuCards = {};
	local niuCardsIndex = 1;	-- 数组index
	-- 非牛牌记录
	local noniuCards = {}; 
	local noniuCardsIndex = 1;

	-- 花牌记录
	local huaCards = {}
	local huaCardsIndex = 1;

	-- 用于炸弹的判断记录
	local cardsNumb = {};
	local idTypes = 0;
	local lastId = nil;
	for i=1,5,1 do
		-- 判断炸弹的依赖
		local cardId = cards[i].cardId;
		if not lastId or lastId ~=  cardId then 
			idTypes = idTypes + 1;
			cardsNumb[idTypes] = { cardCounts = 1};
			cardsNumb[idTypes].cards = {};
			cardsNumb[idTypes].cards[cardsNumb[idTypes].cardCounts] = cards[i];
			--ngx.say("---------------分割线----------------",idTypes," ",cardsNumb[idTypes].cardCounts);
		else   
			cardsNumb[idTypes].cardCounts = cardsNumb[idTypes].cardCounts + 1;
			cardsNumb[idTypes].cards[cardsNumb[idTypes].cardCounts] = cards[i];
			--ngx.say("---------------分割线----------------",idTypes," ",cardsNumb[idTypes].cardCounts);
		end
		if cards[i].cardId > 10 then 
			huaCards[huaCardsIndex] = cards[i];
			huaCardsIndex = huaCardsIndex + 1;
		end

		if cards[i].cardId > 9 then 
			niuCards[niuCardsIndex] = cards[i];
			niuCardsIndex = niuCardsIndex + 1;
		else 
			noniuCards[noniuCardsIndex] = cards[i];
			noniuCardsIndex = noniuCardsIndex + 1;
		end
		lastId = cardId;
	end

	--ngx.say("---------------分割线----------------");
		-- 将特殊的情况先判断和排除 
    table.sort(cardsNumb,_NNPoker.niuniu_comp); 
    -- 判断10小
    if table.getn(noniuCards) == 5 then
    	local sumRes = 0;
    	for i=1,5,1 do
    		sumRes = sumRes + cards[i].cardId;
    	end
    	if sumRes < 10 then
    		return  CARDS_TYPE.LESS_TEN ,cards, cards
    	end 
    end 
    --[[]]
    -- 判断炸弹
    if cardsNumb[1].cardCounts == 4 then
    	-- 当前是炸弹 
    	newCards = cardsNumb[1].cards;
    	table.arrayMerge(newCards,cardsNumb[2].cards);
    	return CARDS_TYPE.BOMB ,newCards, newCards
    end

    -- 判断金花
    if table.getn(huaCards) == 5 then  
    	return CARDS_TYPE.FIVE_JINHUA ,cards, cards
    end
    -- 判断银花
    if table.getn(huaCards) == 4  and table.getn(niuCards) == 5 then  
    	return CARDS_TYPE.FOUR_JINHUA, cards, cards
    end

    -- 判断5张10点 牛牛 
    if table.getn(niuCards) == 5 then  
    	return CARDS_TYPE.TEN_NIU, cards, cards
    end
    -- 判断 4个点数为10 返回对应的几牛  
    if table.getn(niuCards) == 4 then  
    	local yushu = noniuCards[1].cardPoint;
    	return CARDS_TYPE[CARDS_TYPE_MAP[yushu]], cards, cards
    end

    -- 如果是3个10点牌则进行直接牛牛判断 -- 存在牛牛的牌形
 	if table.getn(niuCards) == 3 then
 		local niushu = noniuCards[1].cardPoint + noniuCards[2].cardPoint;
 		local yushu = niushu %10;
 		if yushu == 0 then
 			return CARDS_TYPE.TEN_NIU, cards, cards
 		end 
    	return CARDS_TYPE[CARDS_TYPE_MAP[yushu]], cards, cards
    end

   
    -- 其余的组合情况通过系统穷举法,取出三张和剩下2张的组合配置
    -- 首先记录下三张为10的情况,如果三张为牛,则将该牌记录下来,计算后面的两张牌的组合数值 
    local t3Cards ,t2Cards = _NNPoker.C_M_3(cards);
    local t3Index = 1;
    local cardsType = {};
    --ngx.say(table.getn(t3Cards)," ",table.getn(t2Cards))

    for i = 1,table.getn(t3Cards),1 do
    	local cards3Tem = t3Cards[i];
		local cards2Tem = t2Cards[i];
        local card31 =   cards3Tem[1].cardId > 10 and 10 or cards3Tem[1].cardId;
        local card32 =   cards3Tem[2].cardId > 10 and 10 or cards3Tem[2].cardId;
        local card33 =   cards3Tem[3].cardId > 10 and 10 or cards3Tem[3].cardId;
        local card21 =   cards2Tem[1].cardId > 10 and 10 or cards2Tem[1].cardId;
        local card22 =   cards2Tem[2].cardId > 10 and 10 or cards2Tem[2].cardId;

    	local t3Sum = card31 + card32  + card33; 
    	-- 如果三张牌不是10的倍数 则返回说明该牌不是 牛牌
    	local yushu3 = t3Sum % 10; 
    	if yushu3 ~= 0 then 
    		cardsType[t3Index] = CARDS_TYPE.NO_NIU;  
    	else
    		--[[ ]]
    		-- 等于0 说明有牛 ,判断后两位是否为10的倍数
    		--local card21 =   t2Cards[1].cardId > 10 and 10 or t2Cards[1].cardId;
            --local card22 =   t2Cards[2].cardId > 10 and 10 or t2Cards[2].cardId;

    		local t2Sum = card21 +  card22;
    		local yushu2 = t2Sum % 10;
    		if yushu2 ~= 0 then
    			cardsType[t3Index] = CARDS_TYPE[ CARDS_TYPE_MAP[yushu2] ]
    		else
    			-- 如果前后都为牛,则 本牌为牛牛
    			cardsType[t3Index] =  CARDS_TYPE.TEN_NIU;
    			-- 牛牛的话 直接返回
    			return CARDS_TYPE.TEN_NIU, {t3Cards[i][1],t3Cards[i][2],t3Cards[i][3] ,t2Cards[i][1],t2Cards[i][2]}, cards;
    		end 
    	end 
        -- local cards = table.clone(cards3Tem);
        -- table.arrayMerge(cards,cards2Tem)
        -- ngx.log(ngx.ERR,cjson.encode(cards))
    	t3Index = t3Index + 1;
    end 
     
 	local maxType = nil;
    local maxIndex = 1;
    for i = 1,table.getn(cardsType),1 do
    	if not maxType  then 
    		maxType = cardsType[i];
    	else
    		 
    		if maxType < cardsType[i] then 
    			maxType = cardsType[i];
    			maxIndex = i;
            elseif maxType < cardsType[i] then
                -- 如果牌型相同,相比更大的牌型进行返回
                local maxCards = table.clone(t3Cards[maxIndex])
                table.arrayMerge(maxCards,t2Cards[maxIndex])

                local curCards = table.clone(t3Cards[i])
                table.arrayMerge(curCards,t2Cards[i])

                local isG = self.jugeCards(maxCards,curCards)

                if isG < 0 then 
                    maxType = cardsType[i];
                    maxIndex = i;
                end
    		end  
    	end 
    end



    if maxType == CARDS_TYPE.NO_NIU then return maxType,cards , cards end;
    
    return maxType,{t3Cards[maxIndex][1],t3Cards[maxIndex][2],t3Cards[maxIndex][3] ,t2Cards[maxIndex][1],t2Cards[maxIndex][2]}, cards; 
 --[[]]
end

--[[
	玩家两组牌 返回当前玩家最大的组合卡牌
	牌为5张
 
-- @param cards 用户5张卡牌的数组 扑克牌必须排序
-- @return 返回当前卡牌的组合的最大类型
    返回当前卡牌的牌型,
]]
local CARDS_COMPARE =  Poker.CARDS_COMPARE;
function _NNPoker:JugeCards(cards1,cards2)
	local cards1Type , resCards1, cards1Sorted = self:getCardsMaxType(cards1)
	local cards2Type , resCards2, cards2Sorted = self:getCardsMaxType(cards2) 


    if cards1Type ~= cards2Type then
        return cards1Type > cards2Type and CARDS_COMPARE.OVER or CARDS_COMPARE.UNDER ,cards1 , cards2, cards1Type, cards2Type ;
    else
        if cards1Sorted[1].cardId ~= cards2Sorted[1].cardId then
            return cards1Sorted[1].cardId > cards2Sorted[1].cardId and CARDS_COMPARE.OVER or CARDS_COMPARE.UNDER, cards1, cards2, cards1Type, cards2Type ;
        else
            return cards1Sorted[1].cardSuit > cards2Sorted[1].cardSuit and CARDS_COMPARE.OVER or CARDS_COMPARE.UNDER, cards1, cards2, cards1Type, cards2Type ;
        end
    end

 --    local sameCards1 = table.clone(resCards1)
 --    table.sort(sameCards1,self.PokerCards.card_comp)
 --    local sameCards2 =table.clone(resCards2)
 --    table.sort(sameCards2,self.PokerCards.card_comp)
	-- if cards1Type ~= cards2Type then
	-- 	return cards1Type > cards2Type and CARDS_COMPARE.OVER or CARDS_COMPARE.UNDER ,resCards1 , resCards2 ,,cards1Type, cards2Type ;
	-- else
	-- 	if sameCards1[1].cardId ~= sameCards2[1].cardId then
	-- 		return sameCards1[1].cardId > sameCards2[1].cardId and CARDS_COMPARE.OVER or CARDS_COMPARE.UNDER, resCards1 ,resCards2, cards1Type, cards2Type ;
	-- 	else
	-- 		return sameCards1[1].cardSuit > sameCards2[1].cardSuit and CARDS_COMPARE.OVER or CARDS_COMPARE.UNDER, resCards1, resCards2, cards1Type, cards2Type ;
	-- 	end
	-- end
end

--[[
-- 将 用户底牌和公共牌 返回所有可组合的对象列表
-- example 
    比较玩家玩家大小
-- @param player1 玩家的数据结构
-- @param player2 玩家的数据结构
-- @return 返回大的玩家
--]]
function _NNPoker:JugePlayerCards(player1,player2)
    local cards1 = player1.cards;
    local cards2 = player2.cards;
    local isPlayer1
    isPlayer1, player1.cards, player2.cards, player1.cardType, player2.cardType = self:JugeCards(cards1,cards2)
    -- if CARDS_COMPARE.OVER == isPlayer1 then 
    --     return player1
    -- elseif CARDS_COMPARE.UNDER == isPlayer1 then
    --     return player2
    -- else
    --     return player1
    -- end
     return isPlayer1
end
--[[
-- 返回玩家队列中最大的玩家信息, 如果函数返回nil表明都是皇家同花顺,否则返回的为最大的玩家的信息,
-- 取桌面上的公共牌来组合最大的个人牌的时候也调用该函数,只是所有的playerid为相同而已
-- example
    
    
-- @param players 玩家数组
--]]
function _NNPoker:Juge(players)
    local len = table.getn(players);
    -- for i=1,len,1 do
    --     local player = players[i];
    --     player.cardType = self:getCardsMaxType(player.cards);
    -- end
    local maxPlayer = nil;
    for i=1,len,1 do
        local player = players[i];
        if not maxPlayer then 
            maxPlayer = player;
        else
            maxPlayer = self:JugePlayerCards(maxPlayer,player)
        end
    end
    return maxPlayer;
end

_NNPoker.__index = _NNPoker;


--[[
    返回当前cards数组中最大的牌的位置
]]
function _NNPoker:JugeCardsArray(cardsArray)
    local len = table.getn(cardsArray); 
    local mIndex = 1;
    local maxCards = cardsArray[1];
    for i=2,len,1 do 
        local isCards1, cards1, cards2, ct1, ct2 = self:JugeCards(maxCards,cardsArray[i]) 
        if  isCards1 < 0 then
            maxCards = cardsArray[i];
            mIndex = i;
        end
    end 
    
    return mIndex;
end

--[[
--  本平台的玩法allin玩法，即一次性将所有的卡牌发放出来,保持某种重要的限制,系统可以默认调用本方法
--  系统可以进行押注庄家牌型,散家的胜利或者失败,默认定义AP 为庄家,BP,CP,DP表示福禄寿三家
--  平台存在一个特殊处理,即矫正标志
--  该平台的矫正标志说明如下:

-- example
    local texasHoldem = require "game.TexasHoldem.TexasHoldem":new()
    local poker = texasHoldem.PokerImpl;
-- @param _ap  压庄家牌型的数据,该数据为table表,以牌型,为key,数据为押注额Money,赔率Odds 结构如下:
                local _ap = {betTypeSet={RoyalFlush={Money=1000,Odds=6} ,StrainghtFlush={Money=1000,Odds=5} } } 
-- @param _bp  散家牌型,该结构主要该散家被押注的情况,数据结构如下
                local _bp = {win={Money=1000,Odds=6},lose={Money=1000,Odds=5}}
-- @param _cp   同_bp
-- @param _dp   同_bp
-- @param _isLower 是否低于资金池标志,如果低于执行修正算法,如果没有,继续进行
-- @param _bili _矫正比例
-- @return  
--]]
function _NNPoker:allinmodel(_ap,_bp,_cp,_dp,_isLower,_bili)
    -- body
  
        -- 正常业务逻辑
        -- 给所有玩家发送所有手牌 
        _ap.cards = self:getMutiCards(5);
        _bp.cards = self:getMutiCards(5);
        _cp.cards = self:getMutiCards(5);
        _dp.cards = self:getMutiCards(5);
 
        -- self:getUsersMaxCards(_ap.handCards,publicCards);
        -- 获得各个玩家最大的卡牌
        -- _ap.cardsType, _ap.cards = self:getCardsMaxType(_ap.cards); 
        -- _bp.cardsType, _bp.cards = self:getCardsMaxType(_bp.cards);
        -- _cp.cardsType, _cp.cards = self:getCardsMaxType(_cp.cards);
        -- _dp.cardsType, _dp.cards = self:getCardsMaxType(_dp.cards);
    
    if _isLower then
        -- 修正业务逻辑
        -- 计算当前猜牌型的损失数据
        -- local resData = self:computeBetResult(_ap,_bp,_cp,_dp) 
        -- 如果亏钱则需要执行一次调整,即获取概率是否需要调整,如果本次需要调整,则进行调整

        -- if resData < 0 then
        --     -- 获取当前矫正规则,当前矫正规则为

        -- end
        -- 获取随机
        local randomIndex = math.random(1, 100);
        -- 大于说明走的是低概率 小于说明走的是矫正路线
        if randomIndex < _bili then
             local cardsArray = {
                _ap.cards,_bp.cards,_cp.cards,_dp.cards 
            }
            local cindex = self:JugeCardsArray(cardsArray)
            if cindex ~= 1 then
                local tem = { cards=_ap.cards, cardType = _ap.cardType, handCards = _ap.handCards}
                local list={_bp,_cp,_dp};
                _ap.cards = list[cindex - 1].cards
                _ap.cardType = list[cindex - 1].cardType
                _ap.handCards = list[cindex - 1].handCards

                list[cindex - 1].cards = tem.cards;
                list[cindex - 1].cardType = tem.cardType;
                list[cindex - 1].handCards = tem.handCards; 
            end 
        end 
    end
    
end 
 
--[[
-- 创建一副牛牛游戏的实例对象,包含牛牛的发牌,牌型比较，玩家比较等
--  
-- example
    local _NNPoker = require "game.niuniu.niuniu":new()
    
-- @param   
-- @return 返回当前牛牛游戏的当前对象
--]] 
function _NNPoker:new()
    local niuniuImpl =  setmetatable({}, _NNPoker);
    -- 创建poker 对象,每局卡牌进行数据new
    niuniuImpl.Cards = niuniuImpl:newCards(1,false);
    return niuniuImpl;
end

return _NNPoker

