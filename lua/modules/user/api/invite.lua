--[[
    @brief: 邀请好友
]]
local cjson = require "cjson"
local api_data_help = require "common.api_data_help"
local random_help = require "common.random_help"
local redis_help = require "common.db.redis_help"
local mysql_help = require "common.db.mysql_help"
local mysql_db = require "common.db.db_mysql"
local incr_help = require "common.incr_help"
local invite_dao = require("user.model.invite_dao")

local _M = {}

--[[
    @url:   user/api/invite/gen_code.action?user_code=10000120
    @brief: 生成邀请码，保存到 REDIS， 
]]
-- INVITE_CODE  154878144    {user_code=10000097, timestamp=2018-01-01 12:00:00}
function _M.gen_code()
    local args = ngx.req.get_uri_args()
    local user_code = args["user_code"]
    if not user_code then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "Param [user_code] is not set.")
    end
    local redis_cli = redis_help:new()
    if not redis_cli then
        return nil, "redis new failed."
    end

    local invite_code
    invite_code = redis_cli:hget("INVITE_USER_CODE", user_code)
    if not invite_code then
        invite_code = random_help.random_by_len(7)
        redis_cli:hset("INVITE_USER_CODE", user_code, invite_code)
        redis_cli:hset("INVITE_CODE_USER", invite_code, user_code)
    end
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取邀请码成功", {code = invite_code})
end

--[[
    @url:   user/api/invite/use_invite_code.action?user_code=10000001?invite_code=1243517
    @brief: 生成邀请码，保存到 REDIS， 
]]
function _M.use_invite_code()
    local args = ngx.req.get_uri_args()
    local invite_code = args["invite_code"]
    local user_code = args["user_code"]
    if not invite_code or not user_code then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "Param [user_code or invite_code] is not set.")
    end

    local redis_cli = redis_help:new()
    if not redis_cli then
        return api_data_help.new(ZS_ERROR_CODE.REDIS_NEW_ERR, "redis new failed.")
    end

    local userA = redis_cli:hget("INVITE_CODE_USER", invite_code)
    if not userA then
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "Get invite code failed. Cann't find [" .. invite_code.. "in REDIS, key=INVITE_CODE_USER", -1)
    end

    local res = redis_cli:hget("INVITE_CODE_RECORD", invite_code .. ":" .. user_code)
    if res then
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "The invite code is already used.", -2)
    end

    if user_code == userA then
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "Can't invite yourself.", -3)
    end

    
    ngx.log(ngx.ERR, string.format("==========  A:%s, B:%s, code:%s", userA,user_code, invite_code))
    local res, err = invite_dao.reward(userA, invite_code, user_code)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "输入邀请码获取奖励失败.", err)
    end

    redis_cli:hset("INVITE_CODE_RECORD", invite_code .. ":" .. user_code, os.date("%Y-%m-%d %H:%M:%S", os.time()))
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "Successful.", 0)
end

--[[
    @url:   
    @brief: 邀请好友，发送注册链接短信： http://fmyl.com/index.html?code=1425861&user=10000010
]]
local aes = require "resty.aes"
_M.send_sms = function()
    --ECB 方式无需iv,传递一个16字节的iv以便用原始key进行EVP_DecryptInit_ex初始化
    -- local price_decode = aes:new(key,nil,aes.cipher(128,"ecb"),{iv=dspkey})
    -- local base_decode_bytes = ngx.decode_base64(ad_price)
    -- ngx.log(ngx.DEBUG,"base_decode_price_byte:" .. str.to_hex(base_decode_price))
    -- --补充一个空块的加密结果，以适应decrypt函数的调用
    -- base_decode_bytes = base_decode_bytes .. pad_bytes
    -- local price =  price_decode:decrypt(base_decode_bytes)
    local k = "fmyl"
    local s = "1234567890000000"
    local text = "HelloWorld"
    local chipertext = aes:new(k, s, aes.cipher(128, "cbc")):encrypt(text)
    ngx.log(ngx.ERR, chipertext)
end

return _M
