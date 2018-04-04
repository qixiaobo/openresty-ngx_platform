--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:identify_code.lua
--	version: 0.01 
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  获得获得验证码,获得短信验证码,以及其他相关判断,验证码相关存尽量存放于共享内存中
--  短信获取需要获取当前请求的msgtoken信息,该信息由系统生成携带,客户端需要将该信息返回给服务器
--  mobile_number,area_code,msg_token,msg_temp
--  短信发送, 与验证; 验证码生成, 验证码验证; 邮箱验证发送, 邮箱验证等
--]]

local cjson = require "cjson"
local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help" 
local messages_dao = require "messages.model.messages_dao"
local messages_temp = require "messages.model.messages_temp"
local random_help = require "common.random_help"


local Identity_M = {
	VERSION = "0.01",
}

Identity_M.get_phone_code = function (  )
	-- body
	local args = request_help.getAllArgs() 

	local area_code = args["area_code"]
	local phone_number = args["phone_number"]
	local msg_token = args["msg_token"] 
	if not phone_number then 
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR,'手机号不能为空 或 手机号格式不对 error!') 
	end

	local msg_code,isHaved = messages_dao.get_mobile_msg(area_code, phone_number, 6)

	local msg_temp =  messages_temp.get_message_temp() 

	local msg_context = string.gsub(msg_temp, "#000000", msg_code)
	-- ngx.log(ngx.ERR, msg_context ,"   --   ", msg_code)

	 
	 -- 发送短信接口调用 ----!!!!!!!!!!!!!!-----begin
	--  未来需要注意短信发送问题, 短信只能发送100条,超过一百条,系统对账号进行封停


	 -- 记录写入数据库 
	 

	 -- 发送短信接口调用 ----!!!!!!!!!!!!!!-----end

	-- 失败 通知客户端,日志上传客户端
	if not msg_code then
		-- 生成失败, 客户端从新发起请求,超过三次提醒异常
		return api_data_help.new_failed()
		
	else
		if not isHaved then -- 系统是否发送过短信,发送过短信只有当前有效
			messages_dao.record_mobile_msg(area_code, phone_number, msg_context)
		end
		return api_data_help.new_success({msg_token=msg_token})
	end 

end

--[[
	-- 检查手机验证码
]]
Identity_M.check_phone_code = function (  )

	local args = ngx.req.get_uri_args() 
	local phone_number = args["phone_number"]
	local area_code = args["area_code"]
	local msg_token = args["msg_token"] 
	local check_code = args["check_code"]  


	if not phone_number or not check_code or not area_code then 
		return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR,
			'phone_number or check_code or area_code 参数不能为空!')	
		
	else 
		
		local result = messages_dao.check_msg_code(area_code..phone_number, check_code)
		if result then
			return api_data_help.new_success()
		else
			return api_data_help.new_failed()
		end
	end 
end


Identity_M.get_email_code = function (  )
	--[[
	https://www.zhengsutec.com/messages/api/get_message.do?mobile_number=13851737717&area_code=+86&msg_token=testtoken
	curl 127.0.0.1/messages/api/get_message.do?mobile_number=13851737717&area_code=+86&msg_token=testtoken
	-- ]]

	-- 获得当前是否包含指定的参数
	-- 获得短信息包含一下几类信息
	 -- 1 短信信息
	 -- 2 随机验证码信息
	local args = ngx.req.get_uri_args()
	local email = args["email"] 
	if not email then  
		return  api_data_help.new_failed("邮箱不能为空",nil)
	end

	-- 验证是否符合email规则
	local regex_help = require "common.regex_help"
	local res = regex_help.isEmail(email) 

	if not res then 
		return api_data_help.new_failed("格式不正确",nil)
		
	end

	-- 生成32位的唯一token, 所有的用户将进行以下数据处理
		local user_identity_token = random_help.randomchar_by_len(32);

		-- 头信息中不可以使用下划线,否则html端无法获取头信息
		ngx.header["User-Identity-Token"] = user_identity_token

	local msg_code,isHaved = messages_dao.get_email_msg(email, 6)
	local msg_temp = messages_temp.get_message_temp('EMAIL_CHECK_CODE') 
	  
	-- 失败 通知客户端,日志上传客户端
	if not msg_code then
		return api_data_help.new_failed('发送验证码失败,请稍后再试') 
	else 
		return api_data_help.new_success('发送成功')
	end
 

end

Identity_M.check_email_code = function (  )
		

end


--[[
	获得验证码图片, 该功能将同时写入当前验证码的对应token权限	
	即在头文件中添加 User-Identity-Token 字段,验证的同时系统必需添加钙字段
	验证时 需要比对 token 和 code 

--]]
Identity_M.get_identifying_code =function (  )
	-- body

	-- 用户登陆指定页面需要携带系统生成的唯一用户身份,用于验证
	-- 当前版本不考虑该问题 identity_token 该信息由用户第一次访问该页面,
	-- 由系统或者客户端创建,作为唯一访问约束  

	-- 生成32位的唯一token, 所有的用户将进行以下数据处理
	local user_identity_token = random_help.randomchar_by_len(32);

	-- 头信息中不可以使用下划线,否则html端无法获取头信息
	ngx.header["User-Identity-Token"] = user_identity_token
	 
	-- 用户随机验证码存放在 redis 缓存中
	local redis_cli = redis_help:new();
	if not redis_cli then
	    ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
	    -- 返回失败
	   	return api_data_help.new_failed() 
	end

	-- 生成随机数, 4位随机数,用户比较时候都需要转换为小写进行比较
	local identity_code  = random_help.randomchar_by_len(4);
	-- ngx.log(ngx.ERR,"identity_code is ", identity_code );
	redis_cli:set(user_identity_token,identity_code)
	redis_cli:expire(user_identity_token,30)
	-- 生成验证码图片,返回该图片,由于访问不同 
 	-- ngx.say(cjson.encode(api_data_help.new_success()))

	--在32个备选字符中随机筛选4个作为captcha字符串
	-- local dict={'A','B','C','D','E','F','G','H','J','K','L','M','N','P','Q','R','S','T','U','V','W','X','Y','Z','2','3','4','5','6','7','8','9'}
	-- local stringmark=""
	-- for i=1,4 do
	--        stringmark=stringmark..dict[math.random(1,32)]
	--  end

	-- local filename= "1_check_code.png"

	local xsize = 78
	local ysize = 26
	local wsize = 17.5
	local line = "yes"

	local gd=require('gd')

	local im = gd.createTrueColor(xsize, ysize)

	local black = im:colorAllocate(0, 0, 0)
	local grey = im:colorAllocate(202,202,202)
	local color={}
	for c=1,100 do
	        color[c] = im:colorAllocate(math.random(100),math.random(100),math.random(100))
	end

	x, y = im:sizeXY()
	im:filledRectangle(0, 0, x, y, grey)

	gd.useFontConfig(true)
	for i=1,4 do
	    k=(i-1)*16+3
	    im:stringFT(color[math.random(100)],"Arial:bold",wsize,math.rad(math.random(-10,10)),k,22,string.sub(identity_code,i,i))
	end

	if line=="yes" then
	    for j=1,math.random(3) do
	        im:line(math.random(xsize),math.random(ysize),math.random(xsize),math.random(ysize),color[math.random(100)])
	    end
	    for p=1,20 do
	            im:setPixel(math.random(xsize),math.random(ysize),color[math.random(100)])
	    end
	end

	local fp=im:pngStr(75)
	return fp

end


--[[
	图片验证码, 验证码存放在系统redis, 验证码对应的图片验证码 通过token进行比对
--]]
Identity_M.check_identifying_code =function (  )
		
	local args = ngx.req.get_uri_args()

	local user_identity_token = ngx.req.get_headers()['User-Identity-Token']
	local user_identity_code = args["user_identity_code"]
	 
	-- 包含头信息并且包含验证码,平台进行判断响应
	if  not user_identity_code and not user_identity_token then
		 return api_data_help.new_failed('参数不正确,请检查参数') 
	end

	-- 用户随机验证码存放在 redis 缓存中
	local redis_cli = redis_help:new();
	if not redis_cli then
	    ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
	    -- 返回失败
	    return api_data_help.new_failed() 
	end

	local identity_code = redis_cli:get(user_identity_token)

	if not identity_code then
		return api_data_help.new_failed()
	elseif identity_code == user_identity_code then
		return api_data_help.new_success()
	else
		return api_data_help.new_failed()
	end 
end

return Identity_M