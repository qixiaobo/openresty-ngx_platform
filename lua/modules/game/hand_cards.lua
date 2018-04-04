--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:lua/modules/game/hand_cards.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  扑克牌手牌相关,主要对于手牌的管理与实现,
--]]

local HandCards = { }

function HandCards:new()
    local carset = setmetatable({}, { __index = HandCards })
    return carset
end


-- function CardSet:insert(_cardId)
--    table.insert(self, _cardId)
-- end

function HandCards.card_comp(card1, card2)
    if card1.cardId  ~= card2.cardId then 
        return card1.cardId > card2.cardId;
    else
        return card1.cardSuit > card2.cardSuit;
    end
end

function HandCards:insert(_card)
    table.insert(self, _card)

    -- 排序：最小的在前，大的在后（不判断花色）
    local size = table.getn(self)
  
    table.sort(self, self.card_comp);

--    local cardTemp = {}
--    for i=1, size-1, 1 do
--        for j=1, size-i, 1 do
--            if self[j].id > self[j+1].id then
--                cardTemp = self[j]
--                self[j] = self[j+1]
--                self[j+1] = cardTemp
--            end
--        end
--    end 
end


return HandCards
 