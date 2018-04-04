--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:game.texasholdem.th_protocol.lua
--  
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  德州扑克玩家-服务器之间的通信协议
--  玩家登陆成功之后将用户编号+token开启wssocket链接进行后续操作
--]]
local _M = {}

local PROTOCOL_TH = {
	HEARTBEAT_C2S = 0x01, --[[系统心跳包协议,心跳包用于客户端向服务器发送当前状态数据,服务器将自身的服务器数据同步到本地 
	-- { protocol_type = PROTOCOL_TH.HEARTBEAT_C2S, 
		data = {user_no = xx} 
		}
	]]

	HEARTBEAT_S2C = 0x02, --[[ 系统心跳包协议,服务器根据客户端类型,返回实际信息
	--  服务器下发给用户 结构如下 没有数据的字段默认不上传
	-- { protocol_type = PROTOCOL_TH.HEARTBEAT_S2C,  
		data = {user_no = xx ,
			room_no = xxxx, 	
			balance = xxx,
			player_level = xxx,
			player_state = xxx,
			
			is_banker = false,
			is_small_blind = false,
			is_big_blind = false, 
			is_utg = false,
   			}
		}  
	]]

	ROOM_SIDELINES_U2S = 0x03,	--[[ 旁观指令, 用户旁观可以接收房间的各类信息, 不能看到牌局数据 
  		-- { protocol_type = PROTOCOL_TH.ROOM_SIDELINES_U2S, 
  				data = {user_no="xxx", room_no="xxxx" }   
  		}
	]]
	ROOM_SIDELINES_S2U = 0x04,	--[[ 旁观回复指令,  
  		-- { protocol_type = PROTOCOL_TH.ROOM_SIDELINES_S2U, 
  			code = 200,
  			data = {user_no="xxx", room_no="xxxx" }   
  		}
	]]

	ROOM_OUTSIDELINES_U2S = 0x05,-- 退出机器房间旁观 ,退出旁观成功,code=200 标志,默认用户退出成功,如果退出失败,用户端可以从新连接
		--[[ {protocol_type = PROTOCOL_TH.ROOM_OUTSIDELINES_U2S,
			data = {user_no="xxx", room_no="xxxx"} } 
		]]
  	ROOM_OUTSIDELINES_S2U = 0x06,-- 退出机器房间旁观 ,退出旁观成功,code=200 标志,默认用户退出成功,如果退出失败,用户端可以从新连接
		--[[ {protocol_type = PROTOCOL_TH.ROOM_OUTSIDELINES_S2U,
			code = 200,
			data = {user_no="xxx", room_no="xxxx"} } 
		]]
	-- 第一期的聊天协议
  	WECHAT_MSG_U2S = 0x07,	-- 发送者, from_code 发送者信息, at_code提醒者信息, room_code房间编号
  		-- {protocol_type = PROTOCOL_TH.WECHAT_MSG_U2S, from_no="xxx", at_no="xxx", room_no="xxxx",msg="xxx"} 
  	WECHAT_MSG_S2U = 0x08,  -- 接收者信息
  		-- {protocol_type = PROTOCOL_TH.WECHAT_MSG_S2U, from_no="xxx", at_no="xxx",room_no="xxxx",msg="xxx"} 

  	JOIN_GAME_U2S = 0x09,  --[[ 加入房间请求
  	-- {protocol_type = PROTOCOL_TH.JOIN_GAME_U2S, 

  			data = {
  				player_no=xxx,
				nick_name=xxx,
				sex=xx,
				head_img=xxx,
				balance=xxx,
				player_level = xxx,
	  			room_no="xxxx", 
	  			seat_index = xx, -- 如果没有传递该信息,则随机一个有效位置返回给用户
	  			room_pwd = xxx,  -- 房间密码 需要密码的房间用户必须输入密码才能登陆
  			}
  		} 
  	--]]
  	JOIN_GAME_S2U = 0x0a,  --[[ 服务器返回 信息
	-- {protocol_type = PROTOCOL_TH.JOIN_GAME_S2U,
			code = 200, 
  			data = {

	  			player_no=xxx, 
	  			room_no="xxxx", 
	  			seat_index = xx, -- 服务器给用户分配到位置 
	  			game_state = xx, -- 房间的状态,主要牌局相关信息
	  			left_time = xx,  -- 当前房间的倒计时 暂不用处理

				player_list=[	-- 牌桌上 所有的用户列表信息
					{	
						player_no=xxx,
						nick_name=xxx,
						sex=xx,
						head_img=xxx,
						balance=xxx,
						player_level = xxx,
						player_state = xxx,
						
						is_banker = false,
						is_small_blind = false,
						is_big_blind = false, 
						is_utg = false,
						hand_cards = {}, -- 玩家手牌 服务器处理之后的假牌
						player_index = xx, -- 玩家所在的座位位置
					},
					{...}

	  			],
				public_cards = {
		
				},
			}
  		}   
  	]]
	LEFT_GAME_U2S = 0x0b,  --[[ 离开房间请求
  	-- { protocol_type = PROTOCOL_TH.LEFT_GAME_U2S, 
  			data = {	player_no=xxx, 
  				room_no="xxxx", }
  		} 
  	--]]
  	LEFT_GAME_S2U = 0x0c,  --[[ 离开房间回复
  		-- { protocol_type = PROTOCOL_TH.LEFT_GAME_S2U,
  			code=200, 
  			data = {player_no=xxx,  }
  		} 
  	--]]
	ROOM_STATE_S2U = 0x0d,  --[[ 房间信息变化的通知
		-- { protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.PLAYER_JOIN,
  			code=200,
			data = { player_no=xxx,
				nick_name=xxx,
				sex=xx,
				head_img=xxx,
				balance=xxx,
				player_level = xxx,
				player_state = xxx,
				room_no = xxx,
				game_pot = xxx,
			} 
 
  		}   
  	]]


  	PLAYER_FOLD_U2S = 0x0e,  --[[ 玩家盖牌操作
		protocol_type = PROTOCOL_TH.PLAYER_FOLD,
  			    data = {player_no=xxx, }
			} 
 
  		}   
  	]]
  	PLAYER_CALL_U2S = 0x0f,  --[[ 跟注操作,如果金额不够,则用户只能进行allin 操作才能进行游戏
		protocol_type = PROTOCOL_TH.PLAYER_CALL_U2S,
  			    data = = {player_no=xxx, }
			} 
 
  		}   
  	]]
  	PLAYER_RAISE_U2S = 0x10,  --[[ 押注操作,如果金额不够,则用户只能进行allin 押注的规则
		protocol_type = PROTOCOL_TH.PLAYER_RAISE_U2S,
  			    data = {
  			    	player_no=xxx, 
  			    	bet = xxx,}
			} 
 
  		}   
  	]]
  	PLAYER_CHECK_U2S = 0x11,  --[[ check操作
		protocol_type = PROTOCOL_TH.PLAYER_CHECK_U2S,
  			   data = { player_no=xxx, }
			} 
 
  		}   
  	]]

  	PLAYER_CZ_S2U = 0x12, --[[用户扑克牌操作相关失败的返回,用于玩家发起操作的错误返回 统一采用该协议结构进行
	  		protocol_type = PROTOCOL_TH.PLAYER_CZ,
	  		protocol_last = xxx, -- 操作失败的协议的类型
	  		code = xxx,
	  		msg = xxx,
	  		data = { player_no=xxx,  }
			} 
 
  		}   
  	]]
	PLAYER_BCFA_S2U = 0x13, --[[ 通知玩家进行押注, call, check, allin 等操作
		  		protocol_type = PROTOCOL_TH.PLAYER_BCFA_S2U,  
		  		data = { 
		  		player_no=xxx, 
				
		  		}
			} 
 
  		}   
  	]]

}
_M.PROTOCOL_TH = PROTOCOL_TH
-- 子协议 主要用于游戏房间相关的通知
local SUB_PROTOCOL = {
	PLAYER_JOIN = 0x01, -- 新玩家加入
	--[[
		protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.PLAYER_JOIN,
			data = { player_no=xxx,
				nick_name=xxx,
				sex=xx,
				head_img=xxx,
				balance=xxx,
				player_level = xxx,
				player_state = xxx,
				player_index = xxx, -- 玩家所在的座位
			} 
 
  		}   
	]]
	PLAYER_LEFT = 0x02, --[[ 玩家离开, 如果当前玩家在游戏中,直接从双队列中删除 
							 如果正好是等待该玩家执行操作,
							 则直接通知下一个玩家进行押注操作
								 
	]]
	--[[
		protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.PLAYER_LEFT,
			data = { 
				player_no=xxx,
				is_lost = xxx,
				 
			} 
 
  		}   
	]]

	PLAYER_OFFLINE = 0x03, --[[ 玩家掉线
					]]
	--[[
		protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.PLAYER_OFFLINE,
			data = { 
				player_no=xxx,
				room_no = xxx,
				player_state = xxx,
				game_pot = xxx,
			} 
 
  		}   
	]]
	PLAYER_REWARD = 0x04, -- 打赏 主要分为手气,平分,或指定玩家,二期优化
	--[[
		protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.PLAY_REWARD,
			data = { 
				player_no=xxx, 
				awards = xxx,
			}  
  		}   
	]]

	
	BIG_JACKPOT = 0x5, -- 中大奖提醒
	--[[
		protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.BIG_JACKPOT,
			data = { 
				player_no=xxx, 
				jackpot_no = xxx,
			}  
  		}   
	]]

	GAME_REST = 0x06, -- 进入休息状态
	--[[
		protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.GAME_REST,
			data = { 
				room_no = xxx,
				game_state = xxx,
				game_pot = 0,  -- 池底
				player_list = [{
					player_no=xxx,  -- 指定玩家进行操作,超时默认15秒 后续的协议结构类似  
					balance = xxx,

				}  ,
				{...}
			]
  		}   
	]]

	---------牌局相关--------------
	ON_PER_FLOP = 0x07, -- 开始per flop
	--[[
		protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.ON_PER_FLOP,
			data = { 
				room_no = xxx,
				game_state = xxx,
				game_pot = xxx,  -- 池底
				player_list = [{
					player_no=xxx,  -- 指定玩家进行操作,超时默认15秒 后续的协议结构类似 
					
					is_banker= xxx,
					is_small_blind = xxx,
					is_big_blind = xxx,
					is_utg = xxx,
					balance = xxx,

				}  ,
				{...}
			]
  		}   
	]] 

	ON_FLOP = 0x08,		-- 发三张公共牌
	--[[
		protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.ON_PER_FLOP,
			data = { 
				room_no = xxx,
				game_state = xxx,
				game_pot = xxx,  -- 池底
				public_cards = [{},{},{}]
			]
  		}   
	]]


	ON_TURN = 0x09,		-- 发第四张公共牌
	--[[
		protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.ON_PER_FLOP,
			data = { 
				room_no = xxx,
				game_state = xxx,
				game_pot = xxx,  -- 池底
				public_cards = [{},{},{},{}]
			]
  		}   
	]]

	ON_RIVER = 0x0a,	-- 发第五张公共牌
	--[[
		protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.ON_PER_FLOP,
			data = { 
				room_no = xxx,
				game_state = xxx,
				game_pot = xxx,  -- 池底
				public_cards = [{},{},{},{},{}]
			]
  		}   
	]]
	ON_GAME_CLEARING = 0x0b,		-- 清算
	--[[
		protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.ON_PER_FLOP,
			data = { 
				room_no = xxx,
				game_state = xxx,
				game_pot = xxx,  -- 池底
				player_list = [{
					player_no=xxx,  -- 指定玩家进行操作,超时默认15秒 后续的协议结构类似 
					
					is_banker= xxx,
					is_small_blind = xxx,
					is_big_blind = xxx,
					is_utg = xxx,
					balance = xxx,

				}  ,
				{...}
			]
  		}   
	]]

	ON_PER_FLOP_BET = 0x0c, -- 开始per flop 通知用户进行押注处理, 该消息为群发, 客户端受到该消息进行功能处理
	--[[
			protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.ON_PER_FLOP_BET,
			data = { 
				room_no = xxx,
				game_state = xxx,
				game_pot = xxx,  -- 池底 
				player_no = xxx, -- 玩家的编号 
				player_opt = {}, -- 玩家有效的操作状态 fold bet call raise allin 
			]
  		}   
	]] 

	ON_FLOP_BET = 0x0c, -- flop 通知玩家以及后面的操作状态通知
	--[[
			protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.ON_PER_FLOP_BET,
			data = { 
				room_no = xxx,
				game_state = xxx,
				game_pot = xxx,  -- 池底 
				player_no = xxx, -- 玩家的编号
				player_opt = {}, -- 玩家有效的操作状态 fold bet call raise allin 
			]
  		}   
	]] 

	PLAYER_FOLD = 0x0d, -- 盖牌
	PLAYER_CALL = 0x0e,  -- 跟注
	PLAYER_RAISE = 0x0f, -- 加注
	PLAYER_BET = 0x010, -- 押注
	PLAYER_CHECK = 0x11, -- check 
	PLAYER_ALLIN = 0x12, --[[ 玩家allin 效果提醒
							玩家allin 服务器收到信息之后,
							房间处理消息之后给所有用户发送allin 消息
					]]
	--[[
		protocol_type = PROTOCOL_TH.ROOM_STATE_S2U,
  			sub_type =  SUB_PROTOCOL.PLAYER_ALLIN,
			data = { 
				player_no=xxx,
				room_no = xxx,
				game_pot = xxx,
			} 
 
  		}   
	]]

}


_M.SUB_PROTOCOL = SUB_PROTOCOL


local TH_ERROR = {
	TH_ERROR_OK = 200,
	TH_ERROR_FALSE = 400,	-- 错误
	TH_ERROR_PARAM_NIL = 401, -- 重要参数为nil
	TH_ERROR_ROOM_OFFLINE = 402, -- 房间不在线
	TH_ERROR_ROOM_ALL_SEATS_TAKEN = 403, -- 满员


	TH_ERROR_SYSTEM_BUSY = 500, -- 系统繁忙
	TH_ERROR_SYSTEM_ERROR = 0xffffffff, -- 系统错误
}
_M.TH_ERROR = TH_ERROR




local PROTOCOL_FUNC_MAP = {
	"on_heartbeat_c2s",			
	"on_heartbeat_s2c",		
	"on_room_sidelines_u2s",
	"on_room_sidelines_s2u",
	"on_room_outsidelines_u2s",
	"on_room_outsidelines_s2u", 
	"on_wechat_msg_u2s",
	"on_wechat_msg_s2u",  
	"on_join_game_u2s",
	"on_join_game_s2u", 
	"on_left_game_u2s",
	"on_left_game_s2u", 
	"on_game_state_s2u", 
	"on_player_fold_u2s", 
	"on_player_call_u2s", 
	"on_player_raise_u2s", 
	"on_player_check_u2s", 
	"on_player_cz_s2u", 
}

_M.PROTOCOL_FUNC_MAP = PROTOCOL_FUNC_MAP

-- 游戏房间状态
local THGAME_STATE = {
    ON_GAME_RESET = 1, -- 休息
    ON_PERFLOP = 2,    -- 大小盲注下注,发手牌
    ON_PREFLOP_BET = 3, -- 发完手牌进行押注
    ON_FLOP = 4,       -- 发三张公共牌
    ON_FLOP_BET = 5,   -- 发完三张公共牌 下注
    ON_TURN = 6,       -- 发第四张公共牌
    ON_TURN_BET = 7,   -- 发第四张公共牌后下注
    ON_RIVER = 8,      -- 发第五张公共牌
    ON_RIVER_BET = 9,  -- 发完第五张公共牌 下注
    ON_CLEAR = 10,     -- 清算
    ON_GAME_OVER = 11, -- 游戏提前结束

    ON_GAME_WAITING = 0xff,  -- 游戏玩家不足,等待玩家进入
}

_M.THGAME_STATE = THGAME_STATE





local PLAYER_STATE = {
	FREE = 1, -- 空闲状态
    -- 旁观
    SIDELINES = 2,
    -- 占座未开始游戏状态 等待游戏开始

    ON_WAITING = 3,

    -- 游戏中
    ON_GAME = 4,
    -- 覆牌
    FOLDED = 5,
    -- 本轮没有 玩家 raise 则进行
    
    -- 当前不需要押注, 则玩家可选择check
    CHECK = 6,
    
    -- 跟注
    CALL = 7,

    -- RAISED 押注 CALLED
    RAISED = 8,

    -- 金钱不够时可以进行all操作,可以看到最后的牌,进行PK
    ALL_IN = 9,

    LEAVE = 10, -- 离开


}
_M.PLAYER_STATE = PLAYER_STATE



return _M