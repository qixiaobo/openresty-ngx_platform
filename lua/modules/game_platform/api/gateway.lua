--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:gateway.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  渠道接入函数入口,子功能函数通过传递参数方法进行分发处理
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
 
local method_conf = require "gapi_platform.method_conf"
-- 获得当前域名
local _domain_name = ngx.var.host

-- 获得当前 post 有效数据
local post_data = request_help.get_post_json()
if not post_data then
	return 
end 
-- 1 判断必要字段是否正确

if not post_data.app_id or not post_data.user_name
	or not post_data.sign or not post_data.version 
	or not post_data.timestamp or not post_data.sign_type
	or not post_data.method or not post_data.biz_details then

	ngx.say( api_data_help.new_failed("参数为空!"))
end


-- 2 读取当前数据的方法, 不同方法执行不同的函数服务



-- 3 版本号判断
local version = post_data.version
if version ~= "v1.0" then
	ngx.say(api_data_help.new_failed("参数错误!"))
end

-- 4 判断时间是否超时


-- 5 读取 商家 app_id 读取该对应app_id 的公钥
local app_id = post_data.app_id
-- 读取redis 查询 rsa_public_key
local redis_cli = redis_help:new()
if not redis_cli then
	ngx.log(ngx.ERR,"redis new error!!!") 
	ngx.say(api_data_help.new_failed("系统繁忙,请稍后再试!")) 
end
local RSA_KEY_PRE = "TEST_RSA_KEY_PRE"
local res,err = redis_cli:hget(RSA_KEY_PRE..app_id,"public_key")
if not res then
	ngx.log(ngx.ERR,"redis get error!!!",err) 
end

local sign_base64_str = post_data.sign
local sign_str = ngx.decode_base64(sign_base64_str)
post_data.sign = nil
-- 6 读取 
local un_signed_str = sign_help.make_sign_str_sort(post_data) 

local algorithm = "SHA256"
local public_cli = rsa:new_rsa_public(res, algorithm)

local res = public_cli:verify(un_signed_str, sign_str) 
if not res then
	ngx.say(api_data_help.new_failed("验证失败,请检查参数!") ) 
end

-- ngx.say("ok!!!")
--  调用对应的 方法的执行函数
ngx.log(ngx.ERR, "b method: "..post_data.method)
local method = string.gsub(post_data.method, "[%.]", "_")
ngx.log(ngx.ERR, "a method: "..method)
local capture_url = method_conf[method]
ngx.log(ngx.ERR,"----- ",capture_url,"----",method,cjson.encode(method_conf))

if not capture_url then
	ngx.say(api_data_help.new_failed("方法参数错误,请检查方法参数!") ) 
	return
end
 

local res = ngx.location.capture(
     capture_url,
     { method = ngx.HTTP_POST, body = cjson.encode(post_data) }
 ) 

ngx.say(res.body)


