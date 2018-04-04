--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:baccarat.lua
--	版本号: 0.2 增加多宝百家乐算法
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  百家乐游戏的封装,棋牌房间调用时需要首先调用一次new对象,创建新对象之后,对象中包含棋牌的扑克牌集合
--  通过扑克牌集合封装类进行发牌等基础操作
--  百家乐卡牌的玩法预定义
--  定义卡牌组合的类型,卡牌的大小比较,以及赔率倍数等
--  同时修改该扑克牌的状态防止系统被攻击或者串改

--]]



--[[
--  百家乐棋牌的结构如下:
	_Baccarat = {
		bankerCards = {},	-- 	庄家牌数组
		playerCards = {},	--	闲家牌数组 
		betResMap = {},		-- 当前牌局的组合情况
	}
	
]]

local Poker = require "game.poker.Poker"
local cjson = require "cjson"


local _Baccarat = {}  
_Baccarat.__index =  _Baccarat
setmetatable(_Baccarat, Poker)
 
 -- very import 

_Baccarat.CARD_POINT =  table.clone(Poker.CARD_POINT);
_Baccarat.CARD_POINT.KING 	= 0;
_Baccarat.CARD_POINT.QUEEN 	= 0;
_Baccarat.CARD_POINT.JACK 	= 0;
_Baccarat.CARD_POINT.TEN 	= 0;


-- 多宝百家乐的类型同时添加进来,cardsType 的map信息即通过获得牌信息和比较的时候进行状态值的返回

local BET_TYPE = {   
	BANKER_WIN 				= 1,		-- 庄赢
	PLAYER_WIN 				= 2,		-- 闲赢
	TIE 					= 3,			--  和
    PAIRS                   = 4,    -- 对子
	BANKER_PAIRS 			= 4,	-- 庄对子 
	PLAYER_PAIRS 			= 5,	-- 闲对子

	ADD_CARD 				= 6,		-- 是否增牌 作为压大小所用,4表示小,5/6表示大 


	-- 新玩法的状态判断
	THREE_KIND 				= 7,		-- 有一家三张一样的

    TWO_PAIRS 				= 8,  	-- 	两对
    STRAIGHT 				= 9,  	--	顺子
	FLUSH 					= 10,			--	同花
	FULL_HOUSE 				= 11,	-- 	葫芦
	FOUR_OF_AKIND 			= 12,	--	四条
	STRAINGHT_FLUSH 		= 13,	-- 	同花顺
	ROYAL_FLUSH				= 14,	--	皇家同花顺
	FIVE_KIND  				= 15,	-- 	五条
	SIX_KIND 				= 16,		--	六条 
    ORDINARY = 17,  -- 高牌
}

_Baccarat.BET_TYPE = BET_TYPE


-- 押注类型 MAP
local BET_KEYS_MAP = {   
	"BANKER_WIN" ,			-- 	= 1,		-- 庄赢
	"PLAYER_WIN" ,			-- 	= 2,		-- 闲赢
	"TIE" , 					-- = 3,			--  和
	"PAIRS" , 			-- = 4,	-- 庄对子 BANKER_PAIRS
	"PLAYER_PAIRS" , 			-- = 5,	-- 闲对子
 
	"ADD_CARD" , 				-- = 6,		-- 是否增牌 作为压大小所用,4表示小,5/6表示大  
	-- 新玩法的状态判断-- 
	"THREE_KIND" , 				-- = 7,		-- 有一家三张一样的 
    "TWO_PAIRS" ,				-- = 8,  	-- 	两对
    "STRAIGHT" , 				-- = 9,  	--	顺子
	"FLUSH" , 					-- = 10,			--	同花
	"FULL_HOUSE" , 				-- = 11,	-- 	葫芦
	"FOUR_OF_AKIND" , 			-- = 12,	--	四条
	"STRAINGHT_FLUSH" , 		-- = 13,	-- 同花顺
	"ROYAL_FLUSH",				-- = 14,	-- 皇家同花顺
	"FIVE_KIND" ,  				-- = 15,	-- 	五条
	"SIX_KIND" , 				-- = 16,		--	六条  
    "ORDINARY"
}

_Baccarat.BET_KEYS_MAP = BET_KEYS_MAP

--	押注倍率的数组
local BET_ODDS_MAP = {   
	BANKER_WIN 				= 1,		-- 庄赢
	PLAYER_WIN 				= 1,		-- 闲赢
	TIE 					= 8,			--  和
	BANKER_PAIRS 			= 11,	-- 庄对子
	PLAYER_PAIRS 			= 11,	-- 闲对子

	ADD_CARD 				= 1,		-- 是否增牌 作为压大小所用,4表示小,5/6表示大   
	-- 新玩法的状态判断
    TWO_PAIRS 				= 8,  		-- 	两对


    THREE_KIND              = 15,       --  有一家三张一样的  
    FULL_HOUSE              = 60,       --  葫芦 
	FLUSH 					= 75,		--	同花
    STRAIGHT 				= 100,  	--	顺子
	FOUR_OF_AKIND 			= 200,		--	四条
	FIVE_KIND  				= 2000,		-- 	五条
	STRAINGHT_FLUSH 		= 6800,		-- 同花顺
	ROYAL_FLUSH				= 28000,	-- 皇家同花顺
	SIX_KIND 				= 66000,	--	六条  
    ORDINARY = 1,

}

_Baccarat.BET_ODDS_MAP = BET_ODDS_MAP

_Baccarat.CARDS_TYPE_DESCRIPTION = {  
	"对子" ,		-- 对子 
	"豹子" ,		--三张一样的 
	"增牌" ,
}
 



local function sortIdMap(id1,id2)
	return id1.size > id2.size
end

--[[
	首先判断是否为6条,首先是判断6张一样

    判断是否为同花,如果为同花,返回当前同花类型
    如果非同花顺,则返回其他相应的牌的状态
    皇家同花顺(royal flush)：由AKQJ10五张组成，并且这5张牌花色相同 　　  
    同花顺(straight flush)：由五张连张同花色的牌组成 　　
    4条(four of a kind)：4张同点值的牌加上一张其他任何牌 　　
    满堂红(full house)（又称“葫芦”）：3张同点值加上另外一对 　　
    同花(flush)：5张牌花色相同，但是不成顺子 　　
    顺子(straight)：五张牌连张，至少一张花色不同 　　
    3条(three of a kind)：三张牌点值相同，其他两张各异 　　
    两对(two pairs)：两对加上一个杂牌 　　
    一对(one pair)：一对加上3张杂牌 　　
    高牌(high card)：不符合上面任何一种牌型的牌型，由单牌且不连续不同花的组成
 
    遍历过程进行多种状态遍历 
    1 是否同色 
    2 是否顺子 
    3 是否有4+1
    4 是否3+2 
    5 是否3+1+1 
    6 是否2+2+1
    7 是否2+1+1+1
    8 1+1+1+1+1 


-- @param cards 用户5张卡牌的数组
-- @return 返回用户的卡牌类型,用户新的卡牌顺序
]] 
function _Baccarat:getCardsType(_cards)
        
        -- 排序依次poker牌
         local cards = table.clone(_cards)
        table.sort(cards,self.card_comp);
        local len = table.getn(cards);

        -- 通过花色,卡牌id,然后根据牌的组合关系进行各种类型的判断与处理
        local cardsProperty = {
        	cardIdMap = {},		-- cardsid形成的map数据结构
        	cardSuitMap = {},	-- 花色的形成的map数据结构
        	isSTRAIGHT = true,	-- 形成顺子
    	}

    	-- id 当前数量
    	local lastCard = nil
    	local cardIdSize = 0
    	local cardSuitSize = 0
    	for i = 1,i < len do
    		
    		local card = cards[i]

    		-- 首先是花色列表 
    		if not cardsProperty.cardSuitMap[""..card.cardSuit] then 
    			 cardsProperty.cardSuitMap[""..card.cardSuit]  = { size = 0,cardSuit = card.cardSuit }
    			 cardSuitSize = cardSuitSize + 1
    		end
    		cardsProperty.cardSuitMap[""..card.cardSuit].size =  cardsProperty.cardSuitMap[""..card.cardSuit].size + 1

    		-- 首先 是卡牌id数量统计 
    		if not cardsProperty.cardIdMap[""..card.cardId] then 
    			 cardsProperty.cardIdMap[""..card.cardId]  = { size = 0,cardId = cardId}
    			 cardIdSize = cardIdSize + 1
    		end
    		cardsProperty.cardIdMap[""..card.cardId].size =  cardsProperty.cardIdMap[""..card.cardId].size + 1

    		-- 计算 
    		if i == 1 then 
    			lastCard = card 
    		else 
    			if lastCard.cardPoint - card.cardPoint ~= 1 then 
    				cardsProperty.isSTRAIGHT = false
    			end
    		end 
    	end

    	-- 判断六条
    	if len == 6 and cardIdSize == 1	then
    		self.betResMap.SIX_KIND = true
    		return BET_TYPE.SIX_KIND,_cards
    	end
    	-- 进行一次排序
    	table.sort(cardsProperty.cardIdMap,cardIdSize)
    	-- 五条
    	if cardsProperty.cardIdMap[1] == 5 then
    		-- 是否需要排序
    		if len == 5 then
    		else
    			if cards[1].cardId == cards[2].cardId then 
    				self.betResMap.FIVE_KIND = true
    				return BET_TYPE.FIVE_KIND,cards
    			else
    				self.betResMap.FIVE_KIND = true
					return BET_TYPE.FIVE_KIND,{cards[2],cards[3],cards[4],cards[5],cards[6],cards[1]}
				end
			end 
    	end

    	-- 判断皇家同花顺 和 同花顺
    	if cardsProperty.isSTRAIGHT == true and cardSuitSize == 1  then 
    		if cards[1].cardId == CARD_ID_TYPE.ACE then 
    			self.betResMap.ROYAL_FLUSH = true
    			return BET_TYPE.ROYAL_FLUSH,cards 
    		else
    			self.betResMap.STRAINGHT_FLUSH = true
    			return BET_TYPE.STRAINGHT_FLUSH,cards
    		end
    	end

    	-- 判断四条 

        local cardtype_param = {
	        isSIX = {result = false,},	-- 是否有六条	当前 有效的cardId 数量
	        isFIVE = {result = false,},	-- 是否有五条
	        isFLUSH = {result = false , suitSize = 0},    -- 花色统计 suit 数量为1
	        isSTRAIGHT = {result = true , maxcardId = 0},              -- 是否 a a-1 a-2 a-3 a-4
	        isFourOAK = {result = false , maxcardId = 0},               -- 是否 id 计数数组是否为2 其中一个为4,另一个为1, 只需要判断4个相同牌的那个大小
	        isFULL_HOUSE = {result = false , maxcardId = 0},             -- 是否计数数组为2 并且为3,2, 只需要判断3个相同牌的那个大小
	        isThreeOAK = {result = false , maxcardId = 0},              -- 是否为分类数组3，并且其中有一个为3,只需要判断3个相同牌的那个大小
	        isTWO_PAIRS = {result = false  },                  -- 是否为分类数组3，并且其中两个为2,需要判断最大的2,然后判断第二个2,最后判断最后一个1
	        isOnePair = {result = false  },                  -- 是否分类数组为4，需要判断第一个2,同类型需要判断第一个2,然后按顺序判断最大的值截止
	        isHighCard = {result = false },
	        status = {},
        }
        local suitTemp = nil;
        -- 用户牌中相同牌形的排序
        -- 减少判断逻辑
        local cardIdIndex = 1;
        local cardIdTypes = 0;
        for i = 1,len,1 do 
            local card = cards[i];
            -- 花色判断 ---------begin-----------
           if not suitTemp then 
                suitTemp = card.cardSuit;
            elseif suitTemp ~= card.cardSuit then
                cardtype_param.isFLUSH.suitSize = 2; 
           end
           -- ngx.say("suit is "..suitTemp.." "..card.Suit)
           if i == len and cardtype_param.isFLUSH.suitSize == 0 then 
                cardtype_param.isFLUSH.suitSize = 1;
                cardtype_param.isFLUSH.result = true; 
           end
           -- 获得判断 ---------end-----------
           -- 顺子判断 ---------begin---------
           if i > 1 then 
                local lastCard = cards[i - 1];
                if lastCard.cardPoint - card.cardPoint ~= 1 then
                    cardtype_param.isSTRAIGHT.result = false;
                end
           end
           -- 顺子判断 ---------end-----------

           -- N+N 判断 ---------begin---------
           if not cardtype_param.status[cardIdIndex] then
                cardtype_param.status[cardIdIndex] = {
                    cardSize = 1,
                    cardPoint = cards[i].cardPoint,
                    cards = { 
                        cards[i]
                    }
                } 
            else
                if cardtype_param.status[cardIdIndex].cardPoint == cards[i].cardPoint then
                    local _temSize = cardtype_param.status[cardIdIndex].cardSize + 1;
                    cardtype_param.status[cardIdIndex].cardSize = _temSize;
                    cardtype_param.status[cardIdIndex].cards[_temSize] = cards[i];
                else
                    cardIdIndex = cardIdIndex + 1;
                    cardtype_param.status[cardIdIndex] = {
                        cardSize = 1,
                        cardPoint = cards[i].cardPoint,
                        cards = { 
                            cards[i]
                        }
                    } 
                end
            end
        end  
        --[[end return cardtype_param;--]]  
        -- 排序一次 进行大小获取
        table.sort(cardtype_param.status,_TexasHoldem.cardsTypeCmp);
        local statusArray = cardtype_param.status;
        local newCards = nil;
        -- ngx.say(cjson.encode(cardtype_param.status))
       
        -- 顺序进行判断
        if cardIdIndex == 2 then
            -- fouroak or fullhouse
            if statusArray[1].cardSize == 4 then 
                cardtype_param.isFourOAK.result = true;
                -- cardtype_param.isFourOAK.maxcardId = 
                elseif statusArray[1].cardSize == 3 then 
                cardtype_param.isFULL_HOUSE.result = true;
            end
        elseif cardIdIndex == 3 then
            -- 2+2+1 or 3+1+1
            if statusArray[1].cardSize == 3 then
            cardtype_param.isThreeOAK.result = true;
            else
                cardtype_param.isTWO_PAIRS.result = true;
            end
        elseif cardIdIndex == 4 then
            -- 2+1+1+1
                cardtype_param.isOnePair.result = true;
        else
            -- 1+1+1+1+1+1
                cardtype_param.isHighCard = true;
        end
          
        -- 4 + 1 判断 ---------end-----------
 
        local newCards = nil;
        -- 判断牌的状态
        local cardTypeResult = nil;
        if cardtype_param.isFLUSH.result and cardtype_param.isSTRAIGHT.result then -- 是否为同花顺
            if cards[1].cardId == Poker.CardIDType.Ace then      -- 是否为大同花顺
                cardTypeResult = CARDS_TYPE.ROYAL_FLUSH; 
            else
                cardTypeResult =  CARDS_TYPE.STRAINGHT_FLUSH;
            end
        elseif  cardtype_param.isFourOAK.result then               -- 是否为4+1
                cardTypeResult = CARDS_TYPE.FOUR_OF_AKIND;
                local card1Temp = cards[1];
                -- 获取第三张牌
                local card3 = cards[3];
                if card3.cardId ~= card1Temp.cardId then
                    -- 说明第一张是不同数字的 重新排序
                    newCards = {
                        cards[2],cards[3],cards[4],cards[5],cards[1],
                    };
                end


        elseif  cardtype_param.isFULL_HOUSE.result then               -- 是否为3+2
                cardTypeResult = CARDS_TYPE.FULL_HOUSE;
                 local card1Temp = cards[1];
                -- 获取第三张牌
                local card3 = cards[3];
                if card3.cardId ~= card1Temp.cardId then
                    -- 说明第一张是不同数字的 重新排序
                    newCards = {
                        cards[3],cards[4],cards[5],cards[1],cards[2],
                    };
                end


        elseif  cardtype_param.isFLUSH.result then               -- 是否为同花
                cardTypeResult = CARDS_TYPE.FLUSH;
        elseif  cardtype_param.isSTRAIGHT.result then               -- 是否为顺子
                cardTypeResult = CARDS_TYPE.STRAIGHT;
        elseif  cardtype_param.isThreeOAK.result then               -- 是否为3+1+1
                cardTypeResult = CARDS_TYPE.THREE_OF_AKIND;
                if cards[2].cardId == cards[4].cardId then
                    newCards = {
                        cards[2],cards[3],cards[4],cards[1],cards[5],
                    };
                elseif cards[3].cardId == cards[5].cardId then
                    newCards = {
                        cards[3],cards[4],cards[5],cards[1],cards[2],
                    };
                end


        elseif  cardtype_param.isTWO_PAIRS.result then               -- 是否为2+2+1 
                cardTypeResult = CARDS_TYPE.TWO_PAIRS;
                newCards = {
                        statusArray[1].cards[1],
                        statusArray[1].cards[2],
                        statusArray[2].cards[1],
                        statusArray[2].cards[2],
                        statusArray[3].cards[1],
                    };


        elseif  cardtype_param.isOnePair.result then               -- 是否为2+1+1+1 
                cardTypeResult = CARDS_TYPE.ONE_PAIRS;
                -- 获取当前多组cards 的数组信息
                  newCards = {
                        statusArray[1].cards[1],
                        statusArray[1].cards[2],
                        statusArray[2].cards[1],
                        statusArray[3].cards[1],
                        statusArray[4].cards[1],
                    };
        else                                               
                -- 是否为1+1+1+1+1
                cardTypeResult = CARDS_TYPE.HIGHT_CARD;
        end
 
        --[[ 2+2+1 2+1+1+1 需要重新把牌的位置进行排序]]
        if not newCards then newCards = cards end

        -- 排序处理结束
        return cardTypeResult,newCards;
end


--[[
-- 获得当前卡牌的有效点书
-- @param _cards 用户2张或者3张牌
-- @return 返回当前卡牌的有效的点数,不同
]]
function _Baccarat:getCardsPoints( _cards )
	local len = table.getn(_cards)
	local cardPoint = 0
	local cardIdMap = {}
	local cardIdSize = 0
	for i=1,len do
		local card = _cards[i]
		cardPoint = cardPoint + card.cardPoint
		if not cardIdMap[""..card.cardId] then
			cardIdMap[""..card.cardId] = 1
			cardIdSize = cardIdSize + 1
		else
			cardIdMap[""..card.cardId] = cardIdMap[""..card.cardId] + 1
		end
	end
	local cardsType = nil
	local cardPoint1 = cardPoint % 10;

  	if cardIdSize == 1 and len == 2 then
     
    	-- 对子
    	cardsType = _Baccarat.BET_TYPE.PAIRS 
		 
	else
		cardsType = _Baccarat.BET_TYPE.ORDINARY
  	end
 
	return cardPoint1,cardsType
end
--[[
-- 获取百家乐用户牌的最终判断函数,该函数将返回系统的庄家赢/闲家赢/和,同时返回庄家的牌是否为对子,豹子,闲家的牌是否为对子或者豹子
-- @func 
-- example
-- @param _dealerCards 用户2张卡牌的数组  
-- @param _playerCards 玩家牌 2张
-- @return  庄/闲 的大小,庄的牌型,闲的牌型
]]
local CARDS_COMPARE =  Poker.CARDS_COMPARE;
function _Baccarat:jugeCards( _dealerCards ,_playerCards )
	-- body
	local dealerPoints  = self:getCardsPoints(_dealerCards)
	local playerPoints = self:getCardsPoints(_playerCards)
    self.playerPoints = playerPoints
    self.dealerPoints = dealerPoints
    -- ngx.say(self.playerPoints," ",self.dealerPoints)
	local resBL = nil
	if dealerPoints > playerPoints then
		resBL = CARDS_COMPARE.OVER
	elseif dealerPoints == playerPoints then
		resBL = CARDS_COMPARE.EQUAL
	else
		resBL = CARDS_COMPARE.UNDER
	end
	return resBL,playerPoints,dealerPoints
end
--[[
-- 返回卡牌的类型,卡牌可能为两张或者三张,默认发两张牌,前两张牌为8点或者9点,
-- 则返回当前不需要发牌,同时也将返回卡牌的牌型
-- example

-- @param _dealerCards 用户2张卡牌的数组  
-- @param _playerCards 玩家牌 2张
-- @return 返回当前庄家,闲家  是否需要发放第三张牌
]]
function _Baccarat:preTestDPCards( _dealerCards ,_playerCards)
	-- body
	local dealerPoints,dealerCardsType = self:getCardsPoints(_dealerCards)
	local playerPoints,playerCardsType = self:getCardsPoints(_playerCards)

   self.dealerCardsType = dealerCardsType
   self.playerCardsType = playerCardsType 
	-- 根据当前的牌返回当前点数和是否需要发牌
	-- 如果当前有一方牌为8点或9点 则返回双方都不需要发牌
	local isPlayerNeed = false
    local isDealerNeed = false
	if  playerPoints >= 8 or dealerPoints >= 8 then
		isPlayerNeed = false
		isDealerNeed = false
		return isPlayerNeed,isDealerNeed
	else
		if playerPoints == 6 or playerPoints == 7 then
			-- 如果玩家的总数是 6 或者 7，那么玩家就停止进牌
			isPlayerNeed = false 
		else      -- 小于6点必须补牌 
            _playerCards[3] = self:getCard()
            isPlayerNeed = true 
        end

        if not isPlayerNeed then
            if dealerPoints < 6 then
                isDealerNeed = true 
                _dealerCards[3] = self:getCard()
            else
                isDealerNeed = false
            end
            return isPlayerNeed,isDealerNeed 
        else -- 闲家补牌的情况下
             if dealerPoints < 3 then 
                isDealerNeed = true 
                _dealerCards[3] = self:getCard()
                return isPlayerNeed,isDealerNeed 
             end

             -- 庄家7点不用
            if dealerPoints == 7 then 
                isDealerNeed = false 
                return isPlayerNeed,isDealerNeed 
            end

            -- 庄家6点,玩家第三张 6 或者 7点,需要补牌
            if dealerPoints == 6 and (_playerCards[3].cardPoint == 6 or _playerCards[3].cardPoint == 7) then 
                isDealerNeed = true 
                _dealerCards[3] = self:getCard()
                return isPlayerNeed,isDealerNeed  
            end

            -- 庄家5点,玩家第三张 4-7点,需要补牌
            if dealerPoints == 5 and (_playerCards[3].cardPoint >= 4 and _playerCards[3].cardPoint <= 7) then 
                isDealerNeed = true 
                _dealerCards[3] = self:getCard()
                return isPlayerNeed,isDealerNeed 
            end
            
            -- 庄家4点,玩家第三张 2-7 点,需要补牌
            if dealerPoints == 4 and (_playerCards[3].cardPoint >= 2 and _playerCards[3].cardPoint <= 7) then 
                isDealerNeed = true 
                _dealerCards[3] = self:getCard()
                return isPlayerNeed,isDealerNeed 
            end

            -- 庄家3点,玩家第三张 2-7 点,需要补牌
            if dealerPoints == 3 and _playerCards[3].cardPoint ~= 8 then 
                isDealerNeed = true 
                _dealerCards[3] = self:getCard()
                return isPlayerNeed,isDealerNeed 
            end

            return isPlayerNeed,isDealerNeed   
        end  
	end

end



function _Baccarat:preTestDPCards_test( _dealerCards ,_playerCards)
    -- body
    local _playerCards1 = {_playerCards[1],_playerCards[2]}
    local dealerPoints,dealerCardsType = self:getCardsPoints(_dealerCards)
    local playerPoints,playerCardsType = self:getCardsPoints(_playerCards1)

   self.dealerCardsType = dealerCardsType
   self.playerCardsType = playerCardsType 
    -- 根据当前的牌返回当前点数和是否需要发牌
    -- 如果当前有一方牌为8点或9点 则返回双方都不需要发牌
    local isPlayerNeed = false
    local isDealerNeed = false
    if  dealerPoints >= 8 or playerPoints >= 8 then
        isPlayerNeed = false
        isDealerNeed = false 
        _playerCards[3] = nil
        return isPlayerNeed,isDealerNeed
    else
        if playerPoints == 6 or playerPoints == 7 then
            -- 如果玩家的总数是 6 或者 7，那么玩家就停止进牌
            isPlayerNeed = false 
            _playerCards[3] = nil
        else      -- 小于6点必须补牌 
            if not _playerCards[3] then
                _playerCards[3] = self:getCard()
            end
            isPlayerNeed = true 
        end
       
        -- 闲家不补牌 庄家小于6点 补牌
        if not isPlayerNeed then
            if dealerPoints < 6 then
                isDealerNeed = true 
                _dealerCards[3] = self:getCard()
            else
                isDealerNeed = false
            end
            return isPlayerNeed,isDealerNeed 
        else -- 闲家补牌的情况下
             if dealerPoints < 3 then 
                isDealerNeed = true 
                _dealerCards[3] = self:getCard()
                return isPlayerNeed,isDealerNeed 
             end

             -- 庄家7点不用
            if dealerPoints == 7 then 
                isDealerNeed = false 
                return isPlayerNeed,isDealerNeed 
            end

            -- 庄家6点,玩家第三张 6 或者 7点,需要补牌
            if dealerPoints == 6 and (_playerCards[3].cardPoint == 6 or _playerCards[3].cardPoint == 7) then 
                isDealerNeed = true 
                _dealerCards[3] = self:getCard()
                return isPlayerNeed,isDealerNeed  
            end
             
            -- 庄家5点,玩家第三张 4-7点,需要补牌
            if dealerPoints == 5 and (_playerCards[3].cardPoint >= 4 and _playerCards[3].cardPoint <= 7) then 
                isDealerNeed = true 
                _dealerCards[3] = self:getCard()
                return isPlayerNeed,isDealerNeed 
            end
              -- 庄家4点,玩家第三张 2-7 点,需要补牌
            if dealerPoints == 4 and (_playerCards[3].cardPoint >= 2 and _playerCards[3].cardPoint <= 7) then 
                isDealerNeed = true 
                _dealerCards[3] = self:getCard()
                return isPlayerNeed,isDealerNeed 
            end

            -- 庄家3点,玩家第三张 2-7 点,需要补牌
            if dealerPoints == 3 and _playerCards[3].cardPoint ~= 8 then 
                isDealerNeed = true 
                _dealerCards[3] = self:getCard()
                return isPlayerNeed,isDealerNeed 
            end

            return isPlayerNeed,isDealerNeed   
        end  
    end

end

--[[
-- 百家乐发牌相关,由于发牌需要预处理，故是否发牌则通过一次deal进行封装
-- 庄家和玩家各抽两张牌
-- 如果庄家或者玩家中任何一个总数是8或者9，双方就自动停止进牌。
-- 如果玩家的总数是 6 或者 7，那么玩家就停止进牌。
-- 如果玩家停止进牌，庄家的牌小于等于5就庄家继续进牌。
-- 如果玩家小于等于 5 ，玩家就自动进牌，庄家发给玩家第三张牌。
-- 如果玩家拿了第三张牌，那么庄家在以下情况的时候也要拿第三张牌：
-- 庄家的总点数是 0，1，2：庄家总是拿第三张牌。
-- 庄家的总点数是 3：如果玩家的第三张牌是除了8以外的任何牌，庄家就抽第三张牌。
-- 庄家的总点数是 4：如果玩家的第三张牌是 2-3-4-5-6-7 ，庄家就继续拿牌。
-- 庄家的总点数是 5：如果玩家的第三张牌是 4-5-6-7 ，庄家就继续拿牌。
-- 庄家的总点数是 6：如果玩家的第三张牌是 6-7，庄家就继续拿牌。
-- 庄家的总点数是 7：庄家停止进牌。
-- 发完最后一张牌后，谁的总点值靠近9就算谁胜。
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param  无
-- @return 返回本次发牌的用户的扑克牌信息以及,牌型以及大小关系的结果
--]]
function _Baccarat:deal( )
	-- body
	-- 第一步发四张牌，1,3 闲家, 2,4庄家
	self.DealerCards = {}
	self.PlayerCards = {}

	self.PlayerCards[1] = self:getCard()
	self.DealerCards[1] = self:getCard()
	self.PlayerCards[2] = self:getCard()
	self.DealerCards[2] = self:getCard()

	-- 返回当前的判断信息,如果需要发牌,系统则将牌发送到出来
	local resNeed1,resNeed2 = self:preTestDPCards(self.DealerCards,self.PlayerCards)
	 
	local res1,dealerPoints,playerPoints = self:jugeCards(self.DealerCards,self.PlayerCards)
	 
	local resultMap = {
		compareRes = res1,-- 比较大小 >0 庄家打,<0表示闲家大 =0 表示和
		dealerCardsType = self.dealerCardsType,
		playerCardsType = self.playerCardsType,
		dealerCards = self.DealerCards,
		playerCards = self.PlayerCards,
        playerPoints = playerPoints,
        dealerPoints = dealerPoints,
        player3Card = resNeed1,
        dealer3Card = resNeed2,
	}
	return resultMap
end


-- 百家了游戏分为庄（Bank）、闲（Play）、和（Tie）与对子（Pair）四门，
-- 另外部分度场有其独特的押注方式，比如大小、庄双、庄单、闲双、闲单。这里的庄、闲，
-- 并没有具体的含义，只是代表游戏的双方，和与对子则是为了增加娱乐性而设立的一个彩头。
-- 客人根据自己的想法可任意选择庄、闲、和与对子或其他任意一门下注

-- 由于每一手牌的目的就是要取得最接近9点的点数，
-- 所以最好就是第一次发牌首两张牌就取得共8或9点的点数，这就称为「天王」。
-- 若任何一方取得天王，双方必须停止拿牌。当然，唯一能打倒天王8点的就是天王9点。

--[[
-- 洗牌,重新组织牌
-- example
    
-- @param _pokerNums 扑克牌数量
-- @return  
--]]
function _Baccarat:shuffleCards(_pokerNums)
	 self.Cards = self:newCards(_pokerNums,false) 
end

function  _Baccarat:reset()
	
	for k,v in pairs( BET_TYPE  ) do
    	self.cardsType[k] = false
    end
end

--[[
-- 创建百家乐游戏实例,
-- 使用3～8副，每副52张纸牌，洗在一起，置於发牌盒中，由荷官从其中分发。
-- 各家力争手中有两三张牌总点数为9或接近9，K、Q、J和10都计为0，其他牌按牌面计点。
-- 计算时，将各家手中的牌值相加，但仅论最後一位数字。当场付、度、金最多者为庄家。
-- example
    local texasHoldem = require "game.TexasHoldem.TexasHoldem":new()
    local poker = texasHoldem.PokerImpl;
-- @param   
-- @return 返回当前百家乐游戏实例
--]] 

function _Baccarat:new(_pokerNums)
    
 	local baccaratImpl =  setmetatable({}, _Baccarat); 
     -- 创建poker 对象,每局卡牌进行数据new
    baccaratImpl:shuffleCards(_pokerNums)
    baccaratImpl.cardsType = {}
    for k,v in pairs( BET_TYPE  ) do
    	baccaratImpl.cardsType[k] = false
    end

    return baccaratImpl
end



return _Baccarat