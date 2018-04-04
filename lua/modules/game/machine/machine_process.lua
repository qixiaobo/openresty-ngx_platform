--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:machine_process.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  机器类型通信协议json格式化定义-- 未来采用二进制通信方案!!!!!!!
--  
--]]
local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"


local _M = {}
 


--[[
系统由于为4节点非可控节点, 故对系统状态做如下管理
1, 房间的状态信息以 状态起始码:区服:等级场  房间编号:机器编号 机器状态组成的json字符串 以map存入 redis 内存中
2, 机器的离线前状态以 状态起始码+机器编号 机器状态json字符串  写入 redis 内存中 超时15秒 自动释放 通知房间用户
3, 用户的离线状态 以起始码+用户编号 用户必要的状态json化  写入redis 内存中 超时15秒 自动释放 通知机器和用户
	
	一期 系统采用redis作为系统消息队列, 使系统编号唯一 用户,机器,房间三者的订阅同样以起始码+各自编号写入redis内存中, 确保起始码不得相同
 
]]

local PROCESS_TYPE = {
	HEARTBEAT_C2S = 0x01, --[[系统心跳包协议,机器只上传机器编号,用户上传用户编号,同时将上传客户端自身状态
	--	机器端上传 数据结构如下
	-- { process_type = PROCESS_TYPE.HEARTBEAT_C2S,  machine_status = xx , user_code = xx }
	--  用户客户端上传 数据结构如下
	-- { process_type = PROCESS_TYPE.HEARTBEAT_C2S,  room_code = xxxx, machine_code = xxxx }
	-- 
	-- 当前心跳包收到 对应数据 同时进行当前状态写入 各自的redis缓存中
	]]

	HEARTBEAT_S2C = 0x02, --[[ 系统心跳包协议,服务器根据客户端类型,返回实际信息
	--	服务器下发给机器 如下信息
	-- { process_type = PROCESS_TYPE.HEARTBEAT_S2C,  machine_status = xx , user_code = xx, is_queue = true }
	--  服务器下发给用户 结构如下 没有数据的字段默认不上传
	-- { process_type = PROCESS_TYPE.HEARTBEAT_S2C,  user_code = xx ,player_status = xx , is_queue = true, room_code = xxxx, 			machine_code = xxxx,machine_status=xxx, queue_machine_code=xxxx } 
	--} 
	]]

	MACHINE_SIDELINES_U2S = 0x03,	--[[ 机器旁观指令,用户进入房间必须进行该操作,对于推币机 room_code 即房间编号, 旁观成功 code=200 非200 表示失败
			需要提醒用户
  		-- { process_type = PROCESS_TYPE.MACHINE_SIDELINES_U2S, user_code="xxx", room_code="xxxx" }   
	]]
	MACHINE_OUTSIDELINES_U2S = 0x04,-- 退出机器房间旁观 ,退出旁观成功,code=200 标志,默认用户退出成功,如果退出失败,用户端可以从新连接
		-- {process_type = PROCESS_TYPE.MACHINE_OUTSIDELINES_U2S,user_code="xxx", room_code="xxxx" ,code=200 } 
  	
	-- 第一期的聊天协议
  	WECHAT_MSG_U2S = 0x05,	-- 发送者, from_code 发送者信息, at_code提醒者信息, room_code房间编号
  		-- {process_type = PROCESS_TYPE.WECHAT_MSG_U2S, from_code="xxx", at_code="xxx", room_code="xxxx",msg="xxx"} 
  	WECHAT_MSG_S2U = 0x06,  -- 接收者信息
  		-- {process_type = PROCESS_TYPE.WECHAT_MSG_S2U, from_code="xxx", at_code="xxx",room_code="xxxx",msg="xxx"} 

	ASK_FOR_MATHINE_U2M = 0x07 , 	--[[ 1, 用户请求空闲机器 如果用户当前已经在游戏,或者排队,则禁止用户请求,
											用户通过消息队列通知机器,然后通知机器,机器收到消息通知用户,
											如果机器不在线则通知用户机器不在线,请稍后再试, 指令请求 请求机器用户必须在房间,否则服务器将返回错误标志
											同时开启超时等待,超时未受到数据,则本次请求作为无效, 机器返回结果也将直接废弃

										 2, 机器端收到该请求,机器根据自身状态进行一次判断,如果机器为空闲,则将机器设置为 请求状态, 后续有用户请求,则直接通知机器被占用, 
										 本地也需要开启一次定时处理,如果机器未返回,超时之后自动将机器设置为空闲,如机器超时反馈,该条消息也直接废弃, 


		-- {process_type=PROCESS_TYPE.ASK_FOR_MATHINE_U2M, user_code="xxx", machine_code="xxxx", is_visitor = true} 
		]]
	ASK_FOR_MATHINE_M2U = 0x08,		--[[ 1, 机器服务器收到该消息 根据code 修改机器状态,同时通过消息队列 回复客户端 请求返回 成功或者失败. 
										code 200 表示成功 非200 表示失败 ; 成功需要 将消息广播给所有房间用户!!!
										发送失败 机器设置为空闲状态

										2, 用户服务器端收到该消息修改用户状态,同时下发消息,如果下发失败则系统退出,机器端进入用户超时未执行,强制断开,
										如果是游客,则直接发起断开请求
										
		-- {process_type=PROCESS_TYPE.ASK_FOR_MATHINE_M2U, user_code="xxx", machine_code="xxxx", code=200 } 
	 	]]
	SLOT_U2M = 0x09,	--[[ 用户客户端投币 一期默认为投币一枚 ,扣除的游戏币和获得,由系统进行定义 ,默认配置为1:1 
							1, 用户服务器收到该信息,进行用户编号,用户状态信息预判断,判断成功 将通知机器服务器端 ,通知失败则直接通知用户投币失败
							2, 机器服务器端 通知机器 如果通知失败直接返回用户投币失败; 通知成功,收到请求之后生成扣费记录处理 !!!游客不产生数据库操作

		-- {process_type=PROCESS_TYPE.SLOT_U2M,user_code="xxx",machine_code="xxxx",coins=1, is_queue = true} 
	]]
	SLOT_M2U = 0x0a,	--[[ 投币结果反馈, 
							1, 机器端服务器端 收到机器扣费成功,通知用户,同时进行数据库确认; 如果扣除失败 则进行记录取消操作 !!!游客不产生数据库操作
							2, 用户服务器端收到消息直接转发给用户 扣币的结果将通知用户,包括当前用户账户余额, 投币数量 同时修改添加内存数据

		-- {process_type=PROCESS_TYPE.SLOT_M2U,code=200 ,user_code="xxx",machine_code="xxxx",coins=1,balance=xxx,bet_flow_code = 'xxxx', is_queue = true}
	]]
	MACHINE_REWARDS_M2U = 0x0b,	--[[玩家得币通知玩家
									1, 机器服务器端获得数据,添加中奖纪录,同时修改用户账户对应数据变化,积分/余额
									2, 玩家服务端 收到该消息 累加到用户端  替换为用户积分 通知客户端 
									

		-- {process_type=PROCESS_TYPE.MACHINE_REWARDS_M2U,
		-- user_code="xxx",machine_code="xxxx",coins=xxx, integral=xxx, machine_rewardsing = true ,is_queue = true,}
	]]

	ASK_FOR_DISCONNECT_U2M = 0x0c, 	--[[用户退出请求,
										1, 用户服务器端 判断用户状态和参数,然后通知机器服务器端,如果通知失败直接返回回复断开成功
										2, 机器服务器端 收到请求判断是否与当前用户一致 检查失败直接通知用户失败, 通知机器之后开启定时回调
											如果超时未返回则自动通知用户断开,并且设置机器未繁忙状态
										注意  sub_type = 1, 机器需要将sub_type 指令自动带回,如果不存在该指令 则不需要处理 用于请求失败或其他场景!!!
		-- {process_type=PROCESS_TYPE.ASK_FOR_DISCONNECT_U2M,user_code="xxx", machine_code="xxxx"}   
		]]


	ASK_FOR_DISCONNECT_M2U = 0x0d,	--[[ 机器断开反馈, 用户主动断开和机器主动断开都使用本条协议类型
										1, 机器服务器端 获取该消息将状态修改为机器返回的状态, 同时将消息广播给所有房间用户!!!
		-- {process_type=PROCESS_TYPE.ASK_FOR_DISCONNECT_M2U,user_code="xxx",machine_code="xxxx",code=200} 
	]]
	MACHINE_ERROR_U2M = 0x0e,	-- 玩家上报故障,当机器收到该故障时,需要记录当前机器的故障时间,如果正在中奖的吐币,
								-- 管理员修复之后该台机器完成之后自动进行后续结算操作,结算完毕之后才可以放行,同时通知该机器的管理员查看
		-- {process_type=PROCESS_TYPE.MACHINE_ERROR_U2M,user_code="xxx",machine_code="xxxx" }

	MACHINE_ERROR_M2S = 0x0f,	-- 机器上报故障记录时, 操作过程同MACHINE_ERROR_S2M  同时将消息广播给所有房间用户!!!
		-- {process_type=PROCESS_TYPE.MACHINE_ERROR_M2S,user_code="xxx",machine_code="xxxx" }
 
---------------------------------------
--- 用户进入系统后系统需要实时获取消息,排队等协议
---------------------------------------
	QUEUE_UP_U2S = 0x10,		--[[ 用户排队请求,排队主要针对于机器排队管理, 排队结果通过对应的S2U进行
										 排队成功通过 房间消息通知用户,排队队列变化通过消息队列
								-- 客户端本地查询合适的机器进行界面切换和排队请求
		-- {process_type=PROCESS_TYPE.QUEUE_UP_U2S, user_code="xxx",machine_code="xxxx"}
		]]
	QUEUE_UP_S2U = 0x11,		--[[ 用户排队请求返回,排队主要针对于机器排队管理, 排队成功通过房间消息通知用户,排队队列变化
						-- 客户端本地查询合适的机器进行界面切换和排队请求
		-- {process_type=PROCESS_TYPE.QUEUE_UP_S2U, user_code="xxx",machine_code="xxxx", code=200|400}
		]]
	QUEUE_CANCEL_U2S = 0x12,	--[[ 用户取消排队请求 操作流程与排队
		-- {process_type=PROCESS_TYPE.QUEUE_CANCEL_U2S, user_code="xxx",machine_code="xxxx"}  
		]]
	QUEUE_CANCEL_S2U = 0x13,	-- 取消排队回复
	-- {process_type=PROCESS_TYPE.QUEUE_CANCEL_S2U, user_code="xxx",machine_code="xxxx", code=200|400}  
 	QUEUE_ON_S2U = 0x14,		-- 系统通知用户所在的机器准备好
 		-- {process_type=PROCESS_TYPE.QUEUE_ON_S2U, user_code="xxx",machine_code="xxxx", code=200}  
 	QUEUE_CANCEL_ON_U2S = 0x15,	-- 用户放弃排到的机器
 		-- {process_type=PROCESS_TYPE.QUEUE_CANCEL_ON_U2S, }

	MACHINE_YUGUA_U2M = 0x16, -- 雨刮器控制协议
	-- {process_type=PROCESS_TYPE.MACHINE_YUGUA_U2M,user_code="xxx",machine_code="xxxx"}
 
 	-- 专用指令 用户断线, 主动通知其所在的机器 
	PLAYER_BREAK_US2MS = 0x17,	--[[ 用户断线, 游客用户直接断线 , 主要用于正在玩的用户玩家, 
		通知通知游戏服务器进行状态管理, 当超时未连接进来, 	通知机器端用户退出
		-- {process_type=PROCESS_TYPE.PLAYER_BREAK_US2MS,user_code="xxx",machine_code="xxxx"} 
		]] 
	MACHINE_BREAK_MS2US = 0x18, --[[ 机器断开则通知所有的房间玩家, 正在游戏玩家服务器端收到该信息,
									当超过时间主动通知玩家机器掉线,如果中大奖的用户可以发起机器故障请求,
									服务器同时会记录本机器状态,机器上线时自动清算数据给用户!!!
		-- {process_type = PROCESS_TYPE.MACHINE_BREAK_MS2US,user_code="xxx",machine_code="xxxx"} 
		]]
    MACHINE_NOTICE_S2U = 0x19, -- 机器主动通知事件,包括机器新玩家,排队提醒,中大奖等 具体结构见分sub指令说明
    	-- {process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,sub_type = xx, data = {}} 

	CLIENT_OFFLINE_S2U = 0x1a,	-- 用于用户重复登录情况,强行将用户或者机器T下线
		-- {process_type=PROCESS_TYPE.CLIENT_OFFLINE_S2U,user_code="xxx" | machine_code="xxxx"} 	
	MACHINE_NOTICE_M2S = 0x1b, -- 机器主动上传 当机器结算,故障,结算等状态之后进行主动通知,服务器收到通知之后进行通知排队用户或者广播服务
	-- {process_type=PROCESS_TYPE.MACHINE_NOTICE_M2S, machine_code="xxxx" } 
	SYSTEM_ERROR_S2U = 0x1c,	-- 系统故障 稍后再试 收到该协议说明上一次的请求协议失败 协议为上传用户的协议原数据, sub_type  为该消息类型
	-- {process_type=PROCESS_TYPE.SYSTEM_ERROR_S2U, sub_type=xxx } 
	PLAYER_CANCEL_RECONNECT = 0x1d, -- 用户断开之后,再次进入系统,用户选择取消,系统清空用户状态与数据
	-- {process_type=PROCESS_TYPE.PLAYER_CANCEL_RECONNECT, } 
	SYSTEM_NOTICE_S2U = 0x1e, -- 系统通知
	--[[
		{	
			process_type=PROCESS_TYPE.SYSTEM_NOTICE_M2S,
			code=200,msg="" , 
			sub_type=USER_STATUS, 
			data = {
				
			}
		}
	--]] 

	SEAT_U2M = 0x1f, -- 留座请求发起, 用户发起的占座请求 用户端发起不需要携带用户编号字段 user_code
					-- {process_type=PROCESS_TYPE.SEAT_U2M, machine_code='xxxx',user_code=xxx, minutes=2 }
	SEAT_M2U = 0x20, -- 留座成功返回, 
					-- {process_type=PROCESS_TYPE.SEAT_M2U,code=200, machine_code='xxxx', user_code=xxx,minutes=2 }
	SEAT_CANCEL_U2M = 0x21,
					-- {process_type=PROCESS_TYPE.SEAT_CANCEL_U2M, machine_code='xxxx' ,user_code=xxx}
	SEAT_CANCEL_M2U = 0x22,
					-- {process_type=PROCESS_TYPE.SEAT_CANCEL_M2U, code=200, machine_code='xxxx' ,user_code=xxx }
}

local PROCESS_SUB_TYPE = {
 	NEW_PLAYER = 0x01,	-- 新用户上机
 	PLAYER_SLOT = 0x02,	-- 用户投币提醒   -- 暂时不使用
 	BIG_REWARDS = 0x03,	-- 中大奖提醒		-- 暂时不使用
 	MACHINE_INIT = 0x04, -- 机器上线广播
 	MACHINE_FREE = 0x05,  -- 房间空闲提醒      
 	MACHINE_BREAK = 0x06, -- 机器断开广播
 	MACHINE_STATUS = 0x07, -- 房间状态变化,主要为空闲,清算,游戏中,故障等状态 
 	USER_STATUS = 0x08,	-- 用户状态变化
 	MAIL_COMING = 0x09,	-- 系统通知事件
}
_M.PROCESS_SUB_TYPE = PROCESS_SUB_TYPE

_M.PROCESS_TYPE = PROCESS_TYPE

local PROCESS_FUNC_MAP = {
	"on_heartbeat_c2s",			
	"on_heartbeat_s2c",		
	"on_machine_sidelines_u2s",
	"on_machine_outsidelines_u2s",
	"on_wechat_msg_u2s",
	"on_wechat_msg_s2u", 
	"on_ask_for_machine_u2m",
	"on_ask_for_machine_m2u", 
	"on_slot_u2m",
	"on_slot_m2u",
	"on_rewards_m2u",  
	"on_ask_for_disconnect_u2m",
	"on_ask_for_disconnect_m2u",
	"on_machine_error_u2m",
	"on_machine_error_m2u", 
	"on_queue_up_u2s",
	"on_queue_up_s2u",
	"on_queue_cancel_u2s", 
	"on_queue_cancel_s2u",  
	"on_queue_on_s2u",
	"on_queue_cancel_on_u2s",
	"on_ask_for_yugua_u2m",
	"on_player_break_us2ms",
	"on_machine_break_ms2us", 
	"on_machine_notice_s2u",
	"on_client_offline_s2u",
	"on_machine_notice_m2s", 
	"on_system_error_s2u",
	"on_player_cancel_reconnect",
	"on_system_notice_s2u",	
	"on_seat_u2m",	
	"on_seat_m2u",	
	"on_seat_cancel_u2m",
	"on_seat_cancel_m2u"
}

local PROCESS_MAP = {
	
}

_M.PROCESS_MAP = PROCESS_MAP
_M.PROCESS_FUNC_MAP = PROCESS_FUNC_MAP

-- 用户状态, 用户存在多种状态,故玩家采用bit状态进行
local PLAYER_STATUS = {
	FORBIDDEN = 0x00,	-- 禁用
	FREE = 0x01,	 	-- 大厅或其他状态
	SIDELINES = 0x02,	-- 旁观 漫游,进入房间
	MACHINE_ASKING = 0x03,	-- 机器查询中
	ON_GAME = 0x04,		-- 游戏状态
	QUEUE_UP = 0x05, 	-- 排队中,系统一般默认规定游戏中的用户不可以排队,如果支持排队,则用户在排队成功时需要提醒用户释放之前的游戏状态
	ON_RECONNECT = 0x06,	-- 用户重连中
	ON_SEAT = 0x07,			-- 占座状态

	SYSTEM_ERROR = 0xffffff, -- 用户状态或系统异常,不可以进行游戏
}

_M.PLAYER_STATUS = PLAYER_STATUS
 

-- 用户状态, 用户存在多种状态,故玩家采用bit状态进行
local MACHINE_STATUS = { 
	FORBIDDEN = 0x00,	-- 禁用
	ON_IDLE = 0x01,	-- 空闲中
	ON_ASKING = 0x02, -- 用户请求状态
	ON_GAME = 0x03,		-- 游戏中  
 	
 	MACHINE_ON_WAITING = 0x04,	-- 等待用户继续游戏
	--	用户掉线时 机器进入等待状态,等待超过一分钟,自动清算
	ON_LIQUIDATION = 0x05, -- 清算中,主要用于 用户超时的清算, 清算状态时, 机器不能连接
	 
	ON_QUEUE = 0x06,	-- 用户主动退出或者清算结束后 完成队列人员通知 顺序切换队列人员 
 	MACHINE_ERROR = 0x07,	-- 机器故障
 	MACHINE_OFFLINE = 0x08,	-- 机器离线
 	ON_SEAT = 0x09,			-- 占座状态
	STATUS_ERROR = 0xffffff, -- 机器状态为异常,不可以进行游戏
}

_M.MACHINE_STATUS = MACHINE_STATUS
 
local MACHINE_ERR_CODE = {
	SUCCESS = 200, -- 操作成功
	FAILED = 400 , -- 操作失败  
	PARAM_ERROR = 401,	-- 参数错误
	SYSTEM_BUSY = 402,  -- 系统繁忙
	USER_ASK_MULTY_MACHINE = 403, -- 申请多个机器
	ON_ASKING_MACHINE = 404,

	MACHINE_ON_USING = 405, -- 机器被使用中 
	MACHINE_ON_QINGSUAN = 406, -- 清算中 
	MACHINE_FORBIDDEN = 407, -- 机器禁止使用
	MACHINE_OFFLINE = 408,		-- 机器不在线
	ASK_MACHINE_TIME_OUT = 409,			-- 请求超时
	ON_SEND_ERROR = 410,		-- 发送失败
	SERVICE_OFFLINE = 411,		-- 客服不在线,请电话联系
	MACHINE_ERROR = 500, -- 机器故障 
}

_M.MACHINE_ERR_CODE = MACHINE_ERR_CODE


return _M