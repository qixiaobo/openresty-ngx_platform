--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:alipay_page.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  支付宝支付相关接口定义,主要服务器端的主要数据封装以及状态管理
--]]
 
local cjson = require "cjson"
local incr_help = require "common.incr_help" 

local aes = require "common.crypto.aes"
local rsa = require "common.crypto.rsa"
local sign_help = require "common.crypto.sign_help"
local alipay_conf = require "pay.alipay.alipay_conf"
local request_help = require "common.request_help"


local log = ngx.log
local ERR = ngx.ERR



--[[
App支付请求参数说明
app_id	String	是	32	支付宝分配给开发者的应用ID	2014072300007148
method	String	是	128	接口名称	alipay.trade.create
format	String	否	40	仅支持JSON	JSON
charset	String	是	10	请求使用的编码格式，如utf-8,gbk,gb2312等	utf-8
sign_type	String	是	10	商户生成签名字符串所使用的签名算法类型，目前支持RSA2和RSA，推荐使用RSA2	RSA2
sign	String	是	344	商户请求参数的签名串，详见签名	详见示例
timestamp	String	是	19	发送请求的时间，格式"yyyy-MM-dd HH:mm:ss"	2014-07-24 03:07:50
version	String	是	3	调用的接口版本，固定为：1.0	1.0
notify_url	String	否	256	支付宝服务器主动通知商户服务器里指定的页面http/https路径。	http://api.test.alipay.net/atinterface/receive_notify.htm
app_auth_token	String	否	40	详见应用授权概述	
biz_content	String	是		请求参数的集合，最大长度不限，除公共参数外所有请求参数都必须放在这个参数中传递，具体参照各产品快速接入文档	

]]
local ALIPAY_METHOD = {
	ALIPAY_PC = "alipay.trade.page.pay",
	ALIPAY_WAP = "alipay.trade.wap.pay",
	ALIPAY_APP = "alipay.trade.app.pay",
}

local ALIPAY_PRODUCT_CODE = {
	ALIPAY_PC = "FAST_INSTANT_TRADE_PAY",
	ALIPAY_WAP = "QUICK_WAP_WAY",
	ALIPAY_APP = "QUICK_MSECURITY_PAY", 
}

--[[ 支付宝电脑支付必须的key列表
	用于检查是否数据错误或者遗失
 ]]
local ALIPAY_REQUEST_KEY = {
	"app_id",	-- 必须 初始化时必须添加,否则debug时,系统报错
	"method",	-- 必须 系统默认字段为pay
	-- format = "json",
	"charset",	-- 必须
	"sign_type",	-- 必须
	"sign",			-- 必须 但是不用初始化
	"timestamp",		-- 必须 创建时系统创建
	"version",	-- 必须
	"biz_content",	-- 必须
	"notify_url",	
}

-- ali支付请求参数说明
local ALIPAY_REQUEST_T = {
	app_id = nil,	-- 必须 初始化时必须添加,否则debug时,系统报错
	method = "alipay.trade.page.pay",	-- 必须 系统默认字段为pay
	-- format = "json",
	charset = "utf-8",	-- 必须
	sign_type = "RSA2",	-- 必须
	sign = nil,			-- 必须 但是不用初始化
	timestamp = nil,		-- 必须 创建时系统创建
	version = "1.0",	-- 必须
	biz_content = {},	-- 必须
	notify_url = "",	
}


 
--[[
	 初始化一个默认的参数对象,该对象主要包括 必须的初始化数据对象
]]
ALIPAY_REQUEST_T.new = function( _recharge_type )
	-- body
	if not _recharge_type then _recharge_type = "ALIPAY_PC" end
	return { 
		method = ALIPAY_METHOD[_recharge_type],	-- 必须 系统默认字段为pay 
		charset = "utf-8",	-- 必须
		sign_type = "RSA2",	-- 必须 
		timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time()),	-- 必须 创建时自动复制
		version = "1.0",	-- 必须  
		notify_url =  alipay_conf.YU_NAME..alipay_conf.NOTIFY_URL,
	}
end

local BIZ_CONTENT = {
	-- subject	String	是	256	商品的标题/交易标题/订单标题/订单关键字等。	大乐透
	subject = "",
	-- out_trade_no	String	是	64	商户网站唯一订单号	70501111111S001111119
	out_trade_no = "",
	-- timeout_express	String	否	6	该笔订单允许的最晚付款时间，逾期将关闭交易。取值范围：1m～15d。m-分钟，h-小时，d-天，1c-当天（1c-当天的情况下，无论交易何时创建，都在0点关闭）。 该参数数值不接受小数点， 如 1.5h，可转换为 90m。
	-- 注：若为空，则默认为15d。	90m
	timeout_express = "1m",
	-- total_amount	String	是	9	订单总金额，单位为元，精确到小数点后两位，取值范围[0.01,100000000]
	total_amount = "0.01",
	-- product_code	String	是	64	销售产品码，商家和支付宝签约的产品码，为固定值 QUICK_WAP_WAY
	product_code = "QUICK_WAP_WAY", 
}  

 
local _M = {
	alipay_gateway = "https://openapi.alipay.com/gateway.do",
	rsa_private_key = "",
	-- rsa_public_key = "",
	sign_type = "RSA2",
	algorithm = "SHA256"
}
_M.__index = _M 
   
--[[
-- build_body 创建支付宝请求参数 
-- example 
-- @param  wu 
-- @return true 表示post； false 表示 get 请求
--]] 
_M.build_body = function(_self) 
	local un_signed_str = sign_help.make_sign_str_sort(_self.pay_body) 
	local algorithm = _self.algorithm 
	local private_cli = rsa:new_rsa_private(_self.rsa_private_key, algorithm)
 
	local signed_str = private_cli:sign(un_signed_str) 
	local base64_signed_str = ngx.encode_base64(signed_str)
 
	_self.pay_body.sign = base64_signed_str 
	return sign_help.make_urlencode_str(_self.pay_body)
end

_M.redirect2alipay = function(_self)
	-- body  
	local body_str = _self:build_body()  
	ngx.redirect(_self.alipay_gateway.."?"..body_str) 
end

--[[
    创建支付引用对象
    _property 			用户组装的数据集合  
    _rsa_private_key 	用户私钥
-- @param  wu 
-- @return true 表示post； false 表示 get 请求
]]

--[[
--  new 创建支付引用对象 
-- example:

-- @param  _pay_type  支付类型 支付宝支付主要包含三类支付,手机,pc网页,手机网页
-- @param  _rsa_private_key 私钥key
-- @return 指定类型的支付对象
--]] 
function _M:new(_property, _pay_type, _rsa_private_key,_debug) 
    local impl = setmetatable({}, _M) 
    impl.pay_body = ALIPAY_REQUEST_T.new(_pay_type)
    impl.rsa_private_key =  _rsa_private_key and _rsa_private_key or alipay_conf.RSA_PRIVATE_KEY

    if _property and type(_property) == "table" then
        for k,v in pairs (_property) do
        	 impl.pay_body[k]=v
        end  
    end    
    local _pay_body = impl.pay_body
 	if _debug then
 		if not _pay_body.app_id then
 			log(ERR,"app_id can not be nil")
 			ngx.exit(500)
 		elseif not _pay_body.biz_content  then 
 			log(ERR,"biz_content can not be nil")
 			ngx.exit(500)
		elseif not _pay_body.biz_content.subject   then 
 			log(ERR,"biz_content.subject can not be nil")
 			ngx.exit(500)
		elseif not _pay_body.biz_content.out_trade_no   then 
 			log(ERR,"biz_content.out_trade_no can not be nil")
 			ngx.exit(500) 			
		elseif not _pay_body.biz_content.total_amount   then 
 			log(ERR,"biz_content.total_amount can not be nil")
 			ngx.exit(500) 		
		elseif not _pay_body.biz_content.product_code   then 
 			log(ERR,"biz_content.product_code can not be nil")
 			ngx.exit(500) 	 
 		end
 	end    
 	impl.pay_body.biz_content.product_code = ALIPAY_PRODUCT_CODE[_pay_type]
    return impl
end


--[[
	获得订单功能 数据
]]
function _M:get_trade_info()
	return self.pay_body
end

function _M:get_signed_str()
	return self:build_body()  
end


return _M