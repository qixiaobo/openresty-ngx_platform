local api_data_help = require "common.api_data_help" 
local sys_msg_dao = require "system_messages.model.message_dao"

local _M = {}

--[[
    @brief: 
            获取所有消息记录
    @param: 
    @return: 
            	{
					"code" 	: 200,
					"data" 	: {消息内容},
					"msg"	: "获取消息成功"
				}    
]]
function _M.get_all_messages()
	local res, err = sys_msg_dao.get_msg_by_condition({})
	if not res then
		return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "获取消息失败, "..err)
	end

	return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS,'获取消息成功.', err)
end



return _M