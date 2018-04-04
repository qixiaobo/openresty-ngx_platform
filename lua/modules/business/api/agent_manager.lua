local utils = require("common.utils")
local api_data_help = require "common.api_data_help"

local dao_agent = require("business.module.dao_agent")
local dao_game = require("business.module.dao_game")

local _M = {}

--[[
    代理注册
    @url:   business/api/agent_manager/register.action
]]
function _M.register()
    local args, res, err =
        utils.get_req_args({"name", "agentid", "url", "logo", "effects", "desc", "hot", "state", "index"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    local res, err =
        dao_agent.insert(
        args.name,
        args.agentid,
        args.url,
        args.logo,
        args.effects,
        args.desc,
        args.hot,
        args.state,
        args.index
    )
    if not res then
        return api_data_help.new("???", "Database error.", err)
    end
    return api_data_help.new("???", "Agent register successful.", err)
end

--[[
    获取渠道商的产品信息
    @url:   business/api/agent_manager/get_product.action
    @param: [agentid]
]]
function _M.get_product()
    local args, res, err = utils.get_req_args({"agentid"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    local res, err = dao_game.query(args.agentid)
    if not res then
        return api_data_help.new("???", "系统错误", err)
    end
    return api_data_help.new("200", "获取渠道商的产品信息成功", res)
end

--[[
    @url:   business/api/agent_manager/add_product.action
    @param: [agentid]
    @param: [name]
    @param: [gameno]
    @param: [ad]
    @param: [logo]
]]
function _M.add_product()
    local args, res, err = utils.get_req_args({"agentid", "name", "gameno", "ad", "logo"})
    if not res then
        return api_data_help.new("???", "参数错误", err)
    end

    local res, err = dao_game.insert(args.agentid, args.name, args.gameno, args.ad, args.logo, 0, 0)
    if not res then
        return api_data_help.new("???", "系统错误", err)
    end
    return api_data_help.new("200", "添加产品成功", res)
end
return _M
