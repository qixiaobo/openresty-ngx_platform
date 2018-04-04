--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:mail.lua
--	version: 0.1 程序结构初始化实现
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right. 
-- 	站内信接口,主要用于系统的主要通知事件,比如充值成功, 上次登录, 系统信息
--]]

local uuid_help = require "common.uuid_help"
local redis_help = require "common.db.redis_help"
local incr_help = require "common.incr_help"
local request_help = require "common.request_help"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local api_data_help = require "common.api_data_help"
local mail_dao = require "messages.model.mail_dao"

local _API_FUNC = {	}




--[[ 
	@接口： messages/api/mail/get_mails.action?user_code=10000035&page=1&page_size=8
	@说明： 获取用户的系统消息
]]
_API_FUNC.get_mails = function()

    local args = request_help.getAllArgs()
    local user_code = args['user_code']

	if not user_code then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "参数[user_code]未设置")
	end
	
	local page = args['page']
	local page_size = args['page_size'] or 8
	
	local index
	if page then 
		index = (tonumber(page)-1)*page_size
	end

	local res = mail_dao.get_mails(user_code, index, page_size)
	if not res then
		return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "数据库操作失败", msg)
    end
	return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取用户的系统消息成功", res)
end



-- --[[
--     @接口： messages/api/mail/add_user_notice.action?user_code=10000035&type=系统通知&content=这是通知内容
--     @说明： 获取用户的系统消息
-- ]]
-- _API_FUNC.add_mail = function()
-- 	local args = ngx.req.get_uri_args()
-- 	if not args["user_code"] or not args["content"] or args["type"] then
-- 		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "参数异常", "参数[user_code]或[content]或[type]未设置")
-- 	end
-- 	local params = {
-- 		user_code_fk = args["user_code"],
-- 		mail_time = os.date("%Y-%m-%d %H:%M:%S", os.time()),
-- 		mail_type = args["type"],
-- 		content = args["content"],
-- 		is_readed = 0
-- 	}
-- 	local res = mail_dao.add_mail(params)
-- 	if not res then
-- 		return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "数据库写入用户通知消息失败")
-- 	end
-- 	return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "数据库写入用户通知消息成功", res)
-- end

 --[[
	@接口： messages/api/mail/read_mail.action?user_code=10000035&id=10
    @说明： 更新用户的系统消息状态， 设置为已读
]]
_API_FUNC.read_mail = function()
	local args = ngx.req.get_uri_args()
	if not args["user_code"] and not args["id"] then
		return api_data_help.new_failed("user_code or content is not null")
	end
	local params = {
		user_code_fk=args["user_code"],
		id_pk = args["id"],
	}
	local res = mail_dao.read_mail(params)
	if not res then
		return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "数据库操作失败")
    end
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "数据库操作成功", res)
end


--[[
    @接口： messages/api/mail/read_mail.action?user_code=10000035&id=10
    @说明： 删除用户的系统消息
]]
_API_FUNC.delete_mail = function() 
    local args = ngx.req.get_uri_args()
    local user_code = args['user_code']
    local id = args['id']
    if not user_code or not id then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "参数[user_code]或[id]未设置")
    end

    local res, msg = mail_dao.delete_mail(user_code, id)
    if not res then
		return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "数据库操作失败")
    end
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "数据库操作成功", res)
end


--[[
    @接口： messages/api/mail/delete_mail_all.action?user_code=10000035
    @说明： 删除用户全部的系统消息
]]
_API_FUNC.delete_mail_all = function() 
    local args = ngx.req.get_uri_args()
    local user_code = args['user_code']
    if not user_code then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "参数[user_code]未设置")
    end

    local res, msg = mail_dao.delete_mail_all(user_code)
    if not res then
		return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "数据库操作失败", msg)
    end
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "数据库操作成功", res)
end


return _API_FUNC