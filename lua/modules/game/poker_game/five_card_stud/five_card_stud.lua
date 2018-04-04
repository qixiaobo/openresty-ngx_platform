
--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:five_card_stud.lua
--  
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  梭哈 游戏玩法相关的 封装,棋牌房间调用时需要首先调用一次new对象,创建新对象之后,对象中包含棋牌的扑克牌集合
--  通过扑克牌集合封装类进行发牌等基础操作
--  梭哈 扑克卡牌的玩法预定义
--  定义卡牌组合的类型,卡牌的大小比较,以及赔率倍数等
--  同时修改该扑克牌的状态防止系统被攻击或者串改
--]]
 
local Poker = require "game.poker.Poker"
local cjson  = require "cjson"


local _FiveCardStud = {}
-- 继承 poker
_FiveCardStud.__index = _FiveCardStud
 setmetatable(_FiveCardStud, Poker);
-- very import 
_FiveCardStud.CARD_POINT =  table.clone(Poker.CARD_POINT);
_FiveCardStud.CARD_POINT.ACE = 14;



_FiveCardStud.VERSION="0.1"
 --[[
    -- 牌型
    -- 皇家同花顺(royal flush)：由AKQJ10五张组成，并且这5张牌花色相同 　　  
    同花顺(straight flush)：由五张连张同花色的牌组成 　　
    4条(four of a kind)：4张同点值的牌加上一张其他任何牌 　　
    满堂红(full house)（又称“葫芦”）：3张同点值加上另外一对 　　
    同花(flush)：5张牌花色相同，但是不成顺子 　　
    顺子(straight)：五张牌连张，至少一张花色不同 　　
    3条(three of a kind)：三张牌点值相同，其他两张各异 　　
    两对(two pairs)：两对加上一个杂牌 　　
    一对(one pair)：一对加上3张杂牌 　　
    高牌(high card)：不符合上面任何一种牌型的牌型，由单牌且不连续不同花的组成
 ]]
_FiveCardStud.CARDS_TYPE = 
{
    -- ROYAL_FLUSH  = 10,
    STRAINGHT_FLUSH = 9,
    FOUR_OF_AKIND = 8,
    FULL_HOUSE = 7,
    FLUSH = 6,
    STRAIGHT = 5,
    THREE_OF_AKIND = 4,
    TWO_PAIRS = 3,
    ONE_PAIRS = 2,
    HIGHT_CARD = 1,
}
--[[
    德州扑克赔率相关定义，数据未定义,未来可以通过系统初始化获取
]]
_FiveCardStud.CARDS_TYPE_ODDS =
{
    -- ROYAL_FLUSH  = 10,
    STRAINGHT_FLUSH = 9,
    FOUR_OF_AKIND = 8,
    FULL_HOUSE = 7,
    FLUSH = 6,
    STRAIGHT = 5,
    THREE_OF_AKIND = 4,
    TWO_PAIRS = 3,
    ONE_PAIRS = 2,
    HIGHT_CARD = 1,
}

_FiveCardStud.CARDS_TYPE_DESCRIPTION = 
{
    "高牌(high card)：不符合上面任何一种牌型的牌型，由单牌且不连续不同花的组成",
    "一对(one pair)：一对加上3张杂牌",
    "两对(two pairs)：两对加上一个杂牌 ",
    "3条(three of a kind)：三张牌点值相同，其他两张各异",
    "顺子(straight)：五张牌连张，至少一张花色不同",
    "同花(flush)：5张牌花色相同，但是不成顺子",
    "满堂红(full house)（又称“葫芦”）：3张同点值加上另外一对",
    "4条(four of a kind)：4张同点值的牌加上一张其他任何牌 ",
    "同花顺(straight flush)：由五张连张同花色的牌组成",
    -- "皇家同花顺(royal flush)：由AKQJ10五张组成，并且这5张牌花色相同",
}

_FiveCardStud.CARDS_TYPE_SIMPLE_DESCRIPTION = 
{
    "高牌",
    "一对",
    "两对",
    "3条",
    "顺子",
    "同花",
    "满堂红",
    "4条",
    "同花顺",
    -- "皇家同花顺",
}



local CARDS_TYPE = _FiveCardStud.CARDS_TYPE;

--[[
    自定义比较函数,以size大小为主

    cmp1 = {
            cardSize = 1,
            cardPoint = cards[i].cardPoint,
            cards = { 
                cards[i]
            }
]]
function _FiveCardStud.cardsTypeCmp(cmp1,cmp2)
    if cmp1.cardSize ==  cmp2.cardSize then
        return cmp1.cardPoint > cmp2.cardPoint;
    end
    return cmp1.cardSize > cmp2.cardSize;
end

--[[
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
function _FiveCardStud:getCardsType(_cards)
        
        -- 排序依次poker牌
         local cards = table.clone(_cards)
        table.sort(cards,self.card_comp);
        local len = table.getn(cards);
        local cardtype_param = {
        isFLUSH = {result = false , suitSize = 0},    -- suit 数量为1
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
        table.sort(cardtype_param.status,_FiveCardStud.cardsTypeCmp);
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
            -- if cards[1].cardId == Poker.CardIDType.Ace then      -- 是否为大同花顺
            --     cardTypeResult = CARDS_TYPE.ROYAL_FLUSH; 
            -- else
            --     cardTypeResult =  CARDS_TYPE.STRAINGHT_FLUSH;
            -- end

            cardTypeResult =  CARDS_TYPE.STRAINGHT_FLUSH;  
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
-- 将 来源表格 中所有键及值复制到 目标表格 对象中，如果存在同名键，则覆盖其值
-- example 
    PokerCard = {
        cardId = PokercardId.RedJoker;
        Suit = PokerSuitType.Hears;
        IsUsed = 1; -- 0表示已经使用 1表示未使用
    } 

    local testTable={
        { Player_Id = 1, PlayerName = "Steven",PlayerMoney = 100,
            Cards =  {{cardId = PokercardId.Ace,        Suit = PokerSuitType.Spades , IsUsed = 0},
            {cardId = PokercardId.King,     Suit = PokerSuitType.Spades , IsUsed = 0},
            {cardId = PokercardId.Queen,    Suit = PokerSuitType.Spades , IsUsed = 0},
            {cardId = PokercardId.Jack,     Suit = PokerSuitType.Spades , IsUsed = 0},
            {cardId = PokercardId.Ten,      Suit = PokerSuitType.Spades , IsUsed = 0}}
        },
        {  PlayerId = 2, PlayerName = "Tom",PlayerMoney = 100,
            Cards = {{cardId = PokercardId.Ace,        Suit = PokerSuitType.Hears , IsUsed = 0},
            {cardId = PokercardId.King,     Suit = PokerSuitType.Hears , IsUsed = 0},
            {cardId = PokercardId.Queen,    Suit = PokerSuitType.Hears , IsUsed = 0},
            {cardId = PokercardId.Jack,     Suit = PokerSuitType.Hears , IsUsed = 0},
            {cardId = PokercardId.Ten,      Suit = PokerSuitType.Hears , IsUsed = 0}},
        },
    }
    local index = Juge(testTable)

-- @param cards1 卡牌集合1
-- @param cards2 卡牌集合2
-- @return   返回当前最大的卡牌,true 卡牌1大/ false, new cards1 ,new cards2,卡牌1的类型,卡牌2的类型
--]]
-- 第一步首先选出玩家手中最大的牌,将玩家牌和公共牌可组合的集合拿到,然后判断每一个牌的牌形,循环找出最大的牌组并返回
-- 第二步选出所有玩家手中最大的牌 类似以上操作
-- p1,p2都进行了一次牌的排序和牌型计算
local CARDS_COMPARE =  Poker.CARDS_COMPARE;
function _FiveCardStud:JugeCards(cards1,cards2)

   local cardsType1 , rescards1 = self:getCardsType(cards1);
   local cardsType2 , rescards2 = self:getCardsType(cards2);
   
    -- 两副牌中那个比较大
    local cards_a_b = nil;
    -- 牌型不相同,直接以牌型大的为大
    if cardsType1 ~= cardsType2 then
        return  cardsType1 > cardsType2 and CARDS_COMPARE.OVER or CARDS_COMPARE.UNDER, rescards1, rescards2, cardsType1,cardsType2;
    else
        -- 牌形相同,根据牌形类型进行比较
        --[[
        -- 牌型
        ROYAL_FLUSH  = 10,            皇家同花顺(royal flush)：由AKQJ10五张组成，并且这5张牌花色相同 　　  
        STRAINGHT_FLUSH = 9,            同花顺(straight flush)：由五张连张同花色的牌组成 　　
        FOUR_OF_AKIND = 8,            4条(four of a kind)：4张同点值的牌加上一张其他任何牌 　　
        FULL_HOUSE = 7,            满堂红(full house)（又称“葫芦”）：3张同点值加上另外一对 　　
        FLUSH = 6,            同花(flush)：5张牌花色相同，但是不成顺子 　　
        STRAIGHT = 5,            顺子(straight)：五张牌连张，至少一张花色不同 　　
        THREE_OF_AKIND = 4,            3条(three of a kind)：三张牌点值相同，其他两张各异 　　
        TWO_PAIRS = 3,            两对(two pairs)：两对加上一个杂牌 　　
        ONE_PAIRS = 2,            一对(one pair)：一对加上3张杂牌 　　
        HIGHT_CARD = 1,            高牌(high card)：不符合上面任何一种牌型的牌型，由单牌且不连续不同花的组成
        ]]

        if cardsType1 == CARDS_TYPE.ROYAL_FLUSH then
             --  皇家同花顺,平局
            return CARDS_COMPARE.EQUAL,rescards1,rescards2,cardsType1,cardsType2;  
        else 
            for i = 1,5,1 do
                local card1 = rescards1[i];
                local card2 = rescards2[i];
                if card1.cardPoint ~= card2.cardPoint then
                    local cardsize = card1.cardPoint > card2.cardPoint ;
                    return cardsize and CARDS_COMPARE.OVER or CARDS_COMPARE.UNDER,  rescards1, rescards2, cardsType1,cardsType2; 
                end  
            end

            return CARDS_COMPARE.EQUAL, rescards1, rescards2, cardsType1, cardsType2;
                     
        end
    end 
end

--[[
-- 将 用户底牌和公共牌 返回所有可组合的对象列表
-- example 
    比较玩家玩家大小
-- @param player1 玩家的数据结构
-- @param player2 玩家的数据结构
-- @return 返回大的玩家
--]]
function _FiveCardStud:JugePlayerCards(player1,player2)
    local cards1 = player1.cards;
    local cards2 = player2.cards;
   local isPlayer1
   isPlayer1,player1.cards,player2.cards,player1.cardType,player2.cardType = self:JugeCards(cards1,cards2)
    -- if CARDS_COMPARE.OVER == isPlayer1 then 
    --     return player1
    -- elseif CARDS_COMPARE.UNDER == isPlayer1 then
    --     return player2
    -- else
    --     return nil
    -- end
    return isPlayer1
end

  
--[[
    如果函数返回nil表明都是皇家同花顺,否则返回的为最大的玩家的信息
]]

--[[
-- 返回玩家队列中最大的玩家信息, 如果函数返回nil表明都是皇家同花顺,否则返回的为最大的玩家的信息,
-- 取桌面上的公共牌来组合最大的个人牌的时候也调用该函数,只是所有的playerid为相同而已
-- example
    
    
-- @param players 玩家数组
--]]
function _FiveCardStud:Juge(players)
    local len = table.getn(players);
    for i=1,len,1 do
        local player = players[i];
        player.cardType = self:getCardsType(player.cards);
    end
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
--[[
    返回当前cards数组中最大的牌的位置
]]
function _FiveCardStud:JugeCardsArray(cardsArray)
    local len = table.getn(cardsArray); 
    local mIndex = 1;
    local maxCards = cardsArray[1];
    for i=2,len,1 do 
        local isCards1 = self:JugeCards(maxCards,cardsArray[i]) 
        if  isCards1 < 0 then
            maxCards = cardsArray[i];
            mIndex = i;
        end
    end  
    return mIndex;
end
 
_FiveCardStud.__index = _FiveCardStud;



function _FiveCardStud:computeBetResult(_ap,_bp,_cp,_dp,_isLower)
        local betTypeData = 0;
        for k,v in pairs(_ap.betTypeSet)  do
            if _ap.cardsType == self.CARDS_TYPE[k] then
                betTypeData = betTypeData - v.Money*v.Odds
            else
                betTypeData = betTypeData + v.Money;
            end
        end

        -- 计算庄家跟各自玩家的对比数据
        -- 判断a b 两个玩家数据
        local abData = 0; 
        local cards,isPlayer1 = self:JugeCards(_ap.maxCards,_bp.maxCards)
        if isPlayer1 >= 0 then
               abData = abData + _bp.win.Money*_bp.win.Odds;
        elseif isPlayer1 == 0 then
        else
             abData = abData - _bp.win.Money*_bp.win.Odds;
        end 

        -- 判断a c 两个玩家数据
        local acData = 0; 
        local cards,isPlayer1 = self:JugeCards(_ap.maxCards,_cp.maxCards)
        if isPlayer1 >= 0 then
               acData = acData + _cp.win.Money*_cp.win.Odds;
        elseif isPlayer1 == 0 then
        else
             acData = acData - _cp.win.Money*_cp.win.Odds;
        end
 
        -- 判断a d 两个玩家数据
        local adData = 0; 
        local cards,isPlayer1 = self:JugeCards(_ap.maxCards,_dp.maxCards)
        if isPlayer1 > 0 then
           adData = adData +  _dp.win.Money*_dp.win.Odds;
        elseif isPlayer1 == 0 then
        else
            adData = adData - _dp.win.Money*_dp.win.Odds;
        end

        -- 累加当前状态下系统挣钱还是亏钱
        local resData = betTypeData + abData + acData + adData;
        return resData;
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
                local _ap = {betTypeSet={ROYAL_FLUSH={Money=1000,Odds=6} ,STRAINGHT_FLUSH={Money=1000,Odds=5} } } 
-- @param _bp  散家牌型,该结构主要该散家被押注的情况,数据结构如下
                local _bp = {win={Money=1000,Odds=6},lose={Money=1000,Odds=5}}
-- @param _cp   同_bp
-- @param _dp   同_bp
-- @param _isLower 是否低于资金池标志,如果低于执行修正算法,如果没有,继续进行
-- @param _bili _矫正比例
-- @return  
--]]
function _FiveCardStud:allinmodel(_ap,_bp,_cp,_dp,_isLower,_bili)
    -- body
  
        -- 正常业务逻辑
        -- 给所有玩家发送所有手牌  
        _ap.cards = self:getMutiCards(5);
        _bp.cards = self:getMutiCards(5);
        _cp.cards = self:getMutiCards(5);
        _dp.cards = self:getMutiCards(5);
  
  
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
    return publicCards;
end




--[[
-- 创建一副德州扑克牌对象,该对象包含扑克的牌信息,
-- 德州扑克卡牌算法,以及德州扑克牌,该扑克牌的基础信息 PokerCards
-- example
    local texasHoldem = require "game.TexasHoldem.TexasHoldem":new()
    local poker = texasHoldem.PokerImpl;
-- @param   
-- @return 返回当前玩法的德州扑克牌局,创建牌局将创建一副扑克牌,德州扑克玩法的扑克牌
--]]
function _FiveCardStud:new()
    local texasHoldemImpl =  setmetatable({}, _FiveCardStud);
    -- 创建poker 对象,每局卡牌进行数据new
    texasHoldemImpl.Cards = texasHoldemImpl:newCards(1,false);

    return texasHoldemImpl;
end
  
return _FiveCardStud

