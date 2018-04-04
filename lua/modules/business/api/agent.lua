local utils = require("common.utils")
local crypto = require("common.crypto.crypto")
local api_data_help = require("common.api_data_help")

local _M = {}

--[[
    接入登录游戏
    @url:   business/api/agent/access_to.action
    @param: [agentid]
    @param: [account]
    @param: [gameid]
    @param: [points]
    @param: [ip]
    
]]
function _M.access_to()
    local args, res, err = utils.get_req_args({"agentid", "account", "gameid", "points", "ip"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    --http://<server>/channelHandle?agent=10001&timestamp=1488781836949&key=f3afd416a0bb1b183eed8ef6cac30d75&param=ngtgiYCl26%2FgBmGvf9Euj2c1MOpzIzy4VWru%2Fsv3jao88cUlrENQTXz6pAeS3I2FqR7%2FPJFUIoTh%0D%0Ae%2FFnAkdbw2TxTkbhPCi5yjGJVVdY2C4%3D
    --[[
        参数：
        s = 0,              --操作子类型
        account = account,  --会员账号
        money = points,     --金额
        orderid = agentid .. os.date("%Y%m%d%H%M%S", os.time()) .. account, --流水号(格式: 代理编号+yyyyMMddHHmmss+account)
        ip = ip, --IP地址
        lineCode = text11,  --代理下的站点标识
        KindID = gameid     --游戏ID
    ]]
    local timestamp = os.time()

    local param =
        string.format(
        "s=0&account=%s&money=%s&orderid=%s&ip=%s&lineCode=%s&KindID=%s",
        args.account,
        args.points,
        args.agentid .. os.date("%Y%m%d%H%M%S", timestamp) .. args.account,
        args.ip,
        "text11",
        args.gameid
    )

    -- md5 加密
    local md5_key = "HELLOWORLD"
    local text = args.agentid .. timestamp .. md5_key
    local md5_text = utils.to_hex(crypto.md5_encrypt(text))

    local url =
        string.format(
        "http://127.0.0.1/channelHandle?agent=%s&timestamp=%s&param=%s&key=%s",
        args.agentid,
        timestamp,
        param,
        md5_text
    )
    ngx.say(url)
    -- local res, err = utils.http_req(url)

    -- RESPONSE:
    -- {
    --     "s":100,
    --     "m":"/channelHandle",
    --     "d":{
    --         "code":0,
    --         "url":"http://h5.ky34.com/index.html?account=10001_111111&token=IH&T657HHGbhtOMHTUBFGJNJU548HtN8B&lang=zh-cn&KindID=0"
    --     }

    -- }

    return api_data_help.new(
        "200",
        "Access game successful.",
        {s = 100, m = "channelHandle", d = {code = 0, url = "http://www.baidu.com"}}
    )
end

--[[
    查询余额
]]
function _M.get_balance()
    local param = {
        s = 1,
        account = 11111
    }
end

--[[
    上分
]]
function _M.up()
end

--[[
    下分
]]
function _M.down()
end

--[[
    查询订单
]]
function _M.get_order()
end

--[[
    查询用户在线状态
]]
function _M.get_online_state()
end

--[[
    查询游戏注单
]]
function _M.get_record()
end

--[[
    查询玩家总分
]]
function _M.get_total_points()
end

--[[
    强制用户离线
]]
function _M.kick()
end

return _M
