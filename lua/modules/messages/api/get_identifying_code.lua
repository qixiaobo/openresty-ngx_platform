--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:get_identifying_code.lua
--	version: 0.1 程序结构初始化实现
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  用于验证用户的验证码, 随机验证码生成,验证
--  系统验证验证码, 该验证码验证需要上传 user_identity_token user_identity_code 两个字段
-- 	其中 user_identity_token 来源于系统get_identifying_code.do 头信息中所携带的对应token
--]]

local cjson = require "cjson"
local messages_dao = require "messages.model.messages_dao"
local messages_temp = require "messages.model.messages_temp"
local random_help = require "common.random_help"
local api_help = require "common.api_data_help"
local redis_help = require "common.db.redis_help"
local uuid_help = require "common.uuid_help"

-- 用户登陆指定页面需要携带系统生成的唯一用户身份,用于验证
-- 当前版本不考虑该问题 identity_token 该信息由用户第一次访问该页面,
-- 由系统或者客户端创建,作为唯一访问约束  

-- 生成32位的唯一token, 所有的用户将进行以下数据处理
-- local user_identity_token = random_help.randomchar_by_len(32);
local user_identity_token = uuid_help:get64()

-- 头信息中不可以使用下划线,否则html端无法获取头信息
ngx.header["User-Identity-Token"] = user_identity_token

-- 用户随机验证码存放在 redis 缓存中
local redis_cli = redis_help:new();
if not redis_cli then
	ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
	-- 返回失败
	ngx.say(api_help.new_failed())
	return nil; 
end

-- 生成随机数, 4位随机数,用户比较时候都需要转换为小写进行比较
local identity_code  = random_help.randomchar_by_len(4);
-- ngx.log(ngx.ERR,"identity_code is ", identity_code );
redis_cli:set(user_identity_token,identity_code)
redis_cli:expire(user_identity_token,30)
-- 生成验证码图片,返回该图片,由于访问不同 
-- ngx.say(cjson.encode(api_help.new_success()))

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
ngx.say(fp)

ngx.log(ngx.ERR, "=====> 请求图片验证码：TOKEN["..user_identity_token.."], CODE["..identity_code.."]");



