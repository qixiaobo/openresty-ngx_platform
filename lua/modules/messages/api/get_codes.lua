--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:make_codes.lua
--	version: 0.1 程序结构初始化实现
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right. 
--  获得唯一编号,采用不同的编码方案根据类型制定
--]]

-- 默认采用 get 登录
local _API_FUNC = {
	
}

local uuid_help = require "common.uuid_help"
local redis_help = require "common.db.redis_help"
local incr_help = require "common.incr_help"


--[[
	通用类uuid获取
	example:
	http://127.0.0.1/user/api/make_codes/make_goods_code.action?user_name=steven&password=15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225&phone_number=18913826664&area_code=0086&email=xx@qq.com


]]
_API_FUNC.make_uuid_code = function()
	-- 获得当前是否包含指定的参数
	local args = ngx.req.get_uri_args()


end

--[[
	获得商品唯一编号
	example:
	http://127.0.0.1/user/api/make_codes/make_goods_code.action?user_name=steven&password=15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225&phone_number=18913826664&area_code=0086&email=xx@qq.com


]]
_API_FUNC.make_goods_code = function()
	-- 获得当前是否包含指定的参数
	local args = ngx.req.get_uri_args()


end


--[[
	获得订单唯一编号
	example:
	http://127.0.0.1/user/api/make_codes/make_order_code.action?user_name=steven&password=15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225&phone_number=18913826664&area_code=0086&email=xx@qq.com


]]
_API_FUNC.make_order_code = function()


end

--[[
	获得交易唯一编号
	example:
	http://127.0.0.1/messages/api/make_codes/make_transaction_code.action

]]
_API_FUNC.make_transaction_code = function()
	
	return incr_help.get_time_union_id()
end

 --[[
	创建新用户唯一code
	example:
	http://127.0.0.1/user/api/make_codes/make_transaction_code.action?user_name=steven&password=15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225&phone_number=18913826664&area_code=0086&email=xx@qq.com


]]
_API_FUNC.make_user_code = function()


end


return _API_FUNC