local mysql_db = require "common.db.db_mysql" 
local api_data_help = require "common.api_data_help" 

local _M = {}

--[[
    @url:   
            user/system/statistical_info/active_user_number.action
            ?miniutes=120
    @brief: 
            获取系统活相应时间内的跃人数
    @param:
            [miniutes:string]	时间 单位分钟
    @return:
            {
                "code" : 200, 
                "data":	{
                			"active_number":2
                		},
                "msg" : "获取信息成功."
            } 

--]]
function _M.active_user_number()
	local args = ngx.req.get_uri_args()
    local miniutes = args["miniutes"]
    local m = tonumber(miniutes) 

	if not miniutes or miniutes == '' or m == nil then
		return api_data_help.new(ZS_ERROR_CODE.RE_FAILED,'获取失败, 参数[miniutes], 错误.')
	end

	if m < 0 or m > (24 * 60) then
		m = 24 * 60
	end

	local sql_fmt = [[SELECT id_pk, user_id_fk, login_time FROM t_user_help a,
				(SELECT max( id_pk ) id FROM t_user_help GROUP BY user_id_fk ) b 
				WHERE a.id_pk = b.id and login_time is not null 
				and login_time > SUBDATE(now(),INTERVAL %d minute);]]
	local sql = string.format(sql_fmt, m)
	ngx.log(ngx.ERR, "[active_user_number] sql: ", sql)
    local res, code, err =  mysql_db:exec_once(sql)
    if res then
    	local number = #res
    	ngx.log(ngx.ERR, "active_user_number: ", number)
    	return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS,'获取信息成功.', {active_number = number})
    end

    return api_data_help.new(ZS_ERROR_CODE.RE_FAILED,'获取信息失败, err: '..err)
end


return _M