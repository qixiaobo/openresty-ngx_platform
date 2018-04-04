local _M = {} 

--365天秒数
_M.yearTimeSec  = 31536000
--30天秒数 
_M.monthTimeSec = 259200
--一天秒数
_M.daytimeSec = 86400
--30分钟秒数
_M.thirtyMinuteSec = 1800
--一分钟秒数
_M.oneMinuteSec = 60


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
 
 ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR = ""
--[[
--	系统错误扩展相关
--	version:0.01
--  日期:2017-03-26
--]]
require "conf.error_conf"

require "conf.language_code_tbl"
require "conf.coin_code_tbl"
require "conf.area_code_tbl"

require "conf.user_conf"

local fileSys = require "common.lfs_help"
local function moudule_conf_init()
   
    local sys_str = "/lua/modules/"
    local bundles = "/bundles"
    local pre_conf = "/pre_conf.lua"
    -- 获得当前目录功能,
    local project_dir = fileSys.getCurPath() 
	-- body
	-- 遍历文件,类似java中的遍历过滤能力
	local modules_path_str = project_dir..sys_str; 
  	for file in lfs.dir(modules_path_str) do 
	    local p = modules_path_str..file  
	    if file ~= "." and file ~= '..' and fileSys.isDir(p) then
                local _bundles_path = p..bundles
                -- ngx.log(ngx.ERR,_bundles_path) 
                    -- 遍历文件夹 进行文件初始化
                local _moduleName = _bundles_path..pre_conf;
                local ok,res = pcall(require,_moduleName)
                -- ngx.log(ngx.ERR,"----".._moduleName,"ok?",ok)  
	    end 
	 
        end 
    
end
--[[
    执行便利过程
]]
moudule_conf_init()

return _M