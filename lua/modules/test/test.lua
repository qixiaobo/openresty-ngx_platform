-- local session = require "resty.session".open()

-- session.data.name = "OpenResty qwqew222eFan"
-- session:save()

-- if session.present then
-- 	local name = session.data.name or "Anonymous"
-- 	ngx.say("name: "..name)
-- 	ngx.say("session.id: "..ngx.encode_base64(session.id))
-- else
-- 	session.data.name = "OpenResty Fan"
-- 	local ok ,msg = session:save()
-- 	if ok then
-- 		ngx.say("save ok. ")
-- 	else
-- 		ngx.say("save fail. msg: "..msg)
-- 	end
-- 	ngx.say("present: "..(session.present or "nil"))
-- 	ngx.say("session.id: "..ngx.encode_base64(session.id))
-- end

--[[
1、记录is_login ip
2、is_login == true; cmp ip; if same then next; else 

]]

-- local tbl = {
-- 	bz.user.register = "test123"
-- }
-- ngx.say(tbl['bz.user.register'])


--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:sign_test.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  测试用户接入的api签名测试服务
--  

|参数名 | 字段 | 类型\(最大长度\) | 是否必须 | 备注 | 用例 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 渠道id | app\_id | string\(32\) | 是 | 系统为渠道分配的应用id | |
| 玩家名 | user\_name | string\(32\) | 是 | 玩家名称，玩家渠道唯一ID | |
| 编码 | charset | string\(32\) | 否 | 默认使用utf-8，其他编码作为二期支持 | |
| 签名 | sign | string\(4096\) | 是 | 除去签名字段外的字符串，通过签名规则生成的字符串进行使用用户本地的私钥签名 | |
| 版本号 | version | string\(8\) | 是 | 不同版本对应的约束和条件不同，系统为了保持向上兼容，对版本进行映射和业务内部处理 | v1.0 |
| 时间戳 | timestamp | string\(32\) | 是 | 当前时间 格式"yyyy-MM-dd HH:mm:ss" | 2018-03-24 08:08:08 |
| 签名方式 | sign\_type | string\(32\) | 是 | 默认签名方式为RSA2，即SHA256 | |
| 数据组装格式 | data\_format | string\(32\) | 否 | 默认为json，未来可支持protobuf等类型 | json,protobuf |
| 方法 | method | string\(32\) | 是 | 该功能方法管理 | bz.user.register |
| 业务详情 | biz\_details | string\(n\) | 是 | 长度不限 | |


--]]
local cjson = require "cjson" 
local aes = require "common.crypto.aes"
local rsa = require "common.crypto.rsa"
local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help"
local redis_help = require "common.db.redis_help"
local sign_help = require "common.crypto.sign_help"

local RSA_PRIV_KEY = [[
-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQCfWKhQk5YZ5k2DQnszH8u8m+8cAM0Yp17qdWZedede64SavFtM
FcDbfpnCsEc4rANUiKjxpYYsg29kSSnNXAja1TX4+8cTigiIoZCLEyCl8w33gKq5
tG1PNAUo4I4+mFCmYp1AAAj6GqPL/kBaEZV5bAMu9pmO4qVZyagXdQDj1QIDAQAB
AoGBAJega3lRFvHKPlP6vPTm+p2c3CiPcppVGXKNCD42f1XJUsNTHKUHxh6XF4U0
7HC27exQpkJbOZO99g89t3NccmcZPOCCz4aN0LcKv9oVZQz3Avz6aYreSESwLPqy
AgmJEvuVe/cdwkhjAvIcbwc4rnI3OBRHXmy2h3SmO0Gkx3D5AkEAyvTrrBxDCQeW
S4oI2pnalHyLi1apDI/Wn76oNKW/dQ36SPcqMLTzGmdfxViUhh19ySV5id8AddbE
/b72yQLCuwJBAMj97VFPInOwm2SaWm3tw60fbJOXxuWLC6ltEfqAMFcv94ZT/Vpg
nv93jkF9DLQC/CWHbjZbvtYTlzpevxYL8q8CQHiAKHkcopR2475f61fXJ1coBzYo
suAZesWHzpjLnDwkm2i9D1ix5vDTVaJ3MF/cnLVTwbChLcXJSVabDi1UrUcCQAmn
iNq6/mCoPw6aC3X0Uc3jEIgWZktoXmsI/jAWMDw/5ZfiOO06bui+iWrD4vRSoGH9
G2IpDgWic0Uuf+dDM6kCQF2/UbL6MZKDC4rVeFF3vJh7EScfmfssQ/eVEz637N06
2pzSvvB4xq6Gt9VwoGVNsn5r/K6AbT+rmewW57Jo7pg=
-----END RSA PRIVATE KEY-----
]]

--公钥
local RSA_PUBLIC_KEY = [[
-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAJ9YqFCTlhnmTYNCezMfy7yb7xwAzRinXup1Zl51517rhJq8W0wVwNt+
mcKwRzisA1SIqPGlhiyDb2RJKc1cCNrVNfj7xxOKCIihkIsTIKXzDfeAqrm0bU80
BSjgjj6YUKZinUAACPoao8v+QFoRlXlsAy72mY7ipVnJqBd1AOPVAgMBAAE=
-----END RSA PUBLIC KEY-----
]]
local app_id = "200000000000"
-- 读取redis 查询 rsa_public_key
local redis_cli = redis_help:new()
if not redis_cli then
	ngx.log(ngx.ERR,"redis new error!!!") 
	return api_data_help.new_failed("系统繁忙,请稍后再试!")
end
local RSA_KEY_PRE = "TEST_RSA_KEY_PRE"
local res,err = redis_cli:hset(RSA_KEY_PRE..app_id,"public_key",RSA_PUBLIC_KEY)
if not res then
	ngx.log(ngx.ERR,"redis get error!!!",err) 
end

local post_data = {
	app_id = app_id,
	user_name = "test",
	charset = "utf-8",
	version = "v1.0",
	timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time()),
	sign_type = "RSA2",
	method = "test.test1",
	biz_details = "XXXX",
}

local un_signed_str = sign_help.make_sign_str_sort(post_data) 
-- ngx.say(un_signed_str)
local algorithm = "SHA256"
local private_cli = rsa:new_rsa_private(RSA_PRIV_KEY, algorithm)
 

local signed_str = private_cli:sign(un_signed_str) 
local base64_signed_str = ngx.encode_base64(signed_str)
post_data.sign = base64_signed_str


-- ngx.say(cjson.encode(post_data))

-- local sign_base64_str = post_data.sign
-- local sign_str = ngx.decode_base64(sign_base64_str)

-- ngx.say(sign_str)
-- post_data.sign = nil
-- -- -- 6 读取 
-- local un_signed_str1 = sign_help.make_sign_str_sort(post_data) 
-- ngx.say(un_signed_str1 == un_signed_str)
-- local algorithm = "SHA256"
-- local public_cli = rsa:new_rsa_public(RSA_PUBLIC_KEY, algorithm)

-- local res = public_cli:verify(un_signed_str,sign_str) 
-- if not res then
-- 	-- return api_data_help.new_failed("验证失败,请检查参数!") 
-- end
-- ngx.say(res)

ngx.say(cjson.encode(post_data))
 
-- -- 获取用户的token授权信息
local http = require("resty.http") 
local httpc = http.new() 
local timeout = 30000

httpc:set_timeout(timeout) 

local res, err_ = httpc:request_uri("http://127.0.0.1/game_platform/api/gateway.do", {
  method = "POST",
  ssl_verify = false, -- 进行https访问
  body = cjson.encode(post_data),
  headers = {
          -- ["Content-Type"] = "application/x-www-form-urlencoded",
          ["Content-Type"] = "application/json",
        }		
	})

-- 返回失败, 通知前端 服务器业务块
if not res or res.status ~= 200 then    
    ngx.log(ngx.ERR, "wechat get code error! ", err) 
    return  
else 
	ngx.log(ngx.ERR,"get from wechat:",res.body)
	ngx.say("ret: "..res.body)
end






