--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:message.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  消息体操作相关类,主要为消息发送,保持,存储等功能
--  1 , 用户输入手机号,发送请求,本地客户端携带地区编号,服务器端获取手机号,本次请求的有效msgtoken,用于接入验证
--  2 , 平台查询是否上次验证码存在,如果存在,则提醒用户短信已经发送,请等待; 如果没有发送, 生成验证码,写入redis缓存,调用发送端口,将结果写入数据库
--  3 , 用户将手机收到的验证码与手机号,地区号以及接入验证token 一同上传,应用模块调用验证模块,验证成功之后直接进行页面的跳转与其他操作
--]]

local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local uuid_help = require "common.uuid_help"
local incr_help = require "common.incr_help"
local random_help = require "common.random_help"
local redis_help = require "common.db.redis_help"
local logs_help = require "common.logs.logs_help"

local sys_msg_dao = require "system_messages.model.message_dao"

local _M = {}
local CHECK_MSG_PRE = "check_code_"
local CHECK_MSG_COUNTS_PRE = "check_code_counts_"
local CHECK_AUTH_PRE = "check_auth_code_"

--[[
    @brief:
            获得手机验证码
    @param:
            [_area_code:string] 区号
            [_mobile_number:string] 手机号
            [_msg_code_len:number] 生成验证码长度 
    @return:
            nil：获取验证码失败   验证码+验证码已经存在的状态(true：已经存在 false:不存在)
]]
 _M.get_mobile_msg = function(_area_code, _mobile_number , _msg_code_len)
 
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

    local phone_number_key  = CHECK_MSG_PRE.._area_code.._mobile_number    
  
    local msg_code = random_help.random_by_len(_msg_code_len)

    -- local res = redis_cli:hmset(msg_token,"mobile_number",phone_number,"msg_code",_msg_code)
    
    local res = redis_cli:setnx(phone_number_key,msg_code)
   
    if not res then
        ngx.log(ngx.ERR,"------- error failed to set mobile_code: ", err)
        return nil
    end 

    if res == 0 then
        local res = redis_cli:get(phone_number_key)  
        return res, true
    end
      -- 系统验证码有效期60秒,到期自动清理
    redis_cli:expire(phone_number_key,60) 

    -- _M.send_phone_msg(_mobile_number, _area_code, msg_code)
    -- 返回msg_token 用于用户提交手机号码验证的唯一编号
    return msg_code, false
end

--[[
    @brief:
            短信记录写入系统数据库,作为用户统计使用,主要用于结算
    @param:
            [_area_code] 区号
            [_mobile_number] 接收消息的手机号
            [_msg_context] 信息内容
    @return:
            nil 表示失败 true 表示成功
]]
 _M.record_mobile_msg = function (_area_code, _mobile_number , _msg_context )
    local msg_tbl = {}
    msg_tbl.msg_type = "系统消息"
    msg_tbl.msg_recv_no = _mobile_number
    msg_tbl.msg_title = "手机验证码"
    msg_tbl.msg_content = _msg_context
    msg_tbl.msg_state = "正常"
    local res, err = sys_msg_dao.add_one_msg(msg_tbl)
    if not res then
        ngx.log(ngx.ERR, "err: "..err)
        --ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
        return nil, 400;
    end 

    return res
 end

--[[
    @brief:
            验证码验证，从redis中取出验证码比较
    @param:
            [_key_name:string] redis key: CHECK_MSG_PRE.._key_name
            [_msg_code:string] 验证码 
    @return:
            nil/false：验证码不匹配，验证失败   true:验证成功
]]
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

    local res = redis_cli:get(CHECK_MSG_PRE.._key_name) 
    if not res then
        ngx.log(ngx.ERR,"failed to get check,not send or timeout "," ,Key Name: ",_key_name)
        return nil
    end
 
    if res == _msg_code then
        redis_cli:del(_key_name)
        --删除token凭证，主要用于验证操作的一致性
        redis_cli:del(CHECK_AUTH_PRE.._key_name)
		return true
    else
        --判断认证次数，超过3次，验证码自动失效
        local res = redis_cli:get(CHECK_MSG_COUNTS_PRE.._key_name)
        if not res then
            redis_cli:set(CHECK_MSG_COUNTS_PRE.._key_name, '1')
        else
            local count = tonumber(res)
            count = count + 1
            if count >= 3 then
                --删除验证码,已经验证3次，验证码自动失效
                redis_cli:del(_key_name)
                --删除token凭证
                redis_cli:del(CHECK_AUTH_PRE.._key_name)
            else
                local res = redis_cli:set(CHECK_MSG_COUNTS_PRE.._key_name, tostring(count))
            end
        end
    end

    return false;
end

--[[
    @brief:
            短信记录写入系统数据库,作为用户统计使用,主要用于结算
    @param:
            [_email] 接收消息的手机号
            [_msg_context] 信息内容
    @return:
            nil 表示失败 true 表示成功
]]
 _M.record_email_msg = function (_email, _msg_context )
    local msg_tbl = {}
    msg_tbl.msg_type = "系统消息"
    msg_tbl.msg_recv_no = _email
    msg_tbl.msg_title = "邮箱验证码"
    msg_tbl.msg_content = _msg_context
    msg_tbl.msg_state = "正常"
    local res, err = sys_msg_dao.add_one_msg(msg_tbl)
    if not res then
        ngx.log(ngx.ERR, "err: "..err)
        --ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
        return nil, 400;
    end 

    return res
 end

--[[
    @brief:
            获得邮箱验证码
    @param:
            [_email:string] 邮箱账号
            [_msg_code_len:number] 生成验证码长度 
    @return:
            nil：获取验证码失败   验证码+验证码已经存在的状态(true：已经存在 false:不存在)
]]
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
    local res = redis_cli:setnx(email_key, msg_code) 
    if not res then
        ngx.log(ngx.ERR,"------- error failed to set email code: ", err)
        return nil
    end

    if res == 0 then
        local res = redis_cli:get(email_key)  
        return res, true
    end

    -- 系统验证码有效期 10 分钟,到期自动清理
    redis_cli:expire(email_key, 60*10)

    return msg_code, false
end


--[[
    @brief: 
            发送邮件
    @param: 
            [_email] 邮箱账号
            [_msg_context] 邮件内容
    @return: true 表示成功  nil/false 表示失败
]]
 _M.send_email_msg = function( _email , _msg_context)
    if not _email or _email == '' then return nil, "邮箱账号不能为空." end

    local mail = require "common.msg.email"

    local from = mail.SYS_EMAIL_ACCOUNT
    local to = {_email}
    local subject = "邮箱验证码"
    local content = _msg_context
    return mail.send_simple_email(from, to, nil, subject, content)
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
local Access_Key_ID = "LTAIsvG38Qe4YuYx"
local Access_Key_Secret = "OyKGqd6GvQQAHehaX5r1CijFyHedHp"
local SignName = "正溯网络"
local TemplateCode = "SMS_119920940"



local sign_help = require "common.crypto.sign_help"  
local http = require("resty.http") 
 _M.send_phone_msg = function( _phone , _area_code, _code)
    -- body
    -- 如果空的mobile number 系统返回nil
    if not _phone then return nil end

    local _msg = { 
            Format="XML",
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
            TemplateParam = cjson.encode({code=_code}),
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
 
    _msg.Signature = sha1_str

     ngx.log(ngx.ERR," 5  hmac_sha1 加密之后的字符串(Access_Key_Secret+&) 并 base64 ", sha1_str)

    local httpc = http.new() 
    local timeout = 30000
    httpc:set_timeout(timeout) 
    local sms_url = "http://dysmsapi.aliyuncs.com/?".."Signature="..sha1_str.."&"..specialUrlEncode

    ngx.log(ngx.ERR," 6 最终组装的地址 ", sms_url)

    local res, err_ = httpc:request_uri(sms_url, {
        -- method = "POST",
        -- ssl_verify = false, -- 进行https访问 
        -- body =  ngx.encode_args(_msg)
    })

    if not res then
        ngx.log(ngx.ERR,"error ",err_)
      return nil, err_
    else
    if res.status == 200 then 
             ngx.log(ngx.ERR,"status 200 ",res.body)
              return res.body, err_
         else
              ngx.log(ngx.ERR,"status ",res.status ,err_)
              return nil, err_
         end
    end 
 
end

return _M