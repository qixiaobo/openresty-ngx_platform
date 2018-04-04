--[[
]]
local cjson = require("cjson")
local utils = require("common.utils")
local opt_log = require("system.opt_log")
local api_data_help = require "common.api_data_help"
local token_manager = require("common.token_manager")
local redis_manager = require("common.db.redis_manager")
local redis_help = require "common.db.redis_help"

local dao_channel = require("business.module.dao_channel")

local dao_rsa = require("business.module.dao_rsa")
local dao_user = require("user.model.user_dao")

local function create_channelid()
    local redis = redis_help:new()
    if not redis then
        return nil, "create redis object failed."
    end

    local res, err = redis:incr("CHANNEL_ID_INDEX")
    if not res then
        return nil, "redis:incr failed."
    end
    return res + 20000000
end

local _M = {}

--[[
    渠道商注册
    @url:   business/api/channel/register.action?
    @param: [logo] 
    @param: [name] 名称
    @param: [password] 密码
    @param: [email] 邮箱地址
    @param: [phone] 手机号码
    @param: [area_code] 手机号码区号
    @return: 
]]
function _M.register()
    local args, res, err = utils.get_req_args({"logo", "name", "password", "email", "phone", "area_code"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    -- 查询数据库获取渠道商信息，判断该渠道商是否已经注册
    local channel_info, err = dao_channel.select(nil, args.name, args.phone, args.email)
    if not channel_info then
        return api_data_help.new("???", "系统错误", err)
    end
    if channel_info[1] then
        return api_data_help.new("???", "该渠道商已经注册")
    end

    -- 可以注冊
    -- 生成ID
    local id = create_channelid()

    -- 密码加密
    -- args.password = args.password

    -- 数据库操作, 创建新的渠道商
    local channel_info, err =
        dao_channel.insert(id, args.logo, args.name, args.phone, args.email, args.password, args.area_code, 1)
    if not channel_info then
        return api_data_help.new("???", "渠道商注册失败", err)
    end

    -- 渠道商注册成功
    return api_data_help.new("200", "渠道商注册成功", channel_info)
end

--[[
    设置渠道商信息
    @url:   business/api/channel/set_channel_info.action?
    @param: [channel_id]
    @param: [phone](可选)
    @param: [area_code](可选)
    @param: [email](可选)
]]
function _M.set_channel_info()
    local args, res, err = utils.get_req_args({"channel_id"}, {"phone", "area_code", "email"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    if not args.phone and not args.area_code and not args.email then
        return api_data_help.new("200", "无数据更新")
    end

    -- 查询数据库获取渠道商信息，判断该渠道商是否已经注册
    local channel_info, err = dao_channel.get(nil, args.name, args.phone, args.email)
    if not channel_info then
        return api_data_help.new("???", "查询渠道商信息失败", err)
    end
    -- 已经注册
    if channel_info[1] then
        return api_data_help.new("???", "信息已经被使用")
    end

    -- 更新数据库数据
    local res, err = dao_channel.update(args.channel_id, args.phone, args.area_code, args.email)
    if not res then
        return api_data_help.new("???", "更新数据失败", err)
    end
    return api_data_help.new("200", "更新数据成功", res)
end

--[[
    渠道商登陆
    @url:   business/api/channel/login.action?
    @param: [account] 账号
    @param: [password] 密码
    @param: [location] 地理位置（中国江苏省南京市XX区XX路X号XX大厦）
    @param: [ip] 设备IP (0.0.0.0)
    @param: [device_info] 设备信息 (PC Windows10 /Linux /IOS /Android)
]]
function _M.login()
    -- ngx.say(cjson.encode(ngx.req))

    local args, res, err = utils.get_req_args({"account", "passwrod", "location", "ip", "device_info"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    local channel_info, err = dao_channel.get(nil, args.account, args.phone, args.email)
    if not channel_info then
        return api_data_help.new("???", "查询信息失败", err)
    end
    -- 判断账户是否存在
    if not channel_info[1] then
        return api_data_help.new("???", "账户不存在", err)
    end

    -- 判断密码是否正确
    if channel_info[1].password ~= args.passwrod then
        return api_data_help.new("???", "密码错误", err)
    end

    -- 写REDIS信息
    local res, err = redis_manager.exec(nil, "hset", "LOGIN_TOKEN", channel_info[1].bizorg_id, token_manager.create())
    if not res then
        ngx.say("REDIS 设置登陆信息失败", err)
    end

    -- 写入操作日志
    local content = string.format("用户%s在%s使用设备%s(IP=%s)登陆", args.account, args.location, args.device_info, args.ip)
    local res, err = opt_log.write("渠道商登陆", channel_info[1].bizorg_id, content)
    if not res then
        ngx.say("写操作日志失败", err)
    end

    return api_data_help.new("200", "登陆成功", channel_info[1])
end

--[[
    渠道商登出
    @url:   business/api/channel/logout.action?
    @param: [channel_id] 账号
    @param: [account] 账号
    @param: [location] 地理位置（中国江苏省南京市XX区XX路X号XX大厦）
    @param: [ip] 设备IP (0.0.0.0)
    @param: [device_info] 设备信息 (PC Windows10 /Linux /IOS /Android)
]]
function _M.logout()
    local args, res, err = utils.get_req_args({"channel_id", "account", "location", "ip", "device_info"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    local res, err = redis_manager.exec(nil, "hdel", "LOGIN_TOKEN", args.channel_id)
    if not res then
        ngx.say("REDIS 设置登陆信息失败", err)
    end

    -- 写入操作日志
    local content = string.format("用户%s在%s从设备%s(IP=%s)登出", args.account, args.location, args.device_info, args.ip)
    local res, err = opt_log.write("渠道商登陆", args.channel_id, content)
    if not res then
        ngx.say("写操作日志失败", err)
    end
end

--[[
    获取所有渠道商信息
    @url:   business/api/channel/get_all_channel.action
]]
function _M.get_all_channel()
    local res, err = dao_channel.select_all()
    if not res then
        return api_data_help.new("???", "获取渠道商信息失败", err)
    end
    return api_data_help.new("200", "获取渠道商信息成功", res)
end

--[[
    绑定用户所属渠道商
    @url:   business/api/channel/bind_user_channel.action?
    @param: [channel_id] 所属渠道商ID
    @param: [user_id]
    @return: 
]]
function _M.bind_user_channel()
    -- 解析参数
    local args, res, err = utils.get_req_args({"channel_id", "user_id"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    -- 检查渠道商信息
    local res, err = dao_channel.select(args.channel_id)
    if not res then
        return api_data_help.new("???", "系统错误", {channel_id = args.channel_id, user_id = args.user_id})
    end
    if not res[1] then
        return api_data_help.new("???", "渠道商不存在", {channel_id = args.channel_id, user_id = args.user_id})
    end

    -- 绑定用户和渠道商
    local res, err = dao_channel.bind_user_channel(args.channel_id, args.user_id)
    if not res then
        return api_data_help.new("???", "绑定用户所属的渠道商失败", {channel_id = args.channel_id, user_id = args.user_id})
    end
    return api_data_help.new("200", "渠道商所属用户注册成功", {channel_id = args.channel_id, user_id = args.user_id})
end

--[[
    @url:   business/api/channel/set_rsa.action?channel_id=20000001&pri_key=---&pub_key=---&algorithm=CBC&password=1234567890123456
    @param: [channel_id]
    @param: [pri_key]
    @param: [pub_key]
    @param: [algorithm]
    @param: [password]
]]
function _M.set_rsa()
    -- 解析参数
    local args, res, err = utils.get_req_args({"channel_id", "pri_key", "pub_key", "algorithm", "password"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    -- 数据库写入数据
    local res, err = dao_rsa.insert(args.channel_id, args.pri_key, args.pub_key, args.algorithm, args.password)
    if not res then
        return api_data_help.new("???", "设置渠道商RSA信息失败", err)
    end
    return api_data_help.new("200", "设置渠道商RSA信息成功")
end

--[[
    渠道商用户接入
    @url:   business/api/channel/access_user.action
    @param: [channnel_id] 渠道商ID
    @param: [access_code] 接入码
    @param: [user_name]
    @param: []
]]
function _M.access_user()
    local args, res, err = utils.get_req_args({"channel_id", "access_code", "user_name"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    local name = args.channel_id .. ":" .. args.user_name
    -- -- 判断用户信息是否已经注册，如果没有注册则创建新用户，新用户名格式：渠道商ID_用户名
    -- local user_info, code, err = dao_user.get_user(name)
    -- if not user_info then
    --     return api_data_help.new("???", "系统错误", err)
    -- end

    -- -- 不存在用户信息，注册新用户
    -- if not user_info[1] then
    --     user_info[1] = {
    --         user_id = dao_user.make_user_id(),
    --         user_name = name,
    --         password = nil,
    --         email = "",
    --         phone_number = "",
    --         area_code = "0086",
    --         user_state = "normal"
    --     }
    --     local res, code, err = dao_user.register(user_info[1])
    --     if not res then
    --     end
    -- end

    local res =
        ngx.location.capture(
        "/user/api/user_auth/login.action",
        {
            args = {
                login_name = args.user_name,
                login_type = "third_platform",
                agent_no = args.channel_id
            }
        }
    )
    ngx.say(res.body)
    -- local ret = cjson.decode(res.body)
    -- if 200 ~= res.code then
    --     return api_data_help.new("200", res.msg, res.data)
    -- end

    -- redis_manager.exec(nil, "hset", "LOGIN_TOKEN", user_info[1].user_id, token_manager.create())
    return api_data_help.new("200", "用户接入成功")
end

return _M
