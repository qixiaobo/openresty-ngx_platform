--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:game.lottery.lot_protocol.lua
--  
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  彩票通信协议
--]]
local _M = {}


--[[
	彩票通信协议主要包括客户端发送部分, 服务器主动下发部分
	当前游戏主要包含时时彩,利利彩

	协议分为上行 下行部分

]]
local LOT_PROTOCOL = {
	HEARTBEAT_C2S = 0x01, --[[系统心跳包协议,心跳包用于客户端向服务器发送当前状态数据,服务器将自身的服务器数据同步到本地 
	-- { protocol_type = LOT_PROTOCOL.HEARTBEAT_C2S, 
		data = {player_no = xx} 
		}
	]]

	HEARTBEAT_S2C = 0x02, --[[ 系统心跳包协议,服务器根据客户端类型,返回实际信息
	--  服务器下发给用户 结构如下 没有数据的字段默认不上传
	-- { protocol_type = LOT_PROTOCOL.HEARTBEAT_S2C,  
		data = {
			player_no = xx ,
			game_type = xx, -- 彩票游戏类型  
		}  
	]]

	SELECT_GAME_C2S = 0x03, --[[ 选择游戏, 成功之后返回用户游戏, 同时监听该游戏通知频道
		{ protocol_type = LOT_PROTOCOL.SELECT_GAME_C2S,  
		data = {
			player_no = xx ,
			game_type = xx, -- 彩票游戏类型  
		}  
	]]

	SELECT_GAME_S2C = 0x04, --[[ 返回结果 
		{ protocol_type = LOT_PROTOCOL.SELECT_GAME_C2S,
			code = 200,

			data = {
				player_no = xx ,
				game_type = xx, -- 彩票游戏类型 
				innings_no =xxx,		-- 平台自定义的期数
				innings_no_title=xxx, 	-- 表示当前第多少期 系统显示与某网站的期数相同 

			}  
	]]

	GAME_NOTICE_S2C = 0x05, --[[ 游戏通知,对于彩票游戏主要返回通知中奖信息,当前开始的局次等
		-- 相见 SUB_PROTOCOL 定义

	]]

	BET_C2S = 0x06,--[[ 玩家下注 下注除了基础类型, 还包含游戏类型,游戏玩法类型,游戏押注数字  
	-- { protocol_type = LOT_PROTOCOL.BET_C2S,  
		    data = {
				player_no = xx ,
				bet_list={
					{
						game_type=xxx,
						game_way=xxx,
						bet_details = {2,3,5,7}, -- 类似此种
						bet_numbers = 1, -- 空也表示1注 前端与服务器都要进行一次金额处理
					},
					{
						game_type=xxx,
						game_way=xxx,
						bet_details = {2,3,5,7}, -- 类似此种
						bet_numbers = 1, -- 空也表示1注 前端与服务器都要进行一次金额处理
					}
				}
			}
		}  
	]]
	BET_S2C = 0x07,--[[ 服务器返回玩家押注结果
	--   
	-- { protocol_type = LOT_PROTOCOL.BET_S2C,  
		 code = 200,
		data = {
			player_no = xx ,
			game_type=xx, -- 彩票游戏类型 
		}  
	]]

	-- 开奖结果通知
	RUN_LOT_C2S = 0x08,--[[ 开奖启动,应对于利利彩类型的手动游戏
	--   
	-- { protocol_type = LOT_PROTOCOL.RUN_LOT_C2S,  
		    data = {
				player_no = xx ,
				game_type=xx, -- 彩票游戏类型  
			}
		}  
	]]
	-- 开奖结果通知
	RUN_LOT_S2C = 0x09,--[[ 开奖返回 服务器通过内置或者通过
	--   
	-- { protocol_type = LOT_PROTOCOL.RUN_LOT_S2C,  
		    data = {
				player_no = xx ,
				game_type=xx, -- 彩票游戏类型 
				innings_no =xxx,		-- 平台自定义的期数
				innings_no_title=xxx, 	-- 表示当前第多少期 系统显示与某网站的期数相同


				bet_list={
					{
						innings_no = xxx, -- 局编号
						game_no=xxx,		-- 游戏编号
						game_way_no=xxx,		-- 游戏玩法编号
						bet_details = {2,3,5,7}, -- 类似此种
						bet_numbers = 1, -- 空也表示1注 前端与服务器都要进行一次金额处理
						is_win = xx, -- 是否中奖
					},
					{
						innings_no = xxx, -- 局编号
						game_no=xxx,		-- 游戏编号
						game_way_no=xxx,		-- 游戏玩法编号
						bet_details = {2,3,5,7}, -- 类似此种
						bet_numbers = 1, -- 空也表示1注 前端与服务器都要进行一次金额处理
						is_win = xx, -- 是否中奖
					}
				}
			}
		}  
	]]
 

}
_M.LOT_PROTOCOL = LOT_PROTOCOL
-- 子协议 主要用于游戏房间相关的通知
local SUB_PROTOCOL = {
	INNINGS_NO = 0x01, -- 返回当局的编号,用于用户押注
	--[[
		protocol_type = LOT_PROTOCOL.GAME_NOTICE_S2C,
  			sub_type =  SUB_PROTOCOL.INNINGS_NO,
			data = {  
				innings_no =xxx,		-- 平台自定义的期数
				innings_no_title=xxx, 	-- 表示当前第多少期 系统显示与某网站的期数相同
			} 
 
  		}   
	]]



	

}


_M.SUB_PROTOCOL = SUB_PROTOCOL
 

local PROTOCOL_FUNC_MAP = {
	"on_heartbeat_c2s",			
	"on_heartbeat_s2c",		
	"on_select_game_c2s",
	"on_select_game_s2c",
	"on_game_notice_s2c",
	"on_bet_c2s", 
	"on_bet_s2c",
	"on_run_lot_c2s",  
	"on_run_lot_s2c", 
}

_M.PROTOCOL_FUNC_MAP = PROTOCOL_FUNC_MAP
  

local PLAYER_STATE = {
    
}
_M.PLAYER_STATE = PLAYER_STATE


-- 玩法定义
local PLAY_WAY = {
	FIVE_STAR = 0x01,
	FOUR_STAR = 0x02,
	FRONT_THREE = 0x03,
	MID_THREE = 0x04,
	END_THREE = 0x05,
	FRONT_TWO = 0x06,
	END_TWO = 0x07,
	ONE_STAR = 0x08,
}

_M.PLAY_WAY = PLAY_WAY

local PLAY_WAY_FUNC = {
	"five_star" ,
	"four_star" ,
	"front_three" ,
	"mid_three" ,
	"end_three" ,
	"front_two" ,
	"end_two" ,
	"one_star" ,
}
_M.PLAY_WAY_FUNC = PLAY_WAY_FUNC

 

--[[ 
	five_star 五星的判断
-- example 
    
-- @param  _lot_res 开奖结果
-- @param _bet_lot 玩家押注的结果
--]]
local function five_star(_lot_res,_bet_lot)
	if not _lot_res or not _bet_lot then 
		local res = ""..nil
		return nil end
	for i = 1,5 do
		if _lot_res[i] = _lot_res[]
	end
	return true

end

local function four_star(_lot_res,_bet_lot)

end
local function front_three(_lot_res,_bet_lot)

end
local function mid_three(_lot_res,_bet_lot)

end
local function end_three(_lot_res,_bet_lot)

end
local function front_two(_lot_res,_bet_lot)

end
local function end_two(_lot_res,_bet_lot)

end
local function one_star(_lot_res,_bet_lot)

end


return _M