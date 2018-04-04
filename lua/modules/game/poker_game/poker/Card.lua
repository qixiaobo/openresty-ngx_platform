--region *.lua
--Date 2017-03-07
--此文件由[BabeLua]插件自动生成




local _SeenCard = true -- 明牌
local _BlindCard = false -- 暗牌

local _M = {
	--卡牌花色
    cardSuit = 1,
    --牌id
    cardId = 1,
    --牌大小点数
    cardPoint = 1,
    --当前牌是明牌还是暗牌
    cardSB = false,
}

local mt = { __index = _M }  

--[[
-- poker 扑克牌的基础属性
-- 包括以下字段
    -- cardSuit 花色
    -- cardId   扑克牌的Id ,ace ,2 ,3 ,4
    -- cardPoint 扑克牌的点数
    -- cardSB    扑克牌是明牌还是暗牌
]]

function _M:new(_suit, _id,_point,_cardSB)
    local card = setmetatable({}, mt)
    card.cardSuit = _suit
    card.cardId = _id
    card.cardPoint = _point
    card.cardSB = _cardSB -- true 表示明牌 ;false 表示 暗牌
    return card
end

return _M
--endregion
