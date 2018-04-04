--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:lua/modules/game/poker_card.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  poker 游戏 poker 卡牌基础结构, 包含花色,卡牌ID,卡牌点数,卡牌类型(即卡牌效果),明牌/暗牌, 当前该卡牌的ID
--]]
local uuid_help = require("common.uuid_help")
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
    -- 卡牌序列,该序列用于暗牌的数据获取,为了安全起见,序列为随机产生,序列只有在开牌时才能访问
    cardNo = "",
    -- 特效编号,该特效决定了该扑克牌的牌面效果,动画效果,声乐效果,例子效果等
    cardEff = 1,
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
--    card.cardNo = uuid_help:get64()
    
    return card
end

return _M
--endregion
