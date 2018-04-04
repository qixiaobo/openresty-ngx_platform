--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:pre_config.lua
--  version:1.0.0.1
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  各个模块拥有自己的预定义对象,由于多个功能模块的程序放入一个文件中容易出现问题,故系统在初始化的时候,
--  自动扫描各个模块的pre_config对象, 预定义内部,用户自行处理,包括国际化等
--  
--]]

local _M = {} 
  
-- 系统默认的uuid 注意 uuid 设定为全局,其他地方不可以修改,否则会造成其他异常问题
-- 文件uuid namespace
_G.ZS_FILES_NAME_SPACE = "8a4072bd-03bc-4694-b2dd-55f028f16f37"
-- 用户uuid namespace
_G.ZS_USER_NAME_SPACE = "17a6f58d-1d2c-43be-bc31-39f6454deb12"
-- 地理空间 namespace
_G.ZS_REGIONAL_NAME_SPACE = "636ffeb7-4d34-48bb-ad36-3439795ad2fc"
-- book namespace
_G.ZS_PRE_BOOK_CODE_SPACE = "152b0d31-2143-4d11-9dc7-b39bad3e6f8c"
-- transaction namespace
_G.ZS_PRE_TRANSACTION_CODE_SPACE = "6be3c0ff-d78b-49ae-a9cd-8765d2aa23ca"


_G.ZS_USER_REDIS_LOGISTICS = "default_logistics"
 
-- 微信代理服务器场景下,该字符串连接用户唯一编号, 实现用户订阅频道
_G.ZS_WECHAT_PRE_STR = "wechat_"

_G.ZS_REDIS_CHENNEL_SNOTICE = "system_notice"

_G.SYSTEM_ON_LINE_USERS = "SYSTEM_USER_ON_LINE"
 

return _M