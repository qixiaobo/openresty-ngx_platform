--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:visitor.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  游客玩家的功能操作对象,包括各类数据存储与管理 
--  
--]]


local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local bit_help = require "common.bit_help" 
local player = require "game.model.player"
local machine_process = require "game.machine.machine_process"
local uuid_help = require "common.uuid_help"
local machine = require "game.machine.machine"
local online_union_help = require "common.online_union_help"
local timer_help = require "common.timer_help"
local resty_lock = require "resty.lock"

local PROCESS_TYPE = machine_process.PROCESS_TYPE
local PLAYER_STATUS = machine_process.PLAYER_STATUS
local MACHINE_STATUS = machine_process.MACHINE_STATUS
local PROCESS_SUB_TYPE = machine_process.PROCESS_SUB_TYPE
local MACHINE_ERR_CODE = machine_process.MACHINE_ERR_CODE
local PROCESS_FUNC_MAP = machine_process.PROCESS_FUNC_MAP
local PLAYER_TIME_OUT = 15
-- 用户父表,其他游戏可以集成该表 扩充字段

local _M = {
	user_code = "xx",
	player_status = PLAYER_STATUS.FREE ,	-- 默认空闲状态,没有进入房间
	balance = 0,				-- 余额
	nomove_balance = 0,		-- 一般为系统赠送金笔 只可以自己消费
	integral = 0,				-- 积分
	popularity = 0,			-- 人望
	level = 1,					-- 等级  

	machine_code = nil,			-- 当前占有的机器,机器号与旁观机器号必须相同
	queue_machine_code = nil,			-- 排队机器 用户只能排队一个机器或占用一个机器,二者只可以同时有一种状态在
	subscript_map = {},			-- 订阅列表
	room_code = "",			-- 旁观机器 用户进入房间	-- 机器房间聊天室

	user_channel_name = nil,	-- 用户在线的 channel name
	room_channel_name = nil,	-- 用户进入房间之后的 channel 名称
	user_online_key = nil,		-- 用户状态存储 key

}

_M.__index = _M 

setmetatable(_M,player)  -- _M 继承于 clazz


--[[
-- player_init 用户初始化,读取上一次登录的基础数据,获取用户账户余额等信息,读取用户基础信息
-- example 
 	
-- @param _user_code 用户编号
-- @param _user_token 用户有效token
--]]
_M.player_init = function( _self,_user_code, _user_token )

	-- body  
    _self.user_code = _user_code
    _self.user_token = _user_token   
 	_self.online_uuion = uuid_help:get64() 

    _self.user_channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._user_code
    _self.user_online_key = ZS_MACHINE_ONLINE_PRE.._user_code
 	_self.user_asking_machine_key = ZS_USER_MACHINE_ASKING_PRE.._user_code


	_self.balance = 1000
	_self.nomove_balance = 0
	_self.integral = 0
	_self.subscript_map = {}		-- 订阅列表
	_self.is_visitor = 1
			 
	local _process = {
		process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,
		sub_type = PROCESS_SUB_TYPE.NEW_PLAYER,
	}
	local _data = {
		player_status = _self.player_status,
		user_code = _self.user_code,
		machine_code = _self.machine_code,
		room_code = _self.room_code, 
		balance = _self.balance,
		nomove_balance = _self.nomove_balance,
		integral = _self.integral,
		online_uuion = _self.online_uuion, 
		is_visitor = 1,
	}
	_process.data = _data 
	_self.ws:sendMsg(cjson.encode(_process))  

    return true 

end

_M.save_user_info = function (_self)
	local  data = {
		player_status 	= _self.player_status,
		user_code 		= _self.user_code,
		room_code 		= _self.room_code, 
		machine_code 	= _self.machine_code,
		queue_machine_code = _self.queue_machine_code ,
		balance 		= _self.balance,
		nomove_balance 	= _self.nomove_balance,
		integral 		= _self.integral,  
	}
		-- 更新用户数据到缓存中,供在此登陆和机器sever查询
	online_union_help.update_online_redis( _self.user_online_key, cjson.encode(data), 
		PLAYER_TIME_OUT)
	return data
end

--[[
-- on_heartbeat_c2s  用户或机器发起的消息
	主要对于用户在游戏状态和排队用户
	用户掉线之后 系统将用户的数据写入redis缓存时间为1分钟 超过时间后,通知机器进行断开操作,机器进行状态处理,同时通知服务器断开成功
	机器进行内部处理,进入清算状态,清算结算通知服务器空闲, 服务器收到机器结束完成后,自动进行排队或设置为空闲状态
	
	机器掉线之后通知用户

	系统通过redis的异步定时器实现用户状态的管理,用户掉线之后,系统将用户的数据写入redis缓存时间为1分钟
	如果超过这个时间,系统将自动释放用户的所有临时状态,

-- example 
	HEARTBEAT_C2S = 0x01, -- 系统心跳包协议,机器只上传机器编号,用户上传用户编号
	-- {process_type=PROCESS_TYPE.HEARTBEAT_C2S
	--}

-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_heartbeat_c2s = function (_self, _process )
	-- body 
   
	-- HEARTBEAT_S2C = 0x02, -- 系统心跳包协议,服务器根据客户端类型,返回实际信息
	-- -- {process_type=PROCESS_TYPE.HEARTBEAT_S2C,  user_code="xxx" | machine_code="xxxx"
	-- --	balance=xx, nomove_balance=xx, integral=xx, player_status=xxx,room_code="xxx",
	-- --	machine_status=xx,用户在房间时返回该数据 
	-- --} 
	_process.process_type = PROCESS_TYPE.HEARTBEAT_S2C

	_process.data = _self:save_user_info() 
	-- 将当前用户的信息返回给所有用户 
	_self.ws:sendMsg(cjson.encode(_process))	
 	return true  

end
 

--[[
-- on_machine_sidelines_u2s  用户进入房间旁观,用户旁观机器时订阅房间消息
-- example  
	MACHINE_SIDELINES_U2S = 0x03,	 机器旁观指令,用户进入房间必须进行该操作,对于推币机 room_code 即房间编号, 旁观成功 code=200 非200 表示失败
			需要提醒用户
  		-- { process_type = PROCESS_TYPE.MACHINE_SIDELINES_U2S, user_code="xxx", room_code="xxxx" }  
	
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_machine_sidelines_u2s = function (_self, _process )
  	 
  	-- 1, 基础判断,参数和属性是否正确 
	if not _process.room_code or tostring( _process.room_code) == "" then 
		ngx.log(ngx.ERR,"player ",_self.user_code," on_heart_status_c2s ", " ,_process.room_code: ", _process.room_code) 
		_process.code = MACHINE_ERR_CODE.PARAM_ERROR
		_process.msg="room_code can not be  nil or nullstr"
		_self.ws:sendMsg(cjson.encode(_process)) 
	return nil end 

	-- 首先取消用户当前所在房间, 防止用户端没有退出当前房间成功,再次进入新房间,退订失败,可以让用户强制退出
	if _self.room_code then
	 	_self:unsubscribe_channel( ZS_ROOM_MSG_PRE_STR.._self.room_code ) 
	end
	
	_self.room_code = _process.room_code  
	_self.room_channel_name = ZS_ROOM_MSG_PRE_STR.._self.room_code

	local res,err = _self:subscribe_channel( _self.room_channel_name ) 
	if not res then
		ngx.log(ngx.ERR,"subscribe_channel error ",err," ",_self.room_channel_name, " ")
		_process.code = MACHINE_ERR_CODE.SYSTEM_BUSY
		_process.msg = "加入房间失败"
		_self.ws:sendMsg(cjson.encode(_process)) 
		return nil  
	end 

	_process.code = 200 
	-- 其他不做处理 当前需要将机器状态获取出来传递给用户
	_self.ws:sendMsg(cjson.encode(_process))  

		-- 旁观成功 + 1
	local redis_cli = _self.redis_cli_1
	if redis_cli then
		redis_cli:incr(SYSTEM_ON_LINE_USERS.._self.room_code)
		ngx.log(ngx.ERR,"-0-===----",redis_cli:get(SYSTEM_ON_LINE_USERS.._self.room_code))
	end
	-- 取消旁观 - 1 退出时如果还在房间, 则 - 1

	return true
	  
end


--[[
-- on_machine_sidelines_u2s  用户进入房间旁观,用户旁观机器时订阅房间消息
-- example  
	-- 退出机器房间旁观 ,退出旁观成功,code=200 标志,默认用户退出成功,如果退出失败,用户端可以从新连接
		-- {process_type = PROCESS_TYPE.MACHINE_OUTSIDELINES_U2S,user_code="xxx", room_code="xxxx" ,code=200 } 
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_machine_outsidelines_u2s = function (_self, _process ) 
  	-- 断开请求 
	-- 1, 基础判断,参数和属性是否正确 
	if not _process.room_code or tostring( _process.room_code) == "" or  _process.room_code ~= _self.room_code then 
		ngx.log(ngx.ERR,"player ",_self.user_code," on_heart_status_c2s ", " ,_process.room_code: ", _process.room_code) 
		_process.code = MACHINE_ERR_CODE.PARAM_ERROR
		_process.msg="room_code can not be  nil or nullstr"
		_self.ws:sendMsg(cjson.encode(_process)) 
	return nil end 
 
	if  _self.room_code  then
		-- 如果用户已经存在机器编号 则需要取消订阅
		_self:unsubscribe_channel( _self.room_channel_name ) 
	end  
	
	_process.code=200
	-- 其他不做处理
	_self.ws:sendMsg(cjson.encode(_process))  


	-- 旁观成功 + 1
	local redis_cli = _self.redis_cli_1
	if redis_cli then 
		local res = redis_cli:decr(SYSTEM_ON_LINE_USERS.._self.room_code)
		ngx.log(ngx.ERR,"-0-===----",redis_cli:get(SYSTEM_ON_LINE_USERS.._self.room_code))
	end
	-- 取消旁观 - 1 退出时如果还在房间, 则 - 1
	_self.room_code = nil
	return true
	  
end

--[[
-- send2machine 用户向机器发送消息
-- example  
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.send2machine = function(_self, _process)
	local redis_cli = _self.redis_cli_1 
	local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.machine_code
    local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
    if not res then 
    	ngx.log(ngx.ERR,"player ",_self.user_code," on_ask_for_machine_u2m redis_cli:publish err: ",err) 

    	_process.msg = "系统繁忙,请稍后再试!"

    	_process.code = MACHINE_ERR_CODE.SYSTEM_BUSY
    	_process.process_type = PROCESS_TYPE.ASK_FOR_MATHINE_M2U 
		-- 客户端机器将进行二次判断 将数据返回服务器
		_self.ws:sendMsg(cjson.encode(_process)) 
    	return nil
	end

	if res == 0 then
		ngx.log(ngx.ERR,"player publish false, the machine is not online!")  
    	_process.msg = "player publish false, the machine is not online!"  
    	_process.code = MACHINE_ERR_CODE.MACHINE_OFFLINE
    	_process.process_type = PROCESS_TYPE.ASK_FOR_MATHINE_M2U 
		_self.ws:sendMsg(cjson.encode(_process)) 
		return nil 
	end 
	return true
end
--[[
-- on_ask_for_machine_u2m  响应用户客户端发布的请求机器协议
-- example 
	ASK_FOR_MATHINE_U2M = 0x07 , 	-- 用户请求空闲机器 指令请求
		-- {process_type=PROCESS_TYPE.ASK_FOR_MATHINE_U2M,user_code="xxx",machine_code="xxxx"} 


-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]

_M.on_ask_for_machine_u2m = function (_self, _process ) 
	-- 1, 基础判断,参数和属性是否正确 
	if not _process.machine_code or tostring(_process.machine_code) == "" then 
		ngx.log(ngx.ERR," on_ask_for_machine_u2m _process.user_code: ",_self.user_code) 

		_process.code= MACHINE_ERR_CODE.PARAM_ERROR
		_process.msg="参数错误" 
		_process.process_type = PROCESS_TYPE.ASK_FOR_MATHINE_M2U
		_self.ws:sendMsg(cjson.encode(_process))  
		return nil end 

	-- 用户是否请求了多个机器
 	if _self.machine_code and _self.machine_code ~= _process.machine_code then 
		ngx.log(ngx.ERR,"用户请求多个机器,用户已经申请了一个机器,错误操作!!!")
		_process.code=MACHINE_ERR_CODE.USER_ASK_MULTY_MACHINE
		_process.msg="用户已经申请了一个机器,错误操作!!!".._self.machine_code 
		_process.process_type = PROCESS_TYPE.ASK_FOR_MATHINE_M2U 
		_self.ws:sendMsg(cjson.encode(_process)) 
		return nil 
	end



	local res = _self:send2machine(_process)
	if not res then 

		  return nil
	end

	-- 如果已经在请求状态,就直接返回错误  
	local res = online_union_help.set_online_redis(_self.user_asking_machine_key,_self.user_code,10)
	if  not res or res == 0 then 
		ngx.log(ngx.ERR,"player ",_self.user_code," on_ask_for_machine_u2m game_asking ") 
		_process.code = MACHINE_ERR_CODE.ON_ASKING_MACHINE
		_process.msg = "正在申请中,请稍后!!!" 
		_process.process_type = PROCESS_TYPE.ASK_FOR_MATHINE_M2U 
		_self.ws:sendMsg(cjson.encode(_process)) 
		return nil
	end
 	 
    _self.player_status = PLAYER_STATUS.MACHINE_ASKING

    -- 开启定时器判断请求,如果超时5秒则认为断开连接 发起断开请求 
    local timer = timer_help:new(_self.on_ask_for_machine_u2m_timer_func, _self,_process)

    -- 定时器开启超时操作, 定时器超时3秒,如果还未到达,则自动通知用户,并且将上次消息设置为丢失状态
    timer:timer_at(3)

    return res

end

--[[ 
on_timer_func 时间回调用函数,
-- example 

-- @param _timeself 时间对象本身,不使用
-- @param _self 用户需要组装的数据参数表,其中record 的元素信息必须为key=value的格式
				key为表的字段名
-- @param _process 搜索语句的条件,主要表现为字符串	 
--]]
-- _M.on_ask_for_machine_u2m_timer_func = function( _timeself,_self,_process)


--[[ 
on_timer_func 时间回调用函数,非openresty 版本
-- example 

-- @param _timeself 时间对象本身,不使用
-- @param _self 用户需要组装的数据参数表,其中record 的元素信息必须为key=value的格式
				key为表的字段名
-- @param _process 搜索语句的条件,主要表现为字符串	 
--]]

_M.on_ask_for_machine_u2m_timer_func = function(_self,_process)
	-- body
 	if _self.player_status == PLAYER_STATUS.MACHINE_ASKING then
 		-- 超过五秒之后关闭通知用户请求失败
 		_process.code = MACHINE_ERR_CODE.ASK_MACHINE_TIME_OUT
 		_process.msg = "请求超时"
 		_process.process_type = PROCESS_TYPE.ASK_FOR_MATHINE_M2U

 		_self.ws:sendMsg(cjson.encode(_process)) 
 		-- local redis_cli = redis_help:new();
	  --   if not redis_cli then
	  --       ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
	  --       _self.ws:exit(200)
	  --       return nil
	  --   end 

	  --   local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._self.user_code
	  --   local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
	  --   if not res then 
	  --   	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_rewards_m2u redis_cli:publish err: ",err) 
	  --   	_self.ws:exit(200)
	  --   	return nil end 
 		-- _self.ws:sendMsg(cjson.encode(_process))
 		_self.player_status = PLAYER_STATUS.SIDELINES
 	end 
end

--[[
-- on_ask_for_machine_m2u  响应用户客户端发布的请求机器协议
-- example 
	ASK_FOR_MATHINE_M2U = 0x08,		-- 机器回复客户端 请求返回 成功或者失败
		-- {process_type=PROCESS_TYPE.ASK_FOR_MATHINE_M2U,user_code="xxx",machine_code="xxxx",code=200,msg="xxx",
		player_status=  PLAYER_STATUS.ON_GAME ,
		machine_code=xxx} code 200 表示成功 非200 表示失败

	 如果服务器接收信息却没有回复  则系统将读取redis的判断缓存
-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功
--]]
_M.on_ask_for_machine_m2u = function (_self, _process )
	-- body  
	online_union_help.delete_online_redis(_self.user_asking_machine_key)
	if _self.player_status ~= PLAYER_STATUS.MACHINE_ASKING then
		-- 通知机器断开超时
		local _dis_process = {
			process_type = PROCESS_TYPE.ASK_FOR_DISCONNECT_U2M,
			sub_type = 1, -- 
			user_code=_self.user_code,
			machine_code=_process.machine_code,
		}

		local redis_cli = _self.redis_cli_1 
		local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.machine_code
	    	redis_cli:publish(channel_name, cjson.encode(_dis_process)) 
		return nil
	end 

 	if _process.code == 200 then   
		_self.machine_code = _process.machine_code
		_self.player_status = PLAYER_STATUS.ON_GAME  
		_self:save_user_info()
 	else
 		 _self.player_status = PLAYER_STATUS.SIDELINES
 	end 
 	
	-- _process.msg = "请求成功" 
	-- 客户端机器将进行二次判断 将数据返回服务器
	_self.ws:sendMsg(cjson.encode(_process))	 
	return true
end



--[[
-- on_slot_u2m  用户投币操作
-- example 
	SLOT_U2M = 0x09,	-- 用户客户端投币 一期默认为投币一枚 ,扣除的游戏币和获得,由系统进行定义,默认配置为1:1
		-- {process_type=PROCESS_TYPE.SLOT_U2M,user_code="xxx",machine_code="xxxx",coins=1} 

-- @param _self 当前用户对象
-- @param _process 协议结构表  
-- @return nil 表示失败 true 表示成功
--]]
_M.on_slot_u2m = function (_self, _process )
	-- body 
	if _self.player_status ~= PLAYER_STATUS.ON_GAME then
		ngx.log(ngx.ERR,"player ",_self.user_code," on_slot_u2m is not on game!!") 
		_process.code =  MACHINE_ERR_CODE.PARAM_ERROR
		_process.msg = "player is not on game!" 
		_self.ws:sendMsg(cjson.encode(_process)) 
		return nil
	end   

	return _self:send2machine(_process) 
end


--[[
-- on_slot_m2u  投币成功 通知用户
-- example 
SLOT_M2U = 0x0a,	-- 投币成功返回客户端
		-- {process_type=PROCESS_TYPE.SLOT_M2U,code=200 ,user_code="xxx",machine_code="xxxx",coins=1,
			balance=50,
			balance=xxx,bet_flow_code = 'xxxx'}


-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_slot_m2u = function (_self, _process )
	-- body 
   if _process.code == 200 then
	-- 投币成功 进行扣费操作,同时写入数据库!!!!!! 修改账户信息,账户余额返回
	--------------------------------db opt--------------------------------
		_self.balance = _self.balance - _process.balance 
	-- 用户每次投币完成,记录一次,  
	end
	_process.balance = _self.balance 
	-- 客户端机器将进行二次判断 将数据返回服务器
	_self.ws:sendMsg(cjson.encode(_process)) 

	return true
end
 


--[[
-- on_rewards_m2u  用户获利之后的奖励
-- example 
	MACHINE_REWARDS_M2U = 0x0b,	-- 机器通知服务器中奖
	-- {process_type=PROCESS_TYPE.MACHINE_REWARDS_M2U,
	-- user_code="xxx",machine_code="xxxx",coins=xxx, machine_rewardsing = true }

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_rewards_m2u = function (_self, _process )
	-- body 
	-- 投币成功 进行扣费操作,同时写入数据库!!!!!! 修改账户信息,账户余额返回
	--------------------------------db opt--------------------------------
	_self.integral = _self.integral + _process.integral
 	
	--------------------------------db opt--------------------------------
	_process.integral = _self.integral
	-- 客户端机器将进行二次判断 将数据返回服务器
	_self.ws:sendMsg(cjson.encode(_process))	
 	

	return true
end



--[[
-- on_ask_for_disconnect_u2m  用户主动 离开 或断开 机器请求
-- example 
	ASK_FOR_DISCONNECT_U2M = 0x0c, 	-- 用户退出请求,服务器将断开用户的机器绑定,如果机器正在结算状态,机器将一直等到结算结束之后,再通知服务器状态为空闲
		-- {process_type=PROCESS_TYPE.ASK_FOR_DISCONNECT_U2M,user_code="xxx", machine_code="xxxx"}  

-- @param _self 当前用户对象
-- @param _process 协议结构表  
-- @return nil 表示失败 true 表示成功
--]]
_M.on_ask_for_disconnect_u2m = function (_self, _process )  
	-- 用户强行断开
	if not _process.machine_code or not _self.machine_code or  _self.machine_code~=_process.machine_code then 
		_process.code =  MACHINE_ERR_CODE.PARAM_ERROR
		_process.msg = "机器编号为空或发送者与机器不匹配!" 
		_self.ws:sendMsg(cjson.encode(_process)) 
		return nil 
	end

-- 清除用户在线状态
	-- online_union_help.delete_online_redis(ZS_MACHINE_ONLINE_PRE.._self.user_code)  

	-- 客户端机器将进行二次判断 将数据返回服务器
	-- _process.process_type = PROCESS_TYPE.ASK_FOR_DISCONNECT_M2U
	-- _self.ws:sendMsg(cjson.encode(_process)) 
    
    _self.machine_code = nil
	return _self:send2machine(_process)
end


--[[
-- on_ask_for_disconnect_m2u  响应用户客户端发布的请求机器协议
-- example 
	ASK_FOR_DISCONNECT_M2U = 0x0d,	-- 主动退出返回数据,返回状态可能包括断开成功
		-- {process_type=PROCESS_TYPE.ASK_FOR_DISCONNECT_M2U,user_code="xxx",machine_code="xxxx",code=200} 

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_ask_for_disconnect_m2u = function (_self, _process )
	-- body
	-- 1, 基础判断,参数和属性是否正确 
	 
	if _process.machine_code == _self.machine_code and _process.user_code == _self.user_code then  
		_self.player_status = PLAYER_STATUS.SIDELINES 
 		_self.machine_code = nil
	end
  	_self:save_user_info() 
 	-- 客户端机器将进行二次判断 将数据返回服务器
	-- _self.ws:sendMsg(cjsosn.encode(_process))	 
	-- if _process.code == 200 then  
	 -- 		if _process.user_code == _self.user_code then
	 -- 			_self.machine_code = _process.machine_code 
		-- 		online_union_help.delete_online_redis(ZS_USER_MACHINE_ASKING_PRE.._self.user_code)
	 -- 		end
	 -- 	else
	 -- 		 _self.player_status = PLAYER_STATUS.SIDELINES
	 -- 	end 
	-- _process.msg = "请求成功" 
	-- 客户端机器将进行二次判断 将数据返回服务器
	_self.ws:sendMsg(cjson.encode(_process))

	return true
end


	
--[[
-- on_machine_error_u2m  玩家主动发起机器故障,收到该事件,通知管理员进行排查,注意故障
-- example 
	MACHINE_ERROR_U2M = 0x0e,	-- 玩家上报故障,当机器收到该故障时,需要记录当前机器的故障时间,如果正在中奖的吐币,
								-- 管理员修复之后该台机器完成之后自动进行后续结算操作,结算完毕之后才可以放行,同时通知该机器的管理员查看
		-- {process_type=PROCESS_TYPE.MACHINE_ERROR_U2M,user_code="xxx",machine_code="xxxx" }

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_machine_error_u2m = function (_self, _process )
	-- 1, 基础判断,参数和属性是否正确  
	-- 故障时需要对用户的投币操作进行一次清算和操作
	--------------------------------player account opt--------------------------------
	if not _self.machine_code then 
		ngx.log(ngx.ERR,"machine ",_self.machine_code," on_machine_error_u2m ,_process.machine_code: ",_process.machine_code) 
		_process.code =  MACHINE_ERR_CODE.PARAM_ERROR
		_process.msg = "机器编号为空或发送者与机器不匹配!" 
		_self.ws:sendMsg(cjson.encode(_process)) 
	return nil end   
	--------------------------------player account opt--------------------------------
 	_self.machine_code = nil 
 	-- 客户端机器将进行二次判断 将数据返回服务器
	_self.ws:sendMsg(cjson.encode(_process))	
    
	return _self:send2machine(_process)
end




--[[
-- on_machine_error_m2u  机器故障 通知玩家
-- example 
	MACHINE_ERROR_M2S = 0x0f,	-- 机器上报故障记录时, 操作过程同MACHINE_ERROR_S2M
		-- {process_type=PROCESS_TYPE.MACHINE_ERROR_M2S,user_code="xxx",machine_code="xxxx" }

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_machine_error_m2u = function (_self, _process )
	-- 1, 基础判断,参数和属性是否正确  
	-- 故障时需要对用户的投币操作进行一次清算和操作
	--------------------------------player account opt--------------------------------
 
	--------------------------------player account opt--------------------------------
 	_self.machine_code = nil 
 	_self.player_status = PLAYER_STATUS.SIDELINES
 	-- 客户端机器将进行二次判断 将数据返回服务器
	_self.ws:sendMsg(cjson.encode(_process))	
 
	return true
end



--[[
-- on_queue_up_u2s  排队
-- example 
	QUEUE_UP_U2S = 0x10,		-- 用户排队请求,排队主要针对于机器排队管理,客户端需要做如下处理,随机排队,
								-- 客户端本地查询合适的机器进行界面切换和排队请求
		-- {process_type=PROCESS_TYPE.QUEUE_UP_U2S,user_code="xxx",machine_code="xxxx"}

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_queue_up_u2s = function (_self, _process)
	-- body
	-- 1, 基础判断,参数和属性是否正确  
    
    return _self:send2machine(_process)
 	  
end


--[[
-- on_queue_up_s2u  排队回复,机器排队回复消息,成功or失败,大多数时间为成功
-- example 
	QUEUE_UP_S2U = 0x11,		--[[ 用户排队请求返回,排队主要针对于机器排队管理, 排队成功通过房间消息通知用户,排队队列变化
						-- 客户端本地查询合适的机器进行界面切换和排队请求
		-- {process_type=PROCESS_TYPE.QUEUE_UP_S2U, user_code="xxx",machine_code="xxxx", code=200|400}

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_queue_up_s2u = function (_self, _process)
	-- body
	-- 1, 基础判断,参数和属性是否正确 
	if _process.code == 200 then
		_self.queue_machine_code = _process.machine_code
		_self.player_status = PLAYER_STATUS.QUEUE_UP
	end

	_self.ws:sendMsg(cjson.encode(_process))
	return true
end

--[[
-- on_queue_cancel_u2s  取消排队
-- example 
	QUEUE_CANCEL_U2S = 0x12,	--[[ 用户取消排队请求 操作流程与排队
		-- {process_type=PROCESS_TYPE.QUEUE_CANCEL_U2S, user_code="xxx",machine_code="xxxx"}  
		]]

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_queue_cancel_u2s = function (_self, _process)
	-- body
	-- 1, 基础判断,参数和属性是否正确  
	_self.player_status = PLAYER_STATUS.SIDELINES
	_process.machine_code = _self.queue_machine_code
	_self.queue_machine_code = nil
	-- redis订阅,订阅返回  
  	return _self:send2machine(_process)
end



--[[
-- on_queue_cancel_s2u  取消排队 系统回复
-- example 
	QUEUE_CANCEL_S2U = 0x13,	-- 取消排队回复
	-- {process_type=PROCESS_TYPE.QUEUE_CANCEL_S2U, user_code="xxx",machine_code="xxxx", code=200|400}  

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_queue_cancel_s2u = function (_self, _process)
	-- body
	-- 1, 基础判断,参数和属性是否正确 
	_self.player_status = PLAYER_STATUS.SIDELINES
	_process.machine_code = _self.queue_machine_code
	_self.queue_machine_code = nil
	_self.ws:sendMsg(cjson.encode(_process))
	return true
end


--[[
-- on_queue_on_s2u  系统通知用户所在的机器准备好
-- example 
	QUEUE_ON_S2U = 0x14,		-- 系统通知用户所在的机器准备好
 		-- {process_type=PROCESS_TYPE.QUEUE_ON_S2U, user_code="xxx",machine_code="xxxx", code=200}  

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_queue_on_s2u = function (_self, _process)
	-- body
	-- 1, 基础判断,参数和属性是否正确 
	ngx.log(ngx.ERR,"---------- queue ok ", cjson.encode(_process))
	_process.user_code = _self.user_code
	_self.ws:sendMsg(cjson.encode(_process))	 
    return true
end
  
 

--[[
-- on_queue_cancel_on_u2s  取消排队
-- example 
	QUEUE_ON_S2U = 0x14,		-- 系统通知用户所在的机器准备好
 		-- {process_type=PROCESS_TYPE.QUEUE_ON_S2U, user_code="xxx",machine_code="xxxx", code=200}  

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_queue_cancel_on_u2s = function (_self, _process)
	-- body
	-- 1, 基础判断,参数和属性是否正确 
	_self.player_status = PLAYER_STATUS.SIDELINES
	_process.machine_code = _self.queue_machine_code
	_self.queue_machine_code = nil
	return _self:send2machine(_process)  
 
end

--[[
-- on_ask_for_yugua_u2m  雨刮控制器  控制指令
-- example 
	MACHINE_YUGUA_U2M = 0x16, -- 雨刮器控制协议
	-- {process_type=PROCESS_TYPE.MACHINE_YUGUA_U2M,user_code="xxx",machine_code="xxxx"}


-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_ask_for_yugua_u2m = function (_self, _process )
	-- body
	-- 1, 基础判断,参数和属性是否正确  
	if not _self.machine_code then return end
	-- redis订阅,订阅返回
	 return _self:send2machine(_process)
end


--[[
-- on_machine_break_ms2us  响应机器掉线通知
-- example  
		MACHINE_BREAK_MS2US = 0x18, -- 机器断开则通知所有的房间玩家, 玩家可以自行选择退出房间或等待恢复
		-- {process_type = PROCESS_TYPE.MACHINE_BREAK_MS2US,user_code="xxx",machine_code="xxxx"} 
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_machine_break_ms2us = function(_self,_process)
	 _self.ws:sendMsg(cjson.encode(_process))  
end
 
--[[
-- on_client_offline_s2u   
-- example 
	CLIENT_OFFLINE_S2U = 0x1a,	-- 用于用户重复登录情况,强行将用户或者机器T下线
		-- {process_type=PROCESS_TYPE.CLIENT_OFFLINE_S2U,user_code="xxx" | machine_code="xxxx"} 
 
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_client_offline_s2u = function (_self, _process )   
	
	if _self.online_uuion == _process.online_uuion then
		return true
	end

	_self.ws:sendMsg(cjson.encode(_process))
 	
 	ngx.sleep(1) 
	_self.ws.closeFlag = true  
    return true
end

--[[
-- on_machine_notice_s2u  用户平台发送所在机器放假发送消息
-- example 
    MACHINE_NOTICE_S2U = 0x19, -- 机器主动通知事件,包括机器新玩家,排队提醒,中大奖等
    	-- {process_type = PROCESS_TYPE.CLIENT_BREAK_M2U,sub_type = xx, data = {},  user_code="xxx",machine_code="xxxx"} 
 
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_machine_notice_s2u = function (_self, _process )   
	-- local channel_name = ZS_ROOM_MSG_PRE_STR.._self.room_code
	-- local redis_cli = redis_help:new();
 --    if not redis_cli then
 --        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
 --        return nil
 --    end 
 --   	redis_cli:publish(channel_name, cjson.encode(_process))

  	_self.ws:sendMsg(cjson.encode(_process)) 
    return true
end

--[[
-- player_break_us2ms   -- 专用指令 用户断线,主动通知机器,客户端断开,机器将进入倒计时状态
							超过时间,则通知机器端断开请求,将会通知读取之前的数据信息,如果为空,则直接返回   
-- example  
	PLAYER_BREAK_US2MS = 0x17,	-- 用户断开,主要用于正在玩的用户玩家,通知通知游戏服务器进行状态管理,当超时未连接进来,通知机器端用户退出
		-- {process_type=PROCESS_TYPE.PLAYER_BREAK_US2MS,user_code="xxx",machine_code="xxxx"} 
-- @param _self 当前用户对象
 
--]]
_M.player_break_us2ms = function(_self)
	-- 1, 基础判断,参数和属性是否正确 
	if not _self.machine_code then
		return 
	end
	local _process = {
			process_type = PROCESS_TYPE.PLAYER_BREAK_US2MS,
			user_code =_self.user_code,
			machine_code = _self.machine_code, 
			is_visitor = _self.is_visitor,
			time = os.time()
	}

	-- redis订阅,通过订阅通知游戏客户端 系统返回情况
	local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.machine_code   

	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 
    
    local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_machine_pullpoints_m2u redis_cli:publish err: ",err) 
    	return nil end 
    	
	return true 
end
  
--[[
-- on_client_offline_s2u   -- 用户断开,主要用于正在玩的用户玩家,通知通知游戏服务器进行状态管理,当超时未连接进来,通知机器端用户退出
-- example  
	PLAYER_BREAK_US2MS = 0x17,	-- 用户断开,主要用于正在玩的用户玩家,通知通知游戏服务器进行状态管理,当超时未连接进来,通知机器端用户退出
		-- {process_type=PROCESS_TYPE.PLAYER_BREAK_US2MS,user_code="xxx",machine_code="xxxx"} 
-- @param _self 当前用户对象
 
--]]
_M.on_client_offline_s2u1 = function(_self,_process)
	-- 1, 基础判断,参数和属性是否正确  
	-- redis订阅,通过订阅通知游戏客户端 系统返回情况
	if _self.online_uuion ~= _process.online_uuion then
		_self.ws.closeFlag = true 
	end

	return true 
end




--[[
-- on_wechat_msg_u2s 客户端发送消息, 用户端进行分发
-- example  
	-- 第一期的聊天协议
  	WECHAT_MSG_U2S = 0x05,	-- 发送者, from_code 发送者信息, at_code提醒者信息, room_code房间编号
  		-- {process_type = PROCESS_TYPE.WECHAT_MSG_U2S, from_code="xxx", at_code="xxx", room_code="xxxx",msg="xxx"} 
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_wechat_msg_u2s = function (_self, _process ) 

	_process.process_type = PROCESS_TYPE.WECHAT_MSG_S2U
	local redis_cli = _self.redis_cli_1
   
    local res, err = redis_cli:publish(_self.room_channel_name, cjson.encode(_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_machine_pullpoints_m2u redis_cli:publish err: ",err) 
    	return nil end  

	return true
	  
end


--[[
-- on_wechat_msg_s2u 客户订阅收到消息
-- example  
  	WECHAT_MSG_S2U = 0x06,  -- 接收者信息
  		-- {process_type = PROCESS_TYPE.WECHAT_MSG_S2U, from_code="xxx", at_code="xxx",room_code="xxxx",msg="xxx"} 
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_wechat_msg_s2u = function (_self, _process ) 
  	-- 断开请求
  	-- 1, 基础判断,参数和属性是否正确  
 	if _process.from_code ~= _self.user_code then
 		-- redis订阅,通过订阅通知游戏客户端 系统返回情况 
		_self.ws:sendMsg(cjson.encode(_process))
 	end
  
	return true
	  
end


--[[
-- on_heart_status_c2s  -- 订阅新频道 收到指令执行该操作 在用户的redis客户端完成长链接订阅
-- example 
	 
-- @param _self 当前用户对象
-- @param _channel_name 订阅频道
-- @param _process 协议结构表  
--]]
_M.subscribe_channel = function (_self, _channel_name )
	-- body
	-- 1, 基础判断,参数和属性是否正确 
	if not _channel_name or not _self.redis_cli then  
		return nil
	end
    
	local res, err = _self.redis_cli:subscribe(_channel_name)
  	if not res and err ~= "socket busy reading" then
  		ngx.log(ngx.ERR,"subscribe err:",err,", channel_name is ",_channel_name,".")
  		return nil 
    end  
    ngx.log(ngx.ERR, "error is ",err) 
	_self.subscript_map[_channel_name] = _channel_name
	return true
end

--[[
-- on_unsubscribe_new_channel  -- 取消订阅
-- example 
	
	UNSUBSCRIBE_NEW_CHANNEL = 0x16,
	-- {process_type=PROCESS_TYPE.UNSUBSCRIBE_NEW_CHANNEL,  user_code="xxx",  channel_name="xxxx"}

-- @param _self 当前用户对象
-- @param _channel_name 订阅频道
-- @param _process 协议结构表  
--]]
_M.unsubscribe_channel = function (_self, _channel_name )
	-- body
		-- 1, 基础判断,参数和属性是否正确 
	if not _channel_name or not _self.redis_cli then  
		return nil
	end

    if _self.subscript_map[_channel_name] then
    	return nil
    end

	local res, err = _self.redis_cli:unsubscribe(_channel_name)
  	if not res and err ~= "socket busy reading" then
  		ngx.log(ngx.ERR,"unsubscribe err:",err,", channel_name is ",_channel_name,".",_channel_name == "")
  		return nil 
    end  
 
	_self.subscript_map[_channel_name] = _channel_name 
	return true  
end
  
 
_M.server_heart_timer_cb = function(_timeself,_self  )
	-- body 
	local _process = {
		process_type 	=PROCESS_TYPE.HEARTBEAT_S2C,  
		balance 		=_self.balance,
		nomove_balance 	=_self.nomove_balance,
		integral		=_self.integral,
		player_status 	= _self.player_status,
		room_code 		= _self.room_code, 
	} 
	local res = _self.ws:sendMsg(cjson.encode(_process))

	if not res then
		_self.ws:exit(200)
	end

	local ok, err = ngx.timer.at(3, _self.server_heart_timer_cb,_self)
	if not ok then
	    ngx.log(ngx.ERR, "failed to create the timer: ", err)
	end  
end


_M.timer_func = function (_timeself, _self, _process,_ws )
	-- body
	ngx.log(ngx.ERR,cjson.encode(_process),_self.user_code)
	-- local res = _ws:sendMsg("wwwwww")
 	-- ngx.log(ngx.ERR,"res:",res," .")

 	local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._self.user_code 

	_process.process_type = PROCESS_TYPE.WECHAT_MSG_S2U
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 

    local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_machine_pullpoints_m2u redis_cli:publish err: ",err) 
    	return nil end 

	return true 
end


--[[ 
-- example 
 
-- @param  用户需要组装的数据参数表,其中record 的元素信息必须为key=value的格式
				key为表的字段名
-- @param _process 搜索语句的条件,主要表现为字符串	 
--]]
_M.dispatch_process = function (_self,_process )
	-- body
	if not _process or _process == ngx.null then 
		ngx.log(ngx.ERR,'-------- 错误数据', _process)
		return nil end
	if _process.process_type ~= 0x01 then
        ngx.log(ngx.ERR,string.format("--player -- %s,uuid:%s function:%s , proecss:%s",
        	_self.user_code,_self.online_uuion ,PROCESS_FUNC_MAP[_process.process_type],cjson.encode(_process)))
    end   

    if not _process.msgid then
		_process.msgid = uuid_help:get64()   
	end
 		 _process.is_visitor = 1
      	local lock, err = resty_lock:new("ngx_locks")
        if not lock then
            ngx.log(ngx.ERR,"failed to create lock: ", err)
            -- 消息未执行 如何处理???

            -- 
        else 
        	local elapsed, err = lock:lock(_self.online_uuion)
            
    		local redis_cli = redis_help:new();
		    if not redis_cli then
		        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
		    	_process.code = MACHINE_ERR_CODE.SYSTEM_BUSY
		    	_process.msg = "系统繁忙,请稍后再试!" 
				-- 客户端机器将进行二次判断 将数据返回服务器
				_process.sub_type = _process.process_type
				_process.process_type = PROCESS_TYPE.SYSTEM_ERROR_S2U
				_self.ws:sendMsg(cjson.encode(_process)) 
		        return nil
		    end 

		    _self.redis_cli_1 = redis_cli

           local res = _self[PROCESS_FUNC_MAP[_process.process_type]](_self,_process) 

           local ok, err = lock:unlock()
           if not ok then
               ngx.log(ngx.ERR,"failed to unlock: ", err)
           end
           return res
        end  
	
	-- ngx.log(ngx.ERR,"  player dispatch_process  ",cjson.encode(_process)," ",res)
	-- local ok,res = pcall( _self[PROCESS_FUNC_MAP[_process.process_type]],_self,_process) 
	-- _process.msgid = uuid_help:get64()  
	-- local ok, err = ngx.timer.at(1, _self.timer_func,_self,_process,_self.ws)
	-- if not ok then
	--     ngx.log(ngx.ERR, "failed to create the timer: ", err)
	-- end
	
end
 
 

return _M