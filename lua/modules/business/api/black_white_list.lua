local api_data_help = require "common.api_data_help"
local utils = require("common.utils")

local dao_b_w_list = require("business.module.dao_b_w_list")

local _M = {}


--[[
    添加黑白名单
    @url:   business/api/channel_manager/add_b_w_list.action?
    @param: [ip]
    @param: [ip_type]
    @param: [type] black: 黑名单，white: 白名单
    @param: [channel_id]
]]
function _M.add_b_w_list()
    -- 解析参数
    local args, res, err = utils.get_req_args({"ip", "ip_type", "type", "channel_id"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    -- 检查该IP是否已经在黑白名单中
    local res, err = dao_b_w_list.get(args.ip, args.channel_id, args.type)
    if not res then
        return api_data_help.new("???", "系统错误", err)
    end
    if res[1] then
        return api_data_help.new("???", "该IP已经在黑白名单中", {ip = args.ip, type = res[1].black_white})
    end

    -- 添加黑白名单数据到数据库
    local res, err = dao_b_w_list.insert(args.ip, args.ip_type, args.type, args.channel_id)
    if not res then
        return api_data_help.new("???", "添加黑白名单失败", err)
    end

    -- 操作成功
    return api_data_help.new("???", "添加黑白名单成功", res)
end

--[[
    删除黑白名单
    @url:   business/api/channel_manager/del_b_w_list.action?
    @param: [ip] IP地址
    @param: [channel_id] 渠道商ID
    @param: [type] black/white
]]
function _M.del_b_w_list()
    local args, res, err = utils.get_req_args({"ip", "channel_id", "type"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    local res, err = dao_b_w_list.delete(args.ip, args.channel_id, args.type)
    if not res then
        return api_data_help.new("???", "删除黑白名单失败", err)
    end
    return api_data_help.new("???", "删除黑白名单成功", res)
end



--[[
    获取黑白名单
    @url:   business/api/channel_manager/get_b_w_list_by_channelid.action?
    @param: [channel_id]
]]
function _M.get_b_w_list_by_channelid()
    local args, res, err = utils.get_req_args({"channel_id"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    local res, err = dao_b_w_list.get_by_channel_id(args.channel_id)
    if not res then
        return api_data_help.new("???", "获取黑白名单失败", err)
    end
    return api_data_help.new("???", "获取黑白名单成功", res)
end

return _M