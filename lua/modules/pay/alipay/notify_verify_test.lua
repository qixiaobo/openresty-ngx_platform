
local request_help = require "common.request_help"
local cjson = require "cjson"
local aes = require "common.crypto.aes"
local rsa = require "common.crypto.rsa"
local sign_help = require "common.crypto.sign_help"
local alipay_conf = require "pay.alipay.alipay_conf"
local redis_help = require "common.db.redis_help" 

local args = cjson.decode([[
{"gmt_create":"2018-01-13 09:14:08","sign":"xheeeXZJzx\/DA05dWbpccYdimtA81xyy5lmH1ALGuC4eJQgqi6IuICMhSCKkaQPmlwCAma4am0E\/CdR5hq4lOHwiI7R+s2qRZdG9foSzt5lNZlW2rTjLs+o4ngHrkEvDywbH1XDFYOMCarpgv1k92Gfd1pZHYWoFJbwHaEw+y6lyprvJEYKrBK1U8VyFSaJnQN\/5T0dd3FmBf\/\/Qbu+vkLjK8AtAsGx9\/P76yU8USK+JO7QOAPAzWRQV7PFSzX0NuYok\/IP9KcLnjtvh9TB2YqOr1CNGlqY7sYHs4\/zNCK4g6YQEzn16sraQ2ruxjC444pTJeG+NRMs8D\/hpmQK6rA==","trade_status":"TRADE_SUCCESS","trade_no":"2018011321001004970277421746","fund_bill_list":"[{\"amount\":\"0.10\",\"fundChannel\":\"ALIPAYACCOUNT\"}]","charset":"utf-8","auth_app_id":"2017122601230607","receipt_amount":"0.10","notify_id":"833c973ac59aa4bbe5e2bcbd264a189nhi","app_id":"2017122601230607","buyer_pay_amount":"0.10","buyer_id":"2088202872271975","out_trade_no":"201801130913224261971800007","invoice_amount":"0.10","version":"1.0","sign_type":"RSA2","subject":"充值测试","notify_time":"2018-01-13 09:14:12","gmt_payment":"2018-01-13 09:14:12","seller_id":"2088921272720486","total_amount":"0.10","notify_type":"trade_status_sync","point_amount":"0.00"}]])

ngx.log(ngx.ERR,'--------充值回调-验证开始-------',cjson.encode(args))
 
for k,v in pairs(args) do
	ngx.say(k..": "..v)
end


local signed_str_ali = ngx.decode_base64(args.sign)


-- ngx.say(signed_str_ali)
args.sign = nil
args.sign_type = nil
-- 生成充值记录写入数据库
-- 验证是否正确 
local sort_str = sign_help.make_sign_str_sort(args)  

ngx.log(ngx.ERR,'---  排序之后的字符串-------',sort_str )

local algorithm = "SHA256" 
local public_cli =  rsa:new_rsa_public(alipay_conf.ALIPAY_PUBLIC_KEY, algorithm)
local res = sign_help.rsa_verify(sort_str, signed_str_ali, alipay_conf.ALIPAY_PUBLIC_KEY, algorithm)
if not res then
	ngx.log(ngx.ERR,'--------充值回调-验证失败-------',sort_str )
	return
end



ngx.log(ngx.ERR,'--------充值回调-结束-------')

-- ngx.say(sort_str)
-- local test_signed_str = sign_help.rsa_sign(sort_str, alipay_conf.RSA_PRIVATE_KEY,algorithm)
-- ngx.say(test_signed_str)
-- ngx.say(alipay_conf.RSA_PUBLIC_KEY)
-- local res = sign_help.rsa_verify(sort_str,ngx.decode_base64(test_signed_str),alipay_conf.RSA_PUBLIC_KEY,algorithm)
-- ngx.say(res)
 
