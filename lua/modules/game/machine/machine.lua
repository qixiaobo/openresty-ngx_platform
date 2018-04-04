--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:machine.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  机器玩家的功能操作对象
--  
--]]

local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local bit_help = require "common.bit_help" 
local uuid_help = require "common.uuid_help"
local clazz = require "common.clazz.clazz"
local redis_queue_help = require "common.db.redis_queue_help"
local online_union_help = require "common.online_union_help"
local timer_help = require "common.timer_help"
local resty_lock = require "resty.lock"




local machine_process = require "game.machine.machine_process"
local machine_bet_records = require "game.machine.model.machine_bet_records"

local PROCESS_TYPE = machine_process.PROCESS_TYPE
local PLAYER_STATUS = machine_process.PLAYER_STATUS
local MACHINE_STATUS = machine_process.MACHINE_STATUS
local PROCESS_SUB_TYPE = machine_process.PROCESS_SUB_TYPE
local MACHINE_ERR_CODE = machine_process.MACHINE_ERR_CODE 
local PROCESS_FUNC_MAP = machine_process.PROCESS_FUNC_MAP

local MACHINE_ONLINE_TIME_OUT = 15

-- 用户父表,其他游戏可以集成该表 扩充字段

local _M = {
online_uuion = nil,
	machine_room_code = "",			-- 机器所在房间编号
	machine_code = "xx",
	machine_status = MACHINE_STATUS.ON_IDLE ,	-- 机器 
	user_code = nil,			-- 占用当前机器的用户编号
	level = 1,					-- 等级

	machine_rewards_ratio = 1.0, -- 机器兑换系数
	machine_cost_ratio = 1.0,	-- 机器消费系数

	machine_filed_code = "",	-- 机器所在的场次
	machine_district_code = "10001",	-- 机器区服,当机器区服未设置,则系统不需要写入district+filed_code 信息

	player_queue= {},				-- 排队列表
	machine_rewardsing = false,		-- 正在数币 
	machine_on_liquidation = false,	-- 清算状态
	is_visitor = 0,

	machine_channel_name = nil,		-- 机器在线的 channel name 
	machine_online_key = nil,		-- 机器状态存储 key
 	room_channel_name = nil,	-- 用户进入房间之后的 channel 名称
 	machine_status_key = nil,	-- 机器状态key
}
  
_M.__index = _M  
setmetatable(_M,clazz)  -- _M 继承于 clazz
  

--[[
-- machine_init 机器初始化
-- example 
 
-- @param _machine_code 机器编号
-- @param _machine_token 机器有效token
--]]
_M.machine_init = function( _self, _machine_code, _machine_token )
    -- body 
    _self.online_uuion = uuid_help:get64() 
    _self.machine_channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._machine_code
    _self.machine_online_key = ZS_MACHINE_ONLINE_PRE.._machine_code

	-- 进行唯一性登录判断
	local res = online_union_help.set_online_redis( _self.machine_online_key, "",MACHINE_ONLINE_TIME_OUT)
	if not res then  
		return nil
	end 

	local redis_cli = redis_help:new();
    if not redis_cli then 
    	ngx.log(ngx.ERR,"new redis cli error")
      	return nil
    end   

	if res == 0 then
		-- 发送请求,强行关闭机器 
	    -- redis订阅,通过 另外一个订阅系统的机器下线
		local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._machine_code
		local _process = {
			process_type = PROCESS_TYPE.CLIENT_OFFLINE_S2U,  
			machine_code=_machine_code,
			online_uuion = _self.online_uuion,
		}

	    local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
	    if not res then 
	    	ngx.log(ngx.ERR,"machine ",_process.machine_code," on_machine_pullpoints_m2u redis_cli:publish err: ",err)
	    	return nil 
	    end   
	    ngx.sleep(3)
	end

    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
        return nil,1041;
    end 
 
    local sql = string.format([[
    	select t_machine.*, 
	t_game_filed.filed_cost_once,t_game_filed.filed_less_balance,t_game_filed.filed_rewards_ratio,t_machine_room.*
	 from t_machine 
	left join t_machine_room on t_machine.machine_room_code_fk=t_machine_room.machine_room_code 
	left join t_game_filed on t_game_filed.filed_code = t_machine_room.machine_field_code_fk
	where t_machine.machine_code = '%s' and t_machine.machine_token = '%s' and t_machine.machine_status < 3  ;
	]],_machine_code,_machine_token)



    local res, err, errcode, sqlstate = mysql_cli:query(sql) 
    if not res then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
         
        return nil, errcode;
    end 
  
    if #res ~= 1 then
	  	ngx.log(ngx.ERR,"bad result: machine_code or machine_token error", "."); 
        return nil,errcode;
    end

    _self.machine_code = _machine_code
    _self.machine_token = _machine_token
    -- 每次获得一次投币,获取多少积分的倍率,
    _self.machine_rewards_ratio = res[1].filed_cost_once
    _self.machine_cost_ratio = res[1].filed_rewards_ratio


	_self.machine_status = MACHINE_STATUS.ON_IDLE  
 	_self.machine_district_code = res[1].districs_code_fk
 	_self.machine_filed_code = res[1].machine_field_code_fk
 	_self.machine_room_code = res[1].machine_room_code_fk
 	_self.player_queue = {}
	
	_self.room_channel_name	= ZS_ROOM_MSG_PRE_STR.._self.machine_room_code
 
	ngx.log(ngx.ERR,cjson.encode(res[1]))

	local _process = {
		process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,
		sub_type = PROCESS_SUB_TYPE.MACHINE_INIT,  
		data = { 
			machine_code = _self.machine_code,
			machine_room_code = _self.machine_room_code,
			machine_status = _self.machine_status,
		}
	} 
 

 	local _data = online_union_help.get_online_redis(ZS_MACHINE_ONLINE_PRE.._machine_code)
 	if  _data and _data ~= "" then  
 		local data = cjson.decode(_data)

 		if data.machine_status == MACHINE_STATUS.ON_GAME  
 			or data.machine_status == MACHINE_STATUS.MACHINE_ON_WAITING
 			or data.machine_status == MACHINE_STATUS.ON_LIQUIDATION
 			or data.machine_status == MACHINE_STATUS.ON_QUEUE
 			or data.machine_status == MACHINE_STATUS.ON_SEAT  then 

		 		_self.user_code = data.user_code
		 		_self.player_queue = data.player_queue
		 		_self.is_visitor = data.is_visitor  
		 		_self.machine_status = data.machine_status 
		 
				_process.data.machine_status = _self.machine_status
				_process.data.user_code = _self.user_code
				_process.data.is_visitor = _self.is_visitor
				_process.data.player_queue = data.player_queue 
				if _self.machine_status == MACHINE_STATUS.ON_SEAT then
		 			local time_left = online_union_help.get_left_time(_self.user_seat_machine_key)
		 			if time_left > 0 then 
		 				_process.data.seat_left_time = time_left
		 			end

	 			end 

		end 
	end  

	if _self.user_code and _self.is_visitor == 0 then -- 通知用户继续
		_self.machine_status = MACHINE_STATUS.MACHINE_ON_WAITING 
	elseif #_self.player_queue ~= 0 and _self.machine_status == MACHINE_STATUS.ON_IDLE then
		-- 执行排队操作
		_self:machine_queue_opt(redis_cli) 
	end 

	if _self.is_visitor == 1 then
		_self.machine_status = MACHINE_STATUS.ON_IDLE 
	end
 
 	local res, err = redis_cli:publish(_self.room_channel_name, cjson.encode(_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_process.machine_code," on_machine_pullpoints_m2u redis_cli:publish err: ",err)
    	return nil 
    end     

    -- 通知机器当前上一次系统状态,用于机器故障,新机器替换 !!!!!
	_self.ws:sendMsg(cjson.encode(_process))  
	-- ngx.log(ngx.ERR,"0-------",cjson.encode(_process))


    -- 每台机器需要将自己的信息发布游戏机的状态系统中
	local machine_status_key = ZS_MACHINE_FIELD_PRE
	if _self.machine_district_code then
		machine_status_key = machine_status_key..":".._self.machine_district_code
	end

	if _self.machine_filed_code then
		machine_status_key = machine_status_key..":".._self.machine_filed_code
	end 
	local machine_inf = {
		process_type = PROCESS_TYPE.HEARTBEAT_S2C,
		machine_room_code = _self.machine_room_code,
		machine_status = _self.machine_status,
		user_code = _self.user_code,
		player_queue = _self.player_queue,
		player_counts = _self.player_counts,
		stream_addr = _self.stream_addr,
		stream_slave_addr = _self.stream_slave_addr,
		update_time = os.time(),
		is_visitor = _self.is_visitor,
	}

	ngx.log(ngx.ERR,"------------",machine_status_key," machine_inf ",cjson.encode(machine_inf))
	_self.machine_status_key = machine_status_key 

	redis_cli:hset(machine_status_key, _self.machine_room_code..":".._self.machine_code, cjson.encode(machine_inf))  

    return true

end


--[[
-- update_online_status  机器状态更新,主要将机器的重要状态放入系统

-- example 机器将数据更新进redis中间缓存
	 
-- @param _self 当前用户对象  
--]]
_M.update_online_status = function (_self,_time_out)
	local _data = { 
		machine_room_code = _self.machine_room_code,
		machine_code 	= _self.machine_code,
		user_code 		= _self.user_code,
  		machine_status 	= _self.machine_status,
		online_uuion 	= _self.online_uuion,
		player_queue = _self.player_queue, 
		is_visitor = _self.is_visitor,

	}

	if _self.machine_status == MACHINE_STATUS.ON_SEAT then 
	-- 更新用户数据到缓存中,供在此登陆和机器sever查询
		if _time_out  then 
			online_union_help.update_online_redis(_self.machine_online_key, cjson.encode( _data ), 
				_time_out)
		end 
	else
		online_union_help.update_online_redis(_self.machine_online_key, cjson.encode( _data ), 
			_time_out and  _time_out or PLAYER_TIME_OUT) 
	end
 	-- 每台机器需要将自己的信息发布游戏机的状态系统中 
	local machine_inf = {
		process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,
		sub_type = PROCESS_SUB_TYPE.MACHINE_STATUS,
		machine_room_code = _self.machine_room_code,
		machine_status = _self.machine_status,
		user_code = _self.user_code,
		player_queue = _self.player_queue, 
		stream_addr = _self.stream_addr,
		stream_slave_addr = _self.stream_slave_addr,
		update_time = os.time(),
	}
	 
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 

    local jsonstr = cjson.encode(machine_inf)
    local res, err = redis_cli:hset(_self.machine_status_key,_self.machine_room_code..":".._self.machine_code,jsonstr)
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_slot_m2u redis_cli:publish err: ",err) 
    	return nil end 


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
	_process.code = 200  
	-- HEARTBEAT_S2C = 0x02, -- 系统心跳包协议,服务器根据客户端类型,返回实际信息
	-- -- {process_type=PROCESS_TYPE.HEARTBEAT_S2C,  user_code="xxx" | machine_code="xxxx"
	-- --	balance=xx, nomove_balance=xx, integral=xx, player_status=xxx,room_code="xxx",
	-- --	machine_status=xx,用户在房间时返回该数据 
	-- --} 
	_process.process_type = PROCESS_TYPE.HEARTBEAT_S2C
  
	_self.machine_on_liquidation = _process.machine_on_liquidation
	_self.machine_rewardsing =  _process.machine_rewardsing

	_process.data = { 
		machine_code 	= _self.machine_code,
		user_code 		= _self.user_code,
  		machine_status 	= _self.machine_status,
		online_uuion 	= _self.online_uuion,
	}
	-- if _process.machine_status then
	-- 	_self.machine_status = _process.machine_status
	-- end
	-- 将当前用户的信息返回给所有用户 
	_self.ws:sendMsg(cjson.encode(_process))	

	_self:update_online_status()

	-- ngx.log(ngx.ERR," machine_code: ",_self.machine_code ,"heart beat is ",_self.machine_status)

    -- redis_cli:publish(ZS_ROOM_MSG_PRE_STR.._self.machine_room_code,jsonstr)

 	return true  

end
 


--[[
-- on_ask_for_machine_u2m  响应用户客户端发布的请求机器协议
-- example 
	ASK_FOR_MATHINE_U2M = 0x07 , 	-- 用户请求空闲机器 指令请求
		-- {process_type=PROCESS_TYPE.ASK_FOR_MATHINE_U2M,user_code="xxx",machine_code="xxxx"} 
 
-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_ask_for_machine_u2m = function (_self, _process )
	-- body
	-- 1, 基础判断,参数和属性是否正确  
	local redis_cli = _self.redis_cli_1
    
    local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code  
	-- 2, 判断机器当前状态,当前状态为空闲状态,进行游戏
	if  MACHINE_STATUS.MACHINE_ERROR ==_self.machine_status or 
		MACHINE_STATUS.STATUS_ERROR ==_self.machine_status then
		-- redis订阅,通过订阅通知游戏客户端 系统返回情况
		_process.process_type = PROCESS_TYPE.ASK_FOR_MATHINE_M2U
		_process.msg = "系统异常,请稍后再试" 
		_process.code = MACHINE_ERR_CODE.STATUS_ERROR
	    local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
	    if not res then 
	    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_ask_for_machine_u2m redis_cli:publish err: ",err) 
	    	return nil end  

	elseif _self.machine_status == MACHINE_STATUS.ON_QUEUE then
		if _process.user_code ~=  _self.queue_player_code then
			return nil 
		end 
	end

	local res = online_union_help.set_online_redis(ZS_USER_MACHINE_ASKING_PRE.._self.machine_code, _process.user_code,10)
	if not res or res == 0  then 
		-- 客户端机器将进行二次判断 将数据返回服务器
		_process.process_type = PROCESS_TYPE.ASK_FOR_MATHINE_M2U
		_process.msg = "机器已经被使用,请稍后再试" 
		_process.code = MACHINE_ERR_CODE.MACHINE_ON_USING
	    local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
	    if not res then 
	    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_ask_for_machine_u2m redis_cli:publish err: ",err) 
	    	return nil end  
   	else 
		_self.ws:sendMsg(cjson.encode(_process))
	 	_self.machine_status = MACHINE_STATUS.ON_ASKING	 
	 	-- 需要加定时器处理!!! 

	end  
	 
	_self.is_visitor = _process.is_visitor

	return true
end

--[[
-- on_ask_for_machine_m2u  响应用户客户端发布的请求机器协议
-- example 
	ASK_FOR_MATHINE_M2U = 0x08,		-- 机器回复客户端 请求返回 成功或者失败
		-- {process_type=PROCESS_TYPE.ASK_FOR_MATHINE_M2U,user_code="xxx",machine_code="xxxx",code=200,msg="xxx"} code 200 表示成功 非200 表示失败
	  
-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_ask_for_machine_m2u = function (_self, _process ) 
	-- 1, 基础判断,参数和属性是否正确 
	if not _process.machine_code then 
		ngx.log(ngx.ERR,"machine ",_self.machine_code," on_ask_for_machine_m2u _process.user_code: ",_process.user_code," ,_process.machine_code: ",_process.machine_code) 
		_process.code =  MACHINE_ERR_CODE.PARAM_ERROR
		_process.msg = "机器编号为空或发送者与机器不匹配!" 
		_self.ws:sendMsg(cjson.encode(_process))  
		return nil end
 	  
    online_union_help.delete_online_redis(ZS_USER_MACHINE_ASKING_PRE.._self.machine_code)
 
	-- redis订阅,通过订阅通知游戏客户端 系统返回情况
	local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code
	
	local redis_cli = _self.redis_cli_1 
    local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_ask_for_machine_m2u redis_cli:publish err: ",err) 

    	_process.code =  MACHINE_ERR_CODE.ON_SEND_ERROR
		_process.msg = "发送用户失败,请稍后再试!" 
		_self.ws:sendMsg(cjson.encode(_process))  

    	return nil end

    -- 广播通知房间群 用户
 	if _process.code == 200 then
		_self.user_code = _process.user_code
		_self.machine_status = MACHINE_STATUS.ON_GAME  

	 	local _new_process = { 
				process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,
				sub_type = PROCESS_SUB_TYPE.MACHINE_STATUS,

				data = {
					machine_code = _self.machine_code,
					user_code = _process.user_code,
					machine_room_code = _self.machine_room_code,
					machine_status = _self.machine_status,
				},
	 	}
	 	redis_cli:publish(_self.room_channel_name, cjson.encode(_new_process))

	 	_self:update_online_status()

	 else
	 	_self:machine_queue_opt(redis_cli)
	end

	return true
end
  

--[[
-- on_slot_u2m  用户投币,用户投币的操作在机器端进行数据库操作

-- 用户投币开始,系统进行先进行扣费,然后写下流水记录,当前系统投币成功,机器通知服务器,服务器将之前的记录修改为成功,完成本次记录
--	当系统没有回复消息或者回复投币失败,系统需要将该条信息进行还原操作,将用户的账户金额还原回去
--	每天进行批处理处理一次投币失败记录操作!!!!!!
-- example 
	SLOT_U2M = 0x09,	-- 用户客户端投币 一期默认为投币一枚 ,扣除的游戏币和获得,由系统进行定义,默认配置为1:1
		-- {process_type=PROCESS_TYPE.SLOT_U2M,user_code="xxx",machine_code="xxxx",coins=1} 

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_slot_u2m = function (_self, _process )
	-- body 
	local redis_cli = _self.redis_cli_1 
	if _process.user_code ~= _self.user_code or not _self.user_code then
		ngx.log(ngx.ERR,"machine ", _self.user_code, " on_slot_u2m ,_process.machine_code: ", _process.user_code ) 
		return nil 
	end

	local _machine_bet_record = {
			machine_code = _self.machine_code,
			user_code = _self.user_code,
			bet_money = 1* _self.machine_cost_ratio, 
	} 
	 

	-- db opt------------- 非游客
	if  _self.is_visitor == 0 then 

		local res,err,bet_flow_code = machine_bet_records.add_machine_bet_record(_machine_bet_record) 
		if res then
			ngx.log(ngx.ERR,"++++++++++++++++++++++++++bet_flow_code ",bet_flow_code,"  ",cjson.encode(res))
		end
		if not res or not bet_flow_code then   
		    _process.code = MACHINE_ERR_CODE.FAILED
		    _process.process_type = PROCESS_TYPE.SLOT_M2U
		    _process.msg = "投币失败"
		    -- redis订阅,通过订阅通知游戏客户端 系统返回情况
			local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._self.user_code 
			local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
	    	if not res then 
	    		ngx.log(ngx.ERR,"machine ",_self.machine_code," on_ask_for_disconnect_m2u redis_cli:publish err: ",err) 
	    	return nil end 

			return true 
		end 
		_process.bet_flow_code = bet_flow_code
	else
		_process.bet_flow_code = uuid_help:get64()

	end
	_process.balance = _machine_bet_record.bet_money 
	
  
	-- 客户端机器将进行二次判断 将数据返回服务器
	_self.ws:sendMsg(cjson.encode(_process))	
	
	return true
end


--[[
-- on_slot_m2u 投币成功的反馈
-- example 
	SLOT_M2U = 0x06,	-- 投币成功返回客户端
	-- {process_type=PROCESS_TYPE.SLOT_M2U,user_code="xxx",machine_code="xxxx",coins=1}

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
MACHINE_BET_RECORDS_NO_COMPELETE_LIST_KEY = machine_bet_records.MACHINE_BET_RECORDS_NO_COMPELETE_LIST_KEY
MACHINE_BET_RECORDS_CENCEL_LIST_KEY = machine_bet_records.MACHINE_BET_RECORDS_CENCEL_LIST_KEY
MACHINE_BET_REWARDS_ADD_ERROR_LIST_KEY = machine_bet_records.MACHINE_BET_REWARDS_ADD_ERROR_LIST_KEY

_M.on_slot_m2u = function (_self, _process )
	-- body
	-- 1, 基础判断,参数和属性是否正确 
	if not _process.user_code or _process.user_code ~= _self.user_code or  not _process.bet_flow_code then 
		ngx.log(ngx.ERR,"machine ",_self.machine_code," on_slot_m2u _process.user_code: ",_process.user_code) 

		_process.code =  MACHINE_ERR_CODE.PARAM_ERROR
		_process.msg = "参数不正确" 
		_self.ws:sendMsg(cjson.encode(_process)) 
		return nil end

	-- redis订阅,通过订阅通知游戏客户端 系统返回情况
	local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code  

	-- 返回数据由机器端写入数据库,不放入用户端写入数据库,因为
	-- 用户断开链接,无法再次写入,机器的稳定性远比用户端稳定 
 
	-- db opt-------------
	if not _self.is_visitor then
		if _process.code == 200 then  
			machine_bet_records.complete_machine_bet_record(_process.bet_flow_code)  
		else
			-- 执行投币错误,执行取消操作
			local res = machine_bet_records.cancel_machine_bet_record(_process.user_code,_process.bet_flow_code)
			if not res then
				local cancel_data = {
					bet_flow_code = _process.bet_flow_code,
					user_code = _process.user_code
				}
				redis_queue_help.push_redis_queue(MACHINE_BET_RECORDS_CENCEL_LIST_KEY,cjson.encode(cancel_data)) 
			end
		end
	end

	-- db opt-------------
	_process.balance = 1* _self.machine_cost_ratio
	local redis_cli = _self.redis_cli_1 
    local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_slot_m2u redis_cli:publish err: ",err) 
    	return nil end 

	return true
end

  
--[[
-- on_rewards_m2u  机器投币获奖通知用户
-- example 
	MACHINE_REWARDS_M2U = 0x07,	-- 机器通知服务器中奖 
		-- {process_type=PROCESS_TYPE.MACHINE_REWARDS_M2U,user_code="xxx",machine_code="xxxx",coins=xxx }

-- @param _self 当前用户对象
-- @param _process 协议结构表  
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_rewards_m2u = function (_self, _process )
	-- body
	-- 1, 基础判断,参数和属性是否正确 
	if not _process.user_code then 
		ngx.log(ngx.ERR,"machine ",_self.machine_code," on_rewards_m2u _process.user_code: ",_process.user_code) 
		_process.code =  MACHINE_ERR_CODE.PARAM_ERROR
		_process.msg = "参数不正确" 
		_self.ws:sendMsg(cjson.encode(_process)) 
		return nil end
  
  	-- 返回数据由机器端写入数据库,不放入用户端写入数据库,因为
	-- 用户断开链接,无法再次写入,机器的稳定性远比用户端稳定
  
 	-- db opt------------- 
	local _machine_bet_record = {
		machine_code = _self.machine_code,
		user_code = _process.user_code,
		bet_rewards = _process.coins * _self.machine_rewards_ratio, 
	}

	_self.machine_rewardsing = _process.machine_rewardsing 

	_process.integral = _machine_bet_record.bet_rewards
	if  _self.is_visitor == 0 then
		local res = machine_bet_records.add_machine_bet_record(_machine_bet_record)
		if not res then 
			-- 没有添加成功,写入缓存等待后续写入 
			redis_queue_help.push_redis_queue(MACHINE_BET_REWARDS_ADD_ERROR_LIST_KEY,cjson.encode(_machine_bet_record))
		end
 	end

	-- db opt------------- 
	-- redis订阅,通过订阅通知游戏客户端 系统返回情况
	local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code  

	local redis_cli = _self.redis_cli_1 
    local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_rewards_m2u redis_cli:publish err: ",err) 
    	return nil end 

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
	-- body 
 
	-- 1, 基础判断,参数和属性是否正确 
	if not _process.user_code or not _process.machine_code then 
		ngx.log(ngx.ERR,"player ",_self.user_code," on_ask_for_disconnect_u2m _process.user_code: ",_process.user_code," ,_process.machine_code: ",_process.machine_code) 
		return nil end 
	-- 客户端机器将进行二次判断 将数据返回服务器

	_self.ws:sendMsg(cjson.encode(_process)) 

	return true
end


--[[
-- on_ask_for_machine_m2u  响应用户客户端发布的请求机器协议
-- example 
	ASK_FOR_DISCONNECT_M2U = 0x04,	-- 主动退出返回数据,返回状态可能包括断开成功,也有结算中
									-- 结算中,系统将流出10秒左右的结算时间,之后再开始进行开发给其他用户
		-- {process_type=PROCESS_TYPE.ASK_FOR_DISCONNECT_M2U,user_code="xxx",machine_code="xxxx",machine_status=0x04,code=200} 

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_ask_for_disconnect_m2u = function (_self, _process )
	-- body
	-- 1, 基础判断,参数和属性是否正确 
	if not _process.user_code then 
		ngx.log(ngx.ERR,"machine ",_self.machine_code," on_ask_for_disconnect_m2u _process.user_code: ",_process.user_code," ,_process.machine_code: ",_process.machine_code) 
		return nil end
  

  	_self.user_code = nil
	-- redis订阅,通过订阅通知游戏客户端 系统返回情况
	local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code  

	local redis_cli = _self.redis_cli_1

	_self.machine_status = _process.machine_status 
    if _process.code == 200 then    
	   	_self:machine_queue_opt(redis_cli) 
	end 
	

    local res, err = redis_cli:publish(channel_name, cjson.encode(_process))  
 	local _new_process = { 
			process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,
			sub_type = PROCESS_SUB_TYPE.MACHINE_STATUS,
			data = {
				user_code = _self.user_code,
				machine_status = _self.machine_status,
				machine_rewardsing = _self.machine_rewardsing,		-- 正在数币 
				machine_on_liquidation = _self.machine_on_liquidation,	-- 清算状态
				machine_code = _self.machine_code, 
				machine_room_code = _self.machine_room_code ,
				player_queue = _self.player_queue,
			},
 	} 
 	_self:update_online_status()

 	redis_cli:publish( _self.room_channel_name , cjson.encode(_new_process))  
	return true
end

--[[
-- on_machine_error_m2u  机器故障 主动上传
-- example 
	MACHINE_ERROR_M2S = 0x0f,	-- 机器上报故障记录时, 操作过程同MACHINE_ERROR_S2M
		-- {process_type=PROCESS_TYPE.MACHINE_ERROR_M2S, user_code="xxx", machine_code="xxxx" } 
-- @param _self 当前用户对象
-- @param _process 协议结构表  
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_machine_error_m2u = function (_self, _process )
	-- body
	-- 1, 基础判断,参数和属性是否正确  
	if _process.machine_status then
		_self.machine_status = _process.machine_status
    end
 	_self.user_code = nil
	-- redis订阅,通过订阅通知游戏客户端 系统返回情况
	local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code  
   
	local redis_cli = _self.redis_cli_1

    _process.machine_code = _self.machine_code 
    local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_machine_error_m2u redis_cli:publish err: ",err) 
    	return nil end 

	local _new_process = { 
		process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,
		sub_type = PROCESS_SUB_TYPE.MACHINE_STATUS,
		data = {
			user_code = _self.user_code,
			machine_status = _self.machine_status,
			machine_rewardsing = _self.machine_rewardsing,		-- 正在数币 
			machine_on_liquidation = _self.machine_on_liquidation,	-- 清算状态
			machine_code = _self.machine_code, 
			machine_room_code = _self.machine_room_code ,
			player_queue = _self.player_queue,
		},
	}  
    local res, err = redis_cli:publish(_self.room_channel_name, cjson.encode(_new_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_machine_error_m2u redis_cli:publish err: ",err) 
    	return nil end 

	return true
end



--[[
-- on_queue_up_u2s  机器收到排队请求
-- example 
	QUEUE_UP_U2S = 0x10,		-- 用户排队请求,排队主要针对于机器排队管理,客户端需要做如下处理,随机排队,
								-- 客户端本地查询合适的机器进行界面切换和排队请求
		 返回 {process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,sub_type = PROCESS_SUB_TYPE.QUEUE_OK, data = {machine_code=xxx,front_players=1,player_queue={}},  user_code="xxx", machine_code="xxxx"} 

-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_queue_up_u2s = function (_self, _process)
	if not _self.player_queue then 
		_self.player_queue = {}
	end 

	-- redis订阅,通过订阅通知游戏客户端 系统返回情况 
	local redis_cli = _self.redis_cli_1 
	local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code  
	-- 通知用户-----
	_process.process_type = PROCESS_TYPE.QUEUE_UP_S2U
	_process.code = 200

	table.insert(_self.player_queue,_process.user_code) 
	
   
	local res, err = redis_cli:publish( channel_name, cjson.encode(_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_queue_up_u2s redis_cli:publish err: ",err) 
    	return nil end 
 	
	local _queue_process = {
			process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,
			sub_type = PROCESS_SUB_TYPE.MACHINE_STATUS,
			
			data = {  
				user_code = _process.user_code,
				machine_room_code = _self.machine_room_code,
				machine_code = _self.machine_code, 
				front_players = #_self.player_queue,
				machine_status = _self.machine_status,
			}
	}  

	
	_queue_process.data.player_queue = _self.player_queue
 

    local res, err = redis_cli:publish(_self.room_channel_name, cjson.encode(_queue_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_queue_up_u2s redis_cli:publish err: ",err) 
    	return nil end 

    
	return true
end



--[[
-- on_queue_cancel_u2s  机器收到排队取消请求
-- example 
		QUEUE_CANCEL_U2S = 0x12,	--[[ 用户取消排队请求 操作流程与排队
		-- {process_type=PROCESS_TYPE.QUEUE_CANCEL_U2S, user_code="xxx",machine_code="xxxx"}  
		]]
-- @param _self 当前用户对象
-- @param _process 协议结构表 
-- @return nil 表示失败 true 表示成功 
--]]
_M.on_queue_cancel_u2s = function (_self, _process)
	if not _self.player_queue then 
		_self.player_queue = {}
	end
	if res ~= 0 then
    	for i=1,#_self.player_queue do 
    		if _self.player_queue[i] == _process.user_code then
    			table.remove(_self.player_queue,i)  
    		end
    	end 
    else
    	return nil
	end

	_process.process_type = PROCESS_TYPE.QUEUE_CANCEL_S2U
	_process.code = 200

	local redis_cli = _self.redis_cli_1 
	local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code  
	local res, err = redis_cli:publish( channel_name, cjson.encode(_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_queue_up_u2s redis_cli:publish err: ",err) 
    	return nil end 



local _queue_process = {
			process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,
			sub_type = PROCESS_SUB_TYPE.MACHINE_STATUS,
			
			data = { 
				user_code = _process.user_code,
				machine_room_code = _self.machine_room_code,
				machine_code = _self.machine_code, 
				front_players 	= #_self.player_queue,
				machine_status = _self.machine_status,
			}
	}  

	 
	_queue_process.data.player_queue = _self.player_queue 

	-- redis订阅,通过订阅通知游戏客户端 系统返回情况
	local channel_name = ZS_ROOM_MSG_PRE_STR.._self.machine_room_code
	local redis_cli =  _self.redis_cli_1

   local res, err = redis_cli:publish(_self.room_channel_name, cjson.encode(_queue_process))
   if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_queue_up_u2s redis_cli:publish err: ",err) 
    	return nil end  
      
    

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
	_self.queue_player_code = nil 
	local redis_cli = _self.redis_cli_1 
	_self:machine_queue_opt(redis_cli)


	local _queue_process = {
				process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,
				sub_type = PROCESS_SUB_TYPE.MACHINE_STATUS,
				
				data = { 
					user_code = _process.user_code,
					machine_room_code = _self.machine_room_code,
					machine_code = _self.machine_code, 
					front_players 	= #_self.player_queue,
					machine_status = _self.machine_status,
				}
		}  

	 
	_queue_process.data.player_queue = _self.player_queue 

	-- redis订阅,通过订阅通知游戏客户端 系统返回情况
	local channel_name = ZS_ROOM_MSG_PRE_STR.._self.machine_room_code
	local redis_cli =  _self.redis_cli_1

   local res, err = redis_cli:publish(_self.room_channel_name, cjson.encode(_queue_process))
   if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_queue_up_u2s redis_cli:publish err: ",err) 
    	return nil end  
       

	return true
end
 

--[[
-- on_ask_for_yugua_u2m  响应用户客户端发布的请求机器协议
-- example 
	MACHINE_YUGUA_U2M = 0x13, -- 雨刮器控制协议
	-- {process_type=PROCESS_TYPE.MACHINE_YUGUA_U2M,user_code="xxx",machine_code="xxxx"} 

-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_ask_for_yugua_u2m = function (_self, _process )
	-- body   
	_self.ws:sendMsg(cjson.encode(_process))	

end
  
--[[
-- on_player_break_us2ms  响应用户客户端发起的请求机器协议
-- example 
 -- 专用指令 用户断线,再次登录时,将会通知读取之前的数据信息,如果为空,则直接返回 
	PLAYER_BREAK_US2MS = 0x17,	-- 用户断开,主要用于正在玩的用户玩家,通知通知游戏服务器进行状态管理,当超时未连接进来,通知机器端用户退出
		-- {process_type=PROCESS_TYPE.PLAYER_BREAK_US2MS,user_code="xxx",machine_code="xxxx"} 

-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_player_break_us2ms = function(_self,_process)
	ngx.log(ngx.ERR,"user_break +++++++++",cjson.encode(_process)) 

 	_self.ws:sendMsg(cjson.encode(_process))  
 	return true
end
 
--[[
-- on_client_offline_s2u  异地登录, 下线通知
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
 	 _self.ws:exit(200)
    return true
end

 --[[
-- machine_break  机器断开,ws端手动调用故障
-- example 
	 发送系统通知, 通知房间用户状态变化
 
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.machine_break = function(_self) 
 	 
 	_self.machine_status = MACHINE_STATUS.MACHINE_OFFLINE


	local machine_inf = {
		process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,
		sub_type = PROCESS_SUB_TYPE.MACHINE_STATUS,
		machine_room_code = _self.machine_room_code,
		machine_status = _self.machine_status,
		user_code = _self.user_code,
		player_queue = _self.player_queue, 
		stream_addr = _self.stream_addr,
		update_time = os.time(),
	}	 

 	_self:update_online_status()
	-- 在机器房间 通知机器退出
	local channel_name = _self.room_channel_name
	local _process = {process_type=PROCESS_TYPE.MACHINE_BREAK_MS2US,
			user_code=_self.user_code,
			machine_code=_self.machine_code} 
	

	--------------------------------db opt-------------------------------- 
	local redis_cli = redis_help:new();
    if not redis_cli then
        ngx.log(ngx.ERR,ZS_ERROR_CODE.REDIS_CRE_CLI_ERROR);
        return nil
    end 

    local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
    if not res then 
    	ngx.log(ngx.ERR,"machine ",_self.machine_code," on_machine_pullpoints_m2u redis_cli:publish err: ",err) 
    	return nil end  

	_self.ws:exit(200)
	return true

end


 --[[
-- on_machine_notice_m2s  机器结算之后,主动发送该事件, 激活ws端手动调用
-- example 
	MACHINE_NOTICE_M2S = 0x1b, -- 机器主动上传 当前需要进行排队列操作
	-- {process_type=PROCESS_TYPE.MACHINE_NOTICE_M2S, machine_code="xxxx" } 
 
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_machine_notice_m2s = function(_self, _process) 	
-- 自动走排队业务处理
	local redis_cli = _self.redis_cli_1 
	_self.machine_status = _process.machine_status
	_self:machine_queue_opt(redis_cli)
	return true

end




--[[
-- on_seat_u2m  留座
-- example  
	SEAT_U2M = 0x1f, -- 留座请求发起, 用户发起的占座请求 用户端发起不需要携带用户编号字段 user_code
					-- {process_type = PROCESS_TYPE.SEAT_U2M, user_code='xxxx', minutes=2 }
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_seat_u2m = function (_self, _process ) 
  	-- 用户状态不在游戏中,不可以进行留座操作
  	
 	if _self.user_code ~= _process.user_code  or
 	  _process.machine_code ~=  _self.machine_code  then 
 	  	local redis_cli = _self.redis_cli_1 
		local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code
		_process.process_type = PROCESS_TYPE.SEAT_M2U
		local res,err = redis_cli:publish(channel_name, cjson.encode(_process)) 
		ngx.log(ngx.ERR,"------on_seat_u2m eror ")
 		return nil
 	end
 
 	_self.ws:sendMsg(cjson.encode(_process)) 

	return true
	  
end


--[[
-- on_seat_m2u  留座机器返回结果
-- example  
	SEAT_M2U = 0x20, -- 留座成功返回, 
	-- {process_type=PROCESS_TYPE.SEAT_M2U, user_code='xxxx', minutes=2 }
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_seat_m2u = function (_self, _process ) 
  	-- 用户状态不在游戏中,不可以进行留座操作
  	-- 如果定时器
  	if  _process.code ==  200 then 
		-- 直接扣费

		local _machine_bet_record = {
			machine_code = _self.machine_code,
			user_code = _self.user_code,
			bet_money = tonumber(_process.minutes)*10, 
		} 
	  
		local res,err,bet_flow_code = machine_bet_records.add_machine_seat_record(_machine_bet_record) 
		if res then
			ngx.log(ngx.ERR,"++++++++++++++++++++++++++bet_flow_code ",bet_flow_code,"  ",cjson.encode(res))
		end

		if not res or not bet_flow_code then   
		    _process.code = MACHINE_ERR_CODE.FAILED 
		    _process.msg = "留座失败"
		    -- redis订阅,通过订阅通知游戏客户端 系统返回情况
			local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code 
			local res, err = redis_cli:publish(channel_name, cjson.encode(_process))
	    	if not res then 
	    		ngx.log(ngx.ERR,"machine ",_self.machine_code," on_seat_m2u redis_cli:publish err: ",err) 
	    	return nil end 

			return true 
		end 
		_process.bet_flow_code = bet_flow_code 
		_process.balance = _machine_bet_record.bet_money

  	end 
 
	local redis_cli = _self.redis_cli_1 
	local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code
	local res,err = redis_cli:publish(channel_name, cjson.encode(_process)) 


	return true
	  
end


--[[
-- on_seat_cancel_u2m  留座机器返回结果
-- example  
	SEAT_CANCEL_U2M = 0x21,
	-- {process_type=PROCESS_TYPE.SEAT_CANCEL_U2M,user_code='xxxx' }
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_seat_cancel_u2m = function (_self, _process ) 
  	-- 用户状态不在游戏中,不可以进行留座操作
  	if  _self.user_code ~= _process.user_code  or
 	  _process.machine_code ~=  _self.machine_code  then 
 	  	local redis_cli = _self.redis_cli_1 
		local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code
		local res,err = redis_cli:publish(channel_name, cjson.encode(_process)) 

 		return nil
 	end
 
 	_self.ws:sendMsg(cjson.encode(_process)) 
	return true
	  
end



--[[
-- on_seat_cancel_m2u  留座机器返回结果
-- example  
		SEAT_CANCEL_M2U = 0x22,
		-- {process_type=PROCESS_TYPE.SEAT_CANCEL_M2U,user_code='xxxx' }
-- @param _self 当前用户对象
-- @param _process 协议结构表  
--]]
_M.on_seat_cancel_m2u = function (_self, _process ) 
  	-- 用户状态不在游戏中,不可以进行留座操作 
	local redis_cli = _self.redis_cli_1 
	local channel_name = ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._process.user_code
	local res,err = redis_cli:publish(channel_name, cjson.encode(_process))  
 
	return true 
end
  




--[[
-- machine_queue_opt 机器重连
-- example 
 
-- @param _machine_code 机器编号
-- @param _machine_token 机器有效token
--]]
_M.machine_queue_opt = function(_self,_redis_cli)

	while true do
		if #_self.player_queue == 0 then
			_self.machine_status = MACHINE_STATUS.ON_IDLE
			_self:update_online_status()
			-- 每台机器需要将自己的信息发布游戏机的状态系统中 
			local _process = {
				process_type = PROCESS_TYPE.MACHINE_NOTICE_S2U,
				sub_type = PROCESS_SUB_TYPE.MACHINE_STATUS,
				data = {
					machine_code = _self.machine_code,
					machine_room_code = _self.machine_room_code,
					machine_status = _self.machine_status,
				} 
			}
			_redis_cli:publish(_self.room_channel_name, cjson.encode(_process))

			return 
		end 

		_self.machine_status = MACHINE_STATUS.ON_QUEUE
		-- 自动走排队业务处理
		local _user_code = _self.player_queue[1]
		local _queue_process = {
			process_type = PROCESS_TYPE.QUEUE_ON_S2U, 
			code = 200,
			user_code = _user_code,
			room_code = _self.machine_room_code,
			machine_code = _self.machine_code,
		}  

		table.remove(_self.player_queue,1)
		local res,err = _redis_cli:publish(ZS_COIN_MACHINE_SUBSCRIPT_PRE_STR.._user_code , cjson.encode(_queue_process)) 
		if not res then
			ngx.log(ngx.ERR, "-----33--- error",_user_code ) 
			ngx.sleep(1)
		elseif res == 0 then
			-- 用户不在线 直接进行下一个用户
			ngx.log(ngx.ERR, "-----44--- error",_user_code )
		else
			-- 发送成功 等待用户反馈,开启定时器 
			-- 如果当前机器为 

			 -- 开启定时器判断请求,如果超时5秒则认为断开连接 发起断开请求 
		    local timer = timer_help:new(_self.queue_timer_func, _self, {user_code = _user_code })

		    -- 定时器开启超时操作, 定时器超时3秒,如果还未到达,则自动通知用户,并且将上次消息设置为丢失状态
		    timer:timer_at(20)

			_self.queue_player_code = _user_code 
			return 
		end 
		ngx.sleep(0.1)
	end

end


-- -----------需要优化!!!!!

_M.queue_timer_func = function(_self, _process)
	-- body
	ngx.log(ngx.ERR,"---queue_timer_func -------1111  ")
 	if _self.machine_status == MACHINE_STATUS.ON_QUEUE and _self.queue_player_code == _process.user_code then
	 	 	-- 说明用户 未同意,执行下一个用户
	 	ngx.log(ngx.ERR,"---queue_timer_func ------2222  ")
 	    -- 开启定时器判断请求,如果超时5秒则认为断开连接 发起断开请求 
	    local timer = timer_help:new(_self.queue_timer_func, _self, {user_code = _process.user_code })

	 	local lock, err = resty_lock:new("ngx_locks")

	    if not lock then
	        ngx.log(ngx.ERR,"failed to create lock: ", err)
	        -- 消息未执行 如何处理???  
		    -- 定时器开启超时操作, 定时器超时3秒,如果还未到达,则自动通知用户,并且将上次消息设置为丢失状态 
	    else 
	    	local elapsed, err = lock:lock(_self.online_uuion)  
			local redis_cli = redis_help:new();
		    if redis_cli then  
		    	_self:machine_queue_opt(redis_cli)   
		    	lock:unlock()
		    	return 
		    end  
	       local ok, err = lock:unlock()
	       if not ok then
	           ngx.log(ngx.ERR,"failed to unlock: ", err)
	       end  
		end 

	 	timer:timer_at(3) 
 	end
end



-- --[[
-- -- dispatch_process 机器 系统网络消息通信解析功能函数 
-- -- example 
 	
-- -- @param _process_str 消息字符串,系统进行一次 转换为lua系统数据结构进行处理
-- --]]
-- _M.server_heart_timer_cb = function(_timeself,_self  )
-- 	-- body 
-- 	local _process = {
-- 		process_type 	=PROCESS_TYPE.HEARTBEAT_S2C,  
-- 		balance 		=_self.balance,
-- 		nomove_balance 	=_self.nomove_balance,
-- 		integral		=_self.integral,
-- 		player_status 	= _self.player_status,
-- 		room_code 		= _self.room_code, 
-- 	} 
-- 	local res = _self.ws:sendMsg(cjson.encode(_process))
  
-- 	local ok, err = ngx.timer.at(3, _self.server_heart_timer_cb,_self)
-- 	if not ok then
-- 	    ngx.log(ngx.ERR, "failed to create the timer: ", err)
-- 	end  
-- end



--[[
-- dispatch_process 机器 系统网络消息通信解析功能函数 
-- example 
 	
-- @param _process_str 消息字符串,系统进行一次 转换为lua系统数据结构进行处理
--]]
_M.dispatch_process = function (_self, _process )
	-- body 
	if not _process then return nil end
	if _process.process_type ~= 0x01 then
       ngx.log(ngx.ERR,string.format("--machine -- %s, function:%s , proecss:%s",_self.machine_code,PROCESS_FUNC_MAP[_process.process_type],cjson.encode(_process)))
    end  

 	if not _process.msgid then
		_process.msgid = uuid_help:get64()  
	end

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
	-- ngx.log(ngx.ERR,"  machine dispatch_process  ",cjson.encode(_process)," ",res)
	-- local ok,res = pcall( _self[PROCESS_FUNC_MAP[_process.process_type]],_self,_process) 

	
end

 

return _M

