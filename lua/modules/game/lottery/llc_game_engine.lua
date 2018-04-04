
--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:/lua/modules/game/lottery/llc_game_engine.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  时时彩游戏业务引擎,该引擎由一号服务器的01worker进行循环执行,系统开启之后开启该业务对象进行
--  读取抓去指定地址的页面数据分析有效数据,当发生变化期数变化, 写入数据库,同时发起通知,参与游戏的玩家进行判断是否中奖
--  
--]]
local clazz = require "common.clazz.clazz"
local cjson = require "cjson" 
local timer_help = require "common.timer_help"
local ngx_thread_help = require "common.ngx_thread_help" 
local random_help = require "common.random_help"
local _M = {
	-- 平台游戏 局编号
	innings_no = "xx", 
	-- 当局开奖结果
	innings_result = nil, 

}

-- 继承
_M.__index = _M
setmetatable(_M,clazz)
  

--[[ 
	run_lot 开奖操作 获得5位 随机数字字符串来匹配玩家中奖情况
	

-- example 
-- @param _player_bet 玩家押注的数组该数组结构如下
			[{bet_num=[1,2,3],play_way=}]
   
--]]
function _M:run_lot(_player_bet)
	local res = random_help:randomnumber_by_len(5) 

end





return _M