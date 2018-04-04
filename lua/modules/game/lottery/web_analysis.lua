
--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:/lua/modules/game/lottery/web_analysis.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  网页分析封装,主要用于创建指定页面对象,然后进行查询和封装业务处理
--  
--]]

 
local clazz = require "common.clazz.clazz"
local cjson = require "cjson"
local http = require("resty.http") 
local _M = {}

-- 继承
_M.__index = _M
setmetatable(_M,clazz)


--[[ 
	init  初始化函数 虽然由01号机器的00work执行  但是建议使用使用redis的分布式事务所进行一次安全操作
-- example 
-- @param  _web_url 网页地址
-- @param _reg 正则表达式字符串

--]]
function _M:init(_web_url, _reg_no, _reg_lot ,_is_ssl)
	self.web_url = web_url
	self.reg_no_str = _reg_no 
	self.reg_lot_str = _reg_lot 
	self.is_ssl = _is_ssl and _is_ssl or false
end

--[[ 
	analysis web 1地址的分析函数 主要用于分析该页面下的数据
-- example 
      
-- @return res_no 分析出来的 期数编号
-- @return res_lot 分析出来的期数开奖数字
--]]
function _M:analysis()
	local httpc = http.new() 
	local timeout = 30000 
	httpc:set_timeout(timeout)  
	local res, err_ = httpc:request_uri(self.web_url, {
		  method = "GET",
		  ssl_verify = self.is_ssl, -- 进行https访问 
	})

	-- 返回失败, 通知前端 服务器业务块
	if not res or res.status ~= 200 then    
	    ngx.log(ngx.ERR, "get code error ! ", err, self.web_url) 
	    return   
	end

	local web_code = res.body


	-- print(string.find("haha", 'ah') )  ----- 输出 2 3  
	local innings_no = string.find(web_code, self.reg_no_str)
	local lot_res =  string.find(web_code, self.reg_lot_str)

-- 进行一次二次处理 返回

	return innings_no, lot_res


end





return _M