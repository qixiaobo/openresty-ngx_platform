
--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:/lua/modules/game/lottery/ssc_game_engine.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  时时彩游戏业务引擎,该引擎由一号服务器的01worker进行循环执行,系统开启之后开启该业务对象进行
--  读取抓去指定地址的页面数据分析有效数据,当发生变化期数变化, 写入数据库,同时发起通知,参与游戏的玩家进行判断是否中奖
--  
--]]
local clazz = require "common.clazz.clazz"
local cjson = require "cjson" 
local timer_help = require "common.timer_help"
local redis_help = require "common.db.redis_help"

local ngx_thread_help = require "common.ngx_thread_help" 
local web_analysis = require "game.lottery.web_analysis"

local _M = {
	-- 平台游戏 局编号
	innings_no = "xx",
	-- 局次 标题, 该数据为对应游戏的期数
	innings_no_title = "", 
	-- 当局开奖结果
	innings_result = nil,
	-- 是否开奖 
	is_run_lot = false,

}

-- 继承
_M.__index = _M
setmetatable(_M,clazz)

local DATA_SOURCE_URL = {
	{web_url="1",reg_innings_no_str="",reg_lot_str=""},
	{web_url="2",reg_innings_no_str="",reg_lot_str=""},
}
  


--[[ 
	init  初始化函数 虽然由01号机器的00work执行  但是建议使用使用redis的分布式事务所进行一次安全操作
-- example 
     
-- @param  _source_map 指定游戏的查询配置
-- @return 返回 nil 表示失败; 返回 true 表示成功
--]]
function _M:init(_source_map)
	slef.web_analysis_list = {}
	for i=1,#_source_map do
		slef.web_analysis_list[i] = web_analysis:new()
		slef.web_analysis_list[i]:init(_source_map[i].web_url,_source_map[i].reg_str)
	end

	self.timer_imp = timer_help:new(self.web_analysis,self)
	local res = self.timer_imp:timer_every(1)
	return res
end

--[[ 
	web_analysis web 1地址的分析函数 主要用于分析该页面下的数据
-- example 
       
--]]
function _M:web_analysis()
	local web_analysis_list = self.web_analysis_list
	local res = {}
	for i=1,#web_analysis_list do 
		 res[i] = web_analysis_list:analysis()
	end

	local is_same = true
	local last_code = nil
	if #web_analysis_list == 1 then
		if not res[1] then
			is_same = false
		end
	else

		for i=1,#web_analysis_list do
			if i == 1 then  last_code = res[i] end
			if not res[i] then
				is_same = false
				break;
			elseif res[i] ~= last_code then
				is_same = false
				break;	
			end
		end
	end

	if not is_same then  
		return  
	end

	-- 判断期数 如果相同不作处理


	-- 如果不同 说明增长 进行判断  发起redis 请求 同时写入 redis数据库





end





return _M