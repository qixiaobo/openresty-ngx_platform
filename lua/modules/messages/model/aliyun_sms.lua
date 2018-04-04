--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:aliyun_sms.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  消息体操作相关类,主要为消息发送,保持,存储等功能
--  1 , 用户输入手机号,发送请求,本地客户端携带地区编号,服务器端获取手机号,本次请求的有效msgtoken,用于接入验证 
--]]

local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local redis_help = require "common.db.redis_help"
local logs_help = require "common.logs.logs_help"
local uuid_help = require "common.uuid_help"
local incr_help = require "common.incr_help"
local random_help = require "common.random_help"


local _M = {
    
-- local Access_Key_ID = "LTAIsvG38Qe4YuYx"
-- local Access_Key_Secret = "OyKGqd6GvQQAHehaX5r1CijFyHedHp"
-- local SignName = "正溯网络"
-- local TemplateCode = "SMS_119920940"

}
_M.__index = _M

_M.new = function(_self,_Access_Key_ID, _Access_Key_Secret, _SignName, _TemplateCode ) 
     
    local sms =  setmetatable({ 
            Timestamp=os.date("%Y-%m-%dT%H:%M:%SZ",os.time()),
            SignatureMethod= "HMAC-SHA1", 
            SignatureVersion = "1.0",
            -- SignatureNonce = incr_help.get_uuid(),
            -- Signature = nil, 
            Action = "SendSms",
            Version = "2017-05-25",
            RegionId = "cn-hangzhou",
            -- Format = "JSON",
            -- PhoneNumbers=_phone, 
            -- TemplateParam = {code=_code},
            SignName = _SignName,
            TemplateCode = _TemplateCode,  
            -- OutId = incr_help.get_uuid(),
            AccessKeyId = _Access_Key_ID},clazz)  -- _M 继承于 clazz


    return sms
end


local CHECK_MSG_PRE = "check_code_"
local CHECK_MSG_COUNTS_PRE = "check_code_counts_"
--[[
-- _M:get_mobile_msg() 向指定手机发送验证码,系统将调用指定的验证接口实现验证码的发送功能
	发送短信接口主要权限,还有短信的有效时间
-- @param _area_code  地区编码
-- @param _mobile_number 手机号码  
-- @return 
--]]
 _M.get_mobile_msg = function( _area_code, _mobile_number , _msg_code_len)
 
	-- 如果空的mobile number 系统返回nil
	if not _mobile_number then return nil end

	-- 将短信内容写入mysql 数据库
    if not _msg_code_len then _msg_code_len = 6 end
	-- 将 code 写入 redis数据库
 	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        -- 返回失败
        return nil; 
    end

    local phone_number  = CHECK_MSG_PRE.._area_code.._mobile_number    
  
    local msg_code = random_help.random_by_len(_msg_code_len)

    -- local res = redis_cli:hmset(msg_token,"mobile_number",phone_number,"msg_code",_msg_code)
    
    local res = redis_cli:setnx(phone_number,msg_code)
   
    if not res then
        ngx.log(ngx.ERR,"------- error failed to set mobile_code: ", err)
        return nil
    end 

    if res == 0 then
        local res = redis_cli:get(phone_number)  
        return res,true
    end
      -- 系统验证码有效期30秒,到期自动清理
    redis_cli:expire(phone_number,60*5) 

    _M.send_phone_msg(_mobile_number, _area_code, msg_code)
    -- 返回msg_token 用于用户提交手机号码验证的唯一编号
    return msg_code,nil
end

--[[
-- _M:record_mobile_msg() 短信记录写入系统数据库,作为用户统计使用,主要用于结算


-- @param _msg_token 验证tokens ,为了防止最新号码的验证码冲突问题创建一个全局uuid 的64 的 
-- @param _msg_code 验证码
-- @return 
--]]
 _M.record_mobile_msg = function (_area_code, _mobile_number , _msg_context )
     -- body

    -- 发送短信信息写入mysql 数据库,短信信息未来写入分布式数据库中
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end
    -- 默认约束 #000000 
    -- local msg_context = string.gsub(_msg_context, "#000000" , _msg_code)
   
    local str = string.format("insert into t_message_records(mobile_number,area_code,msg_context)values('%s','%s','%s');", 
                            _mobile_number, _area_code ,_msg_context) 
    
    local res, err, errcode, sqlstate = mysql_cli:query(str)
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
        return nil,errcode;
    end 
    return res
 end


--[[
-- _M:check_msg_code() 从内存或者缓存中获取验证码,  可以验证邮箱, 手机, 随机验证码
 
-- @param _mobile_number 手机号, 如果有地区编号, 需要自动添加, 不保留空格
-- @param _msg_code 验证码
-- @return 
--]]
 _M.check_msg_code = function( _key_name, _msg_code )
	-- body
	-- 如果空的mobile number 系统返回nil
	if not _key_name then return nil end

	-- 将 code 写入 redis数据库
 	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        -- 返回失败
        return nil; 
    end
    -- local res = redis_cli::get(CHECK_MSG_COUNTS_PRE.._key_name)
    
    local res = redis_cli:get(CHECK_MSG_PRE.._key_name) 
    if not res then
        ngx.log(ngx.ERR,"failed to get check,not send or timeout "," ,Key Name: ",_key_name)
        return nil
    end

    if res == _msg_code then
        redis_cli:del(_key_name)
		return res
    end

    return false;
end
 

--[[
-- _M:get_email_msg() 获得邮箱消息唯一验证码
 
-- @param _email, 验证码code 
-- @param _msg_code_len  生成验证码长度

-- @return 
--]]
 _M.get_email_msg = function( _email , _msg_code_len)
    -- body
    -- 如果空的mobile number 系统返回nil
    if not _email then return nil end

    -- 将短信内容写入mysql 数据库
    if not _msg_code_len then _msg_code_len = 6 end
    -- 将 code 写入 redis数据库
    local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        -- 返回失败
        return nil; 
    end
    
    local email_key = CHECK_MSG_PRE.._email
    
    local msg_code = random_help.random_by_len(_msg_code_len) 
    local res = redis_cli:setnx(email_key,msg_code) 
    if not res then
         ngx.log(ngx.ERR,"------- error failed to set email code: ", err)
        return nil
    end

    -- 系统验证码有效期 10 分钟,到期自动清理
    redis_cli:expire(email_key,60*10)

-- 返回msg_token 用于用户提交手机号码验证的唯一编号
    return msg_code,true
end


--[[
-- _M:send_email_msg() 想指定email发送验证消息
 
-- @param _email, 验证码code 
-- @param _msg_code_len  地区编码

-- @return 
--]]
 _M.send_email_msg = function( _email , _msg_context)
    -- body
    -- 如果空的mobile number 系统返回nil
    if not _email then return nil end
   
 
end

--[[
-- _M:send_phone_msg   通过手机短信发送验证码
 example: 阿里云短信验证
    必须的组装参数 
    PhoneNumbers    手机号码 支持 以逗号分隔的形式进行批量调用
    SignName        短信签名
    TemplateCode    短信模版id
    TemplateParam   短信模版替换json 字段 {“code”:”1234”,”product”:”ytx”}

    返回
    RequestId   String  8906582E-6722   请求ID
    Code    String  OK  状态码-返回OK代表请求成功,其他错误码详见错误码列表
    Message String  请求成功    状态码的描述
    BizId   String  134523^4351232  发送回执ID,可根据该ID查询具体的发送状态


[
  {
    "phone_number" : "18612345678",
    "send_time" : "20170901000000",
    "content" : "内容",
    "sign_name" : "签名",
    "dest_code" : "1234",
    "sequence_id" : 1234567890
  }
]

-- @param _phone, 手机号
-- @param _area_code  地区编码
-- @param _code  短信验证码
-- @return 
--]]




local sign_help = require "common.crypto.sign_help"  
local http = require("resty.http") 
 _M.send_phone_msg = function( _phone , _area_code, _code)
    -- body
    -- 如果空的mobile number 系统返回nil
    if not _phone then return nil end

    local _msg = { 
            
            Timestamp=os.date("%Y-%m-%dT%H:%M:%SZ",os.time()),
            SignatureMethod= "HMAC-SHA1", 
            SignatureVersion = "1.0",
            SignatureNonce = incr_help.get_uuid(),
            Signature = nil,

            Action = "SendSms",
            Version = "2017-05-25",
            RegionId = "cn-hangzhou",
            -- Format = "JSON",
            PhoneNumbers=_phone, 
            SignName = SignName,
            TemplateCode = TemplateCode, 
            TemplateParam = {code=_code},
            OutId = incr_help.get_uuid(),
            AccessKeyId = Access_Key_ID,
            -- AccessKeySecret = Access_Key_Secret,
    }
    ngx.log(ngx.ERR," 1 原参数 ", cjson.encode(_msg) )

    local sorted_res = sign_help.make_sign_str_sort(_msg)
    ngx.log(ngx.ERR," 2 排序之后的参数 ", sorted_res )
    
    local specialUrlEncode = ngx.escape_uri(sorted_res)
    -- specialUrlEncode = string.gsub(specialUrlEncode,"%7E","~")
    ngx.log(ngx.ERR," 3 url encode 之后 ", specialUrlEncode )

    local specialUrlEncode1 = "GET&"..ngx.escape_uri("/").."&"..specialUrlEncode

    ngx.log(ngx.ERR," 4 最后等待加密的字符串 ", specialUrlEncode1)

    local sha1_str = ngx.escape_uri(ngx.encode_base64(ngx.hmac_sha1(Access_Key_Secret.."&", specialUrlEncode1)))
 
     ngx.log(ngx.ERR," 5  hmac_sha1 加密之后的字符串(Access_Key_Secret+&) 并 base64 ", sha1_str)

    local httpc = http.new() 
    local timeout = 30000
    httpc:set_timeout(timeout) 
    local sms_url = "http://dysmsapi.aliyuncs.com/?".."Signature="..sha1_str.."&"..specialUrlEncode
    ngx.log(ngx.ERR," 6 最终组装的地址 ", sms_url)

    local res, err_ = httpc:request_uri(sms_url, {
        method = "get",
        -- ssl_verify = false, -- 进行https访问 
    })

    if not res then
        ngx.log(ngx.ERR,"error ",err_)
      return nil, err_
    else
    if res.status == 200 then 
              return res.body, err_
         else
              return nil, err_
         end
    end



 
end

return _M