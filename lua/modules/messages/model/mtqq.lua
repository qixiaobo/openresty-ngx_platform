--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:mtqq.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  lua mtqq,服务器相关应用



--]]

--[[
消息体的设计简说
bit		7	6	5	4	3			2	1		0
byte 1	Message Type	DUP flag	QoS level	RETAIN
byte 2	Remaining Length
第一个byte 用于说明消息体的信息.

第二个byte 用于传输我们需要传输的数据. 

"MQTT_CONNECT = 1,--请求连接  
"MQTT_CONNACK = 2,--请求应答  
"MQTT_PUBLISH = 3,--发布消息  
"MQTT_PUBACK = 4,--发布应答  
"MQTT_PUBREC = 5,--发布已接收，保证传递1  
"MQTT_PUBREL = 6,--发布释放，保证传递2  
"MQTT_PUBCOMP = 7,--发布完成，保证传递3  
"MQTT_SUBSCRIBE = 8,--订阅请求  
"MQTT_SUBACK = 9,--订阅应答  
"MQTT_UNSUBSCRIBE = 10,--取消订阅  
"MQTT_UNSUBACK = 11,--取消订阅应答  
"MQTT_PINGREQ = 12,--ping请求  
"MQTT_PINGRESP = 13,--ping响应  
"MQTT_DISCONNECT = 14--断开连接  

]]

local bit_help  =  require "common.bit_help"

-- mtqq 消息类型
local MTQQ_TYPE = {
	MQTT_CONNECT  =  1,--请求连接  
	MQTT_CONNACK = 2,--请求应答  
	MQTT_PUBLISH = 3,--发布消息  
	MQTT_PUBACK = 4,--发布应答  
	MQTT_PUBREC = 5,--发布已接收，保证传递1  
	MQTT_PUBREL = 6,--发布释放，保证传递2  
	MQTT_PUBCOMP = 7,--发布完成，保证传递3  
	MQTT_SUBSCRIBE = 8,--订阅请求  
	MQTT_SUBACK = 9,--订阅应答  
	MQTT_UNSUBSCRIBE = 10,--取消订阅  
	MQTT_UNSUBACK = 11,--取消订阅应答  
	MQTT_PINGREQ = 12,--ping请求  
	MQTT_PINGRESP = 13,--ping响应  
	MQTT_DISCONNECT = 14--断开连接  
}

 -- 其是用来在保证消息传输可靠的，如果设置为1，
 -- 则在下面的变长头部里多加MessageId,并需要回复确认，
 -- 保证消息传输完成，但不能用于检测消息重复发送。
local MTQQ_DUP_FLAG={
	DUP_FLAG = 0 , -- 用户端不需要回复
	DUP_FLAG = 1 , -- 消息需要回复
}

--[[
主要用于PUBLISH（发布态）消息的，保证消息传递的次数。
00表示最多一次 即<=1
01表示至少一次  即>=1
10表示一次，即==1
11保留后用
]]
local QOS_LEVEL = {
	QOS_MAX_1 = 0,
	QOS_ATLEAST_1 = 1,
	QOS_ONCE = 2,
	QOS_RETAIN = 3,
}

-- 主要用于PUBLISH(发布态)的消息，表示服务器要保留这次推送的信息，
-- 如果有新的订阅者出现，就把这消息推送给它。如果不设那么推送至当前订阅的就释放了
local MTQQ_RETAIN={
	NO_RETAIN = 0,
	RETAIN = 1,
}

local mtqq_header  =  {
	msg_header  =  0,		-- 消息头组成 固定长度
	msg_remaining  =  0,	-- 消息体长度 用来保存接下去的变长头部+消息体的总大小的。
}

local mtqq_protocol_name = {
	MSB_length = 0,
	MSB_length = 6,
	MSG_protocol = 'MQIsdp',
	protocol_version = 3,
}
local connect_flags = {
	user_name_flag = 1, -- 1 bit
	password_flag = 1, -- 1 bit
	will_retain = 0, -- 1 bit
	will_QoS = 01, -- 2 bit
	will_flag = 1, -- 1 bit
	clean_session = 1, -- 1 bit
	retain_bit = 1, --  保留位
}




local _M = {}

_M.







