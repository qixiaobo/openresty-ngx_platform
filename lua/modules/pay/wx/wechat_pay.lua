--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:wechat_pay.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  微信支付调用接口,用户访问该页面,系统通过微信回调产生二维码数据,订单等各种数据

--]]

local lub    = require 'lub'
local lut    = require 'lut'
local xml    = require 'xml'
local cjson = require "cjson"
local incr_help = require "common.incr_help"   
local uuid_help = require "common.uuid_help"
local rapidxml_help = require "common.rapidxml_help"
local sign_help = require "common.crypto.sign_help"
local redis_help = require "common.db.redis_help" 

local log = ngx.log
local ERR = ngx.ERR
local ngx_time = ngx.time
local ngx_md5 = ngx.md5
local string_upper = string.upper

 
--[[
字段名		变量名	必填	类型	示例值	描述
公众账号ID	appid	是	String(32)	wxd678efh567hg6787	微信分配的公众账号ID（企业号corpid即为此appId）
商户号		mch_id	是	String(32)	1230000109	微信支付分配的商户号
设备号		device_info	否	String(32)	013467007045764	终端设备号(门店号或收银设备ID)，注意：PC网页或公众号内支付请传"WEB"
随机字符串	nonce_str	是	String(32)	5K8264ILTKCH16CQ2502SI8ZNMTM67VS	随机字符串，不长于32位。推荐随机数生成算法
签名			sign	是	String(32)	C380BEC2BFD727A4B6845133519F3AD6	签名，详见签名生成算法
签名类型		sign_type	否	String(32)	HMAC-SHA256	签名类型，目前支持HMAC-SHA256和MD5，默认为MD5
商品描述		body	是	String(128)	腾讯充值中心-QQ会员充值	商品简单描述，该字段须严格按照规范传递，具体请见参数规定
商品详情		detail	否	String(6000)		单品优惠字段(暂未上线)
附加数据		attach	否	String(127)	深圳分店	附加数据，在查询API和支付通知中原样返回，该字段主要用于商户携带订单的自定义数据
商户订单号	out_trade_no	是	String(32)	20150806125346	商户系统内部的订单号,32个字符内、可包含字母, 其他说明见商户订单号
货币类型		fee_type	否	String(16)	CNY	符合ISO 4217标准的三位字母代码，默认人民币：CNY，其他值列表详见货币类型
总金额		total_fee	是	Int	888	订单总金额，单位为分，详见支付金额
终端IP		spbill_create_ip	是	String(16)	123.12.12.123	必须传正确的用户端IP,详见获取用户ip指引
交易起始时间	time_start	否	String(14)	20091225091010	订单生成时间，格式为yyyyMMddHHmmss，如2009年12月25日9点10分10秒表示为20091225091010。其他详见时间规则
交易结束时间	time_expire	否	String(14)	20091227091010	
订单失效时间，格式为yyyyMMddHHmmss，如2009年12月27日9点10分10秒表示为20091227091010。其他详见时间规则
注意：最短失效时间间隔必须大于5分钟
商品标记		goods_tag	否	String(32)	WXG	商品标记，代金券或立减优惠功能的参数，说明详见代金券或立减优惠
通知地址		notify_url	是	String(256)	http://www.weixin.qq.com/wxpay/pay.php	接收微信支付异步通知回调地址，通知url必须为直接可访问的url，不能携带参数。
交易类型		trade_type	是	String(16)	MWEB	H5支付的交易类型为MWEB
商品ID		product_id	否	String(32)	12235413214070356458058	trade_type=NATIVE，此参数必传。此id为二维码中包含的商品ID，商户自行定义。
指定支付方式	limit_pay	否	String(32)	no_credit	no_credit--指定不能使用信用卡支付
用户标识		openid	否	String(128)	oUpF8uMuAJO_M2pxb1Q9zNjWeS6o	trade_type=JSAPI，此参数必传，用户在商户appid下的唯一标识。openid如何获取，可参考【获取openid】。企业号请使用【企业号OAuth2.0接口】获取企业号内成员userid，再调用【企业号userid转openid接口】进行转换
场景信息		scene_info	是	String(256)	//IOS移动应用
{"h5_info": {"type":"IOS","app_name": "王者荣耀","bundle_id": "com.tencent.wzryIOS"}}

//安卓移动应用
{"h5_info": {"type":"Android","app_name": "王者荣耀","package_name": "com.tencent.tmgp.sgame"}}

//WAP网站应用
{"h5_info": {"type":"Wap","wap_url": "https://pay.qq.com","wap_name": "腾讯充值"}}	该字段用于上报支付的场景信息,针对H5支付有以下三种场景,请根据对应场景上报,H5支付不建议在APP端使用，针对场景1，2请接入APP支付，不然可能会出现兼容性问题

1，IOS移动应用
{"h5_info": //h5支付固定传"h5_info" 
    {"type": "",  //场景类型
     "app_name": "",  //应用名
     "bundle_id": ""  //bundle_id
     }
}

2，安卓移动应用
{"h5_info": //h5支付固定传"h5_info" 
    {"type": "",  //场景类型
     "app_name": "",  //应用名
     "package_name": ""  //包名
     }
}

3，WAP网站应用
{"h5_info": //h5支付固定传"h5_info" 
   {"type": "",  //场景类型
    "wap_url": "",//WAP网站URL地址
    "wap_name": ""  //WAP 网站名
    }
}


]]
-- 微信统一下单接口
local WECHAT_UNION_URL = "https://api.mch.weixin.qq.com/pay/unifiedorder"


-- 微信支付接口

--[[
	将接口做成通用的数据结构
	根据域名地址进行获取指定绑定的appid, mch_id ,用户自定义回调地址

	-- 配置商户信息
	_M.appid = "  商户appid  "
	_M.mch_id = "  商户mch_id  "
	_M.notify_url = "http://服务器地址/pay/wx/notify" -- 接收微信支付异步通知回调地址，通知url必须为直接可访问的url，不能携带参数
	_M.spbill_create_ip = "服务器IP地址" -- 服务器IP地址
	_M.private_key = "*****************" -- 商户在Api安全中设置的私钥
 
]]

local _M = {
	
}

-- app id
local appid = "wx63e89f7c5e560d67"
-- 商家 id
local mch_id = "1496204352"

-- 随机字符串
local nonce_str = uuid_help:get64() 


-- 商品描述
local body =  "chongzhi"
-- 商户订单号
local out_trade_no = incr_help.get_uuid() 

-- 标价金额
local total_fee=1

-- 终端IP
local spbill_create_ip ="49.77.232.106"

-- 通知地址
local notify_url = "http://www.zhengsutec.com/pay/wx/wechat_pay_cb.do"
  
-- 交易类型 JSAPI NATIVE APP
local trade_type = "JSAPI"
 
local private_key = "n4psYrKRVyK5R25Yvyf0OG6ozPXS32wB"

 local headers=ngx.req.get_headers()
local cli_ip=headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"



local wx_pre_order = {
-- app id
	appid = "wx63e89f7c5e560d67" ,

-- 商家 id
	mch_id = "1496204352" ,

-- 随机字符串
	nonce_str = uuid_help:get64() , 

-- 商品描述
	body =  "chongzhi" ,

-- 商户订单号
	out_trade_no = incr_help.get_uuid() ,

-- 标价金额
	total_fee = "1" ,

-- 终端IP
	spbill_create_ip = cli_ip,

-- 通知地址
	notify_url = "http://goodtime.vip/pay/wx/wechat_pay_cb.do" ,
  
-- 交易类型 JSAPI NATIVE APP MWEB
	trade_type = "MWEB" ,
	scene_info = '{"h5_info":{"type":"Wap","wap_url":"http://goodtime.vip","wap_name":"充值测试"}}',
} 

local test_xml=[[<xml>
	   <appid>wx2421b1c4370ec43b</appid>
	   <attach>支付测试</attach>
	   <body>JSAPI支付测试</body>
	   <mch_id>10000100</mch_id>
	   <detail>{ "goods_detail":[ { "goods_id":"iphone6s_16G", "wxpay_goods_id":"1001", "goods_name":"iPhone6s 16G", "quantity":1, "price":528800, "goods_category":"123456", "body":"苹果手机" }, { "goods_id":"iphone6s_32G", "wxpay_goods_id":"1002", "goods_name":"iPhone6s 32G", "quantity":1, "price":608800, "goods_category":"123789", "body":"苹果手机" } ] }</detail>
	   <nonce_str>1add1a30ac87aa2db72f57a2375d8fec</nonce_str>
	   <notify_url>http://wxpay.wxutil.com/pub_v2/pay/notify.v2.php</notify_url>
	   <openid>oUpF8uMuAJO_M2pxb1Q9zNjWeS6o</openid>
	   <out_trade_no>1415659990</out_trade_no>
	   <spbill_create_ip>14.23.150.211</spbill_create_ip>
	   <total_fee>1</total_fee>
	   <trade_type>JSAPI</trade_type>
	   <sign>0CB01533B8C1EF103065174F50BCA001</sign>
	</xml>]]


-- appid：	wxd930ea5d5a258f4f

-- mch_id：	10000100

-- device_info：	1000

-- body：	test

-- nonce_str：	ibuaiVcKdpRxkhJA

 
	-- local xmlimpl = rapidxml_help:new(test_xml) 
	-- local root = xmlimpl:get_key("xml") 
	-- local key_map = {} 
	-- local key_map_index = 1
	-- for k,v in pairs(root)  do  
	-- 	if root[k].xml and root[k].xml ~= "sign" then  
	-- 		key_map[root[k].xml] = root[k][1] 
	-- 		ngx.log(ngx.ERR,"k: ",root[k].xml," v: ",root[k][1] )
	-- 	end
	-- end  
-- ngx.log(ngx.ERR,"sign is ", root.sign,"  ",cjson.encode(key_map))
-- root.sign = nil
 
local wx_pay_str = sign_help.make_sign_str_sort(wx_pre_order)
wx_pay_str = wx_pay_str.."&key="..private_key
 

local signed_str = string_upper(ngx_md5(wx_pay_str))
wx_pre_order.sign = signed_str
 

-- local wx_sign_compare = function ( v1,v2 )
-- 	-- body
-- 	local v1_str = v1[1]
-- 	local v2_str = v2[1]
-- 	if string.sub(v1_str,1,1)>string.sub(v2_str,1,1) then 
-- 		return false
-- 	else
-- 		return true
-- 	end
-- end
-- -- wx_sign_xml 按照微信服务器端结构,验证xml数据结构,使用的是md5 hash
-- local function wx_sign_xml( _xml,_private_key )
-- 	-- body
	
-- 	local xmlimpl = rapidxml_help:new(_xml) 
-- 	local root = xmlimpl:get_key("xml") 
-- 	local key_map = {} 
-- 	local key_map_index = 1
-- 	for k,v in pairs(root)  do  
-- 		if root[k].xml and root[k].xml ~= "sign" then  
-- 			key_map[key_map_index] = {root[k].xml,root[k][1]}
-- 			key_map_index = key_map_index+1
-- 		end
-- 	end  
-- 	table.sort(key_map,wx_sign_compare) 
-- 	local stringa = ""
-- 	-- for i=1,#key_map do
-- 	-- 	stringa=stringa..key_map[i].key_name.."="..key_map[i][key_map[i].key_name].."&" 
-- 	-- end
-- 	stringa = stringa.."key=".._private_key 
-- 	local sign_str = string_upper(ngx_md5(stringa)) 
-- 	return sign_str
-- end

-- -- wx_sign_json 将json数据按照微信服务器的验证结构进行验证,使用的是md5 hash
-- local function wx_sign_json( _json,_private_key )
-- 	-- body 
-- 	local root = _json
-- 	local key_map = {}
-- 	local key_map_index = 1
-- 	for k,v in pairs(root)  do  
-- 		if k and k ~= "sign" then 
-- 			key_map[key_map_index] = {k,v}
-- 			key_map_index = key_map_index+1
-- 		end
-- 	end 
-- 	table.sort(key_map,wx_sign_compare) 
-- 	ngx.log(ngx.ERR,cjson.encode(key_map))

-- 	local stringa = ""
-- 	for i=1,#key_map do
-- 		stringa=stringa..key_map[i][1].."="..key_map[i][2].."&" 
-- 	end
-- 	stringa = stringa.."key=".._private_key 
-- 	local sign_str = string_upper(ngx_md5(stringa)) 
-- 	return sign_str
-- end
-- -- 将json 转为 xml
local make_post_xml = function ( _json )
	-- body
	local root = _json
	local xmlimpl = rapidxml_help:new("<xml></xml>")  
	for k,v in pairs(root)  do 
		   
		-- if type(v) == "string" then
		-- 	_v =   v --"![CDATA["..v.."]]"
		-- else
		-- 	_v = tostring(v)
		-- end

		xmlimpl:set_key(k,tostring(v))
	end 
	return xmlimpl:save2str()
end

-- local make_post_xml1 = function ( _json )
-- 	-- body
-- 	local root = _json
-- 	local xml_str = "<xml>" 
-- 	for k,v in pairs(root)  do 

-- 		local _v = "" 
-- 		if type(v) == "string" then
-- 			_v = "![CDATA["..v.."]]"
-- 		else
-- 			_v = v
-- 		end
-- 		xml_str = xml_str..string.format("<%s>%s</%s>",k,_v,k)
		 
-- 	end 
-- 	xml_str = xml_str.."</xml>"
-- 	return xml_str
-- end


-- local test_data=[[
-- 	<xml>
-- 	<appid>%s</appid> 
-- 	<attach>支付测试</attach>
-- 	<body>H5支付测试</body>
-- 	<mch_id>%s</mch_id>
-- 	<nonce_str>%s</nonce_str>
-- 	<notify_url>%s</notify_url>
-- 	<out_trade_no>%s</out_trade_no>
-- 	<spbill_create_ip>%s</spbill_create_ip>
-- 	<total_fee>%d</total_fee>
-- 	<trade_type>%s</trade_type>
-- 	<scene_info>%s</scene_info>
-- 	<sign>%s</sign>
-- 	</xml>
-- ]]
  
-- local json_obj={
-- 	appid=appid,
-- 	attach = "支付测试",
-- 	body="H5支付测试",
-- 	mch_id=mch_id,
-- 	nonce_str= nonce_str,
-- 	notify_url=notify_url,
-- 	out_trade_no=out_trade_no,
-- 	spbill_create_ip=spbill_create_ip,
-- 	total_fee=total_fee,
--     trade_type=trade_type, 
--     scene_info=scene_info,  
-- } 
 

local xml_str = make_post_xml(wx_pre_order) 

-- ngx.redirect(WECHAT_UNION_URL.."?"..body_str) 

-- -- 获取用户的token授权信息
local http = require("resty.http") 
	local httpc = http.new() 
	local timeout = 30000

httpc:set_timeout(timeout)
 
 
local res, err_ = httpc:request_uri(WECHAT_UNION_URL, {
  method = "POST",
  ssl_verify = false, -- 进行https访问
  body=xml_str,
  headers = {
          ["Content-Type"] = "application/x-www-form-urlencoded",
        }		
	})

-- 返回失败, 通知前端 服务器业务块
if not res or res.status ~= 200 then    
    ngx.log(ngx.ERR, "wechat get code error! ", err) 
    return  
else 
	ngx.log(ngx.ERR,"get from wechat:",res.body)
end
-- local res = {body=[[
-- 	<xml><return_code>SUCCESS</return_code>
-- 	<return_msg>OK</return_msg>
-- 	<appid>wx63e89f7c5e560d67</appid>
-- 	<mch_id>1496204352</mch_id>
-- 	<nonce_str>1496204352</nonce_str>
-- 	<sign>33C279A8CFBA3E429473C5AE1713A8FD</sign>
-- 	<result_code>SUCCESS</result_code>
-- 	<prepay_id>wx20180126143557ce7d0073d50638702603</prepay_id>
-- 	<trade_type>MWEB</trade_type>
-- 	<mweb_url>https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?prepay_id=wx20180126143557ce7d0073d50638702603&package=3871102977</mweb_url>
-- 	</xml>
-- ]]}
local xmlimpl = rapidxml_help:new(res.body)  


local return_code = xmlimpl:get_key("return_code") 

if not return_code or return_code ~= "SUCCESS" then
	-- 调用错误处理
	 
else
	local result_code =  xmlimpl:get_key("result_code")
	if not result_code or result_code ~= "SUCCESS" then
		-- 调用错误处理

	end

	-- 执行充值页面调用

	local mweb_url = xmlimpl:get_key("mweb_url")
	ngx.log(ngx.ERR,"-------",cjson.encode(mweb_url))
	if not mweb_url then
     -- 调用错误处理
	end

	local redirect_url = "http://goodtime.vip/wap/index.html"
	mweb_url = mweb_url.."&redirect_url="..ngx.escape_uri(redirect_url)
	ngx.log(ngx.ERR,"-------",mweb_url)
	-- Referer:http://goodtime.vip/pay/wx/wechat_pay.shtml
	ngx.req.set_header("Referer", "http://goodtime.vip/pay/wx/wechat_pay.shtml")
	ngx.redirect(mweb_url) 



	-- local sign = require "admin.auth.sign_in"
	-- local cjson  = require "cjson"  
	-- local template = require "resty.template"
	-- template.render("demo/wechat_pay.html", {  mweb_url = mweb_url })

end 
 