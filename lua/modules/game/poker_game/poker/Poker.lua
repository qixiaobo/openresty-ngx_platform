--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:poker.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  poker 对象, 
--
--]]

local cjson = require "cjson"
--[[
-- 扑克牌的数据预定义 默认系统返回一个poker信息,不同游戏继承当前poker结构
-- 提供扑克牌的生成,随机输出牌,
-- 同时修改该扑克牌的状态防止系统被攻击或者串改
]]--
local _Poker = {}

_Poker.__index = _Poker

--[[
花色：suit
红心：hearts
梅花：clubs (也叫 clovers)
方块：diamonds
黑桃：spades
例如“跟出同一花色的牌”叫 follow suit
将牌(王牌,主)花色叫 trump suit
红心3叫 three of hearts
-- 花色定义
"spades","hearts","clubs",'diamonds'
--]]

_Poker.SUIT_TYPE = {
    SPADES  = 4,
    HEARS   = 3,
    CLUBS   = 2,
    DIAMONS = 1, 
}
_Poker.SUIT_TYPE_ARRAY = {
    "SPADES" ,
    "HEARS"  ,
    "CLUBS"  ,
    "DIAMONS", 
}

_Poker.SUIT_TYPE_MAP = {
    "♠️","♥️","♣️","♦️" 
}


-- 默认poker对象使用一副牌
_Poker.PokerNum = 1
--[[
    牌ID 定义
    扑克牌中红桃（红心）、黑桃、方块（方片）及梅花（草花）分别用英语hearts、spades、diamonds及clubs表示。记住一定用复数。 
    A读作ACE 复数是ACES 
    2-9用正常数字读法 JQK分别读作Jack Queen King 
    王为JOKER 
    读完整扑克牌名时英语习惯先说数值后说花色，恰与中文相反 
--]]
_Poker.CARD_ID_TYPE = {
            REDJOKER    = 15,
            BLACKJOKER  = 14, 
            KING        = 13,
            QUEEN       = 12,
            JACK        = 11,
            TEN         = 10,
            NINE        = 9,
            EIGHT       = 8,
            SEVEN       = 7,
            SIX         = 6,
            FIVE        = 5,
            FOUR        = 4,
            THREE       = 3,
            TWO         = 2, 
            ACE         = 1,
}
--[[
    单张卡牌的id 与 value之间的映射
]]
_Poker.CARD_ID_KEY_MAP = {
            "ACE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT",
            "NINE", "TEN", "JACK", "QUEEN", "KING", "BLACKJOKER", "REDJOKER"
}
_Poker.CARD_ID_NAME_MAP = {
            "Ace", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight",
            "Nine", "Ten", "Jack", "Queen", "King", "BlackJoker", "RedJoker"
}
--[[
    定义扑克牌的单张牌的大小
]]
_Poker.CARD_POINT = {
            REDJOKER    = 18,
            BLACKJOKER  = 17, 
            KING        = 13,
            QUEEN       = 12,
            JACK        = 11,
            TEN         = 10,
            NINE        = 9,
            EIGHT       = 8,
            SEVEN       = 7,
            SIX         = 6,
            FIVE        = 5,
            FOUR        = 4,
            THREE       = 3,
            TWO         = 2, 
            ACE         = 1,
}
--[[
    定义扑克牌的大小
]]
_Poker.CARDS_COMPARE = {
    UNDER = -1,     -- 小于
    EQUAL = 0,       -- 平手
    OVER = 1,       -- 大于
}

--[[


_Poker.PokerCard = {
    cardId = CardID.RedJoker;
    cardSuit = SuitType.Hears;
    isUsed = 1; -- 0表示已经使用 1表示未使用
}
]]
 
 
--[[
-- C_M_N 集合数据样本取法
-- example
    local testSrc3 = {
        1,2,3,4,5
    }
    local resultT3 = C_M_N(testSrc1,3);
    ngx.say("size is "..table.getn(resultT3).." "..cjson.encode(resultT3))

-- @param srcTable 样本集合
-- @param n 样本中需要取出的大小
返回已经结果数组

]]
function  _Poker.C_M_3( srcTable)
    -- body
    local m = table.getn(srcTable);
    local n = 3;
    local index = 1;
    local tDes = {};
    for index1 = 1, m-n+1 , 1 do
        for index2 = index1 + 1, m-1, 1 do
            for index3 = index2 + 1, m, 1 do
                tDes[index] = {
                    srcTable[index1],srcTable[index2],srcTable[index3]
                }
                index = index + 1;
            end
        end
    end
    return tDes;
end

function  _Poker.C_M_5( srcTable )
    -- body
    local m = table.getn(srcTable);
    local n = 3;
    local index = 1;
    local tDes = {}; 
    for index1 = 1, m - n + 1 , 1 do
        for index2 = index1 + 1, m - 3, 1 do
            for index3 = index2 + 1, m - 2, 1 do
                for index4 = index3 + 1, m - 1, 1 do
                    for index5 = index4 + 1, m, 1 do
                        tDes[index] = {
                            srcTable[index1],srcTable[index2],srcTable[index3],srcTable[index4],srcTable[index5]
                        }
                        index = index + 1;
                    end
                end 
            end
        end
    end
    return tDes;
end
--[[
-------------------------------------------------
-------------------------------------------------
-- 定义CARD 的排序算法 主要包括用于卡牌的大小比较和排序,也可以用于单张牌比大小
-- example1
--  作为卡牌排序回掉
    local testCard = {...};
    table.sort(testCard,card_comp);  
    玩家组合的牌必须进行一次排序,方便对比与判断

-- example2
-- 作为普通卡牌比较
     card1 = {
        cardId = _Poker.CardIDType.Ace,        
        cardPoint = _Poker.CardPoint.Ace,
        cardSuit = _Poker.Suits.Spades,
        isUsed = false,
        exCardValue = nil,  --扩展值 比如斗地主中2为当局王，则需要将扑克牌中的2设置为较大值比如15 ,不同游戏卡牌不同设定
                            -- 设置颜色的修改同时在本局游戏中设定,不要修改默认的大小,所有的结果用户需要clone处理各个数据结构
     }
 card2 = {
        cardId = _Poker.CardIDType.Ace,        
        cardPoint = _Poker.CardPoint.Ace,
        cardSuit = _Poker.Suits.Spades,
        isUsed = false,
        exCardValue = nil,  --扩展值 比如斗地主中2为当局王，则需要将扑克牌中的2设置为较大值比如15 ,不同游戏卡牌不同设定
                            -- 设置颜色的修改同时在本局游戏中设定,不要修改默认的大小,所有的结果用户需要clone处理各个数据结构
     }
-- @param card1 卡牌1
-- @param card2 卡牌2
返回已经两张卡牌的大小
-------------------------------------------------
-------------------------------------------------
--]]

function _Poker.card_comp(card1,card2) 
    if card1.cardId  ~= card2.cardId then   
        -- 如果扩展值不为空 首先以扩展值比较
        local card1Point =  not card1.exCardPoint and  card1.cardPoint  or card1.exCardPoint
        local card2Point =  not card2.exCardPoint and  card2.cardPoint or  card2.exCardPoint
        
        --ngx.say(cjson.encode(card1))
        return card1Point > card2Point;
        --return card1Point > card2Point;
        
    else
        --ngx.say("cardSuit "..card1.cardSuit .. "cardSuit " .. card2.cardSuit)
        return card1.cardSuit > card2.cardSuit;
    end
end

function _Poker.max_comp(numb1,numb2) 
    return numb1 > numb2
end

 
math.randomseed(tostring(os.time()):reverse():sub(1, 7)) 
 
--[[
-- 获取从当前卡牌中获取一张卡牌,卡牌集合同时删除该信息集合数据
-- example
    -- 前提是需要new一次创建卡牌对象 该对象
-- @param  无
-- @return 随机获得一张牌
--]]
function _Poker:getCard()
     --math.randomseed(os.clock()*10000)
    local _cards = self.Cards;
    ngx.log(ngx.ERR,table.getn(_cards))

    local cur_index = math.random(1, table.getn(_cards))
    local card = _cards[cur_index]
    table.remove(_cards, cur_index)

    return card
end

--[[
-- 每个玩家发底牌底牌
 --@parm pokernum 几张牌
--]]
function _Poker:getMutiCards(_cards_num)
    
    local len = table.getn(self.Cards);
    if _cards_num  <= 0 or _cards_num >= len then
        ngx.log(ngx.ERR,"get cards_num is error ",_cards_num)
        return nil
    end
    local resCards = {}
    for i=1,_cards_num do
        resCards[i] = self:getCard();
    end 
    return resCards;
end
  

--[[
-- _Poker:surplus 返回当前剩余的cards数量
-- @param: 无 几张牌
-- @return: 返回当前牌局的扑克牌剩余数量
--]]
function _Poker:surplusCards()
    -- body
    return table.getn(self.Cards)
end

--[[
-- new 新建一套扑克牌
-- example
    local poker = require "game.poker.Poker"
    local pokerTemp = poker.new(1,false);

    local pokerCards = pokerTemp.Cards;
-- @param number 扑克牌数量
-- @param hasJoker 是否包含大小王

-- @return 返回poker对象,该对象包含Cards,即用户扑克牌

]]
local PokerCard = require "game.poker.Card"
function _Poker:newCards(number,hasJoker)
-- 根据需要初始化的扑扑克返回扑克
    local cards = {};
    local startIndex = 1;
    -- 需要大小王时,添加进入卡牌中
    if hasJoker then
        cards[1] =  PokerCard:new(nil,self.CARD_ID_TYPE.REDJOKER,self.CARD_POINT.REDJOKER);
        cards[2] =  PokerCard:new(nil,self.CARD_ID_TYPE.BLACKJOKER,self.CARD_POINT.BLACKJOKER);
        startIndex = 3; 
    end

    local cardSuits = self.SUIT_TYPE;
    local CardIDType = self.CARD_ID_TYPE;

    for ks,vs in pairs(cardSuits) do
        for kid,vid in pairs(CardIDType) do
            if self.CARD_ID_TYPE.REDJOKER ~= vid and vid ~= self.CARD_ID_TYPE.BLACKJOKER then
                cards[startIndex] = PokerCard:new(vs,vid,self.CARD_POINT[kid],false); 
                startIndex = startIndex + 1;
            end
        end
    end
    -- ngx.say(table.getn(cards))
    -- 根据需要创建的扑克数量，将扑克牌合并到扑克牌数组中
    local resultCards = {};
    for i = 1,number,1 do
        table.arrayMerge(resultCards,cards);
    end
    -- 设置元组,返回返
    -- local newPoker = setmetatable({Cards = resultCards}, _Poker)
    --newPoker.Cards = resultCards;
    return resultCards;
end 

return _Poker