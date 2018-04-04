local mail = require "resty.mail"
local email_conf = require "conf.email_conf"

local _M = {}
_M.VERSION = "1.0"

_M.SYS_EMAIL_ACCOUNT = "dongyf90@126.com"

--[[
    @brief: 发送简单文本邮件
    @param: 
            [_email] 邮箱账号
            [_msg_context] 邮件内容
    @return: true 表示成功  nil/false 表示失败
]]
_M.send_simple_email = function ( _form, _to, _cc, _subject, _text)
	if not _form or not _to then
		return false, "发送者(_form)和接收者(_to)不能为空."
	end

	if type(_form) ~= 'string' or _form == '' then
		return false, "发送者(_form)参数错误, 请输入正确的邮箱账号."
	end

	if type(_to) ~= 'table' or #_to == 0 then
		return false, "接收者(_to)参数错误, 请输入正确的邮箱账号列表."
	end

	-- 验证是否符合email规则
	local regex_help = require "common.regex_help"
	local res = regex_help.isEmail(_form) 
	if not res then 
		return false, "发送者(_form)参数错误, 请输入正确的邮箱账号." 
	end

	for i = 1, #_to do 
		local res = regex_help.isEmail(_to[i]) 
		if not res then 
			return false, "接收者(_to)参数错误, 请输入正确的邮箱账号. 错误的账号: ".._to[i]
		end
	end 

	if _cc and #_cc ~= 0 then
		for i = 1, #_cc do 
			local res = regex_help.isEmail(_cc[i]) 
			if not res then 
				return false, "抄送者(_cc)参数错误, 请输入正确的邮箱账号. 错误的账号: ".._cc[i]
			end
		end 
	end

	if not _subject or _subject == '' or not _text or _text == '' then
		return false, "主题(_subject)和内容(_text)不能为空."
	end

	local email_conf = email_conf.main_conf
	if not email_conf then
		return false, "邮箱配置错误, 请联系系统管理员."
	end

	local mailer, err = mail.new(email_conf)
	if not mailer then
		return false, "系统错误, 请联系系统管理员."
	end
	
	local msg_context = {
		from = _form,
		to = _to,
		subject = _subject,
		text = _text,
	}
	if _cc then
		msg_context.cc = _cc
	end

	local ok, err = mailer:send(msg_context)
	if not ok then
		return false, "发送邮件失败. err: "..err
	else
		return true, "发送邮件成功."
	end
end


return _M