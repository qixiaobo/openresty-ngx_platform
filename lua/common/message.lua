--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:message.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  消息结构体对象,定义消息的基础数据结构,消息的回调以及其他操作
--  
--]]



--标题名称,用户账户,账户类型,消息类型,消息内容,消息附件,消息默认署名,消息风格,抄送人,以及发送时间

local _M = {
	title = "",		-- 标题
	target = {},	-- 消息发送人列表
	msgType = 1,		-- 消息发送人的消息类型
	msgData = {},	-- 消息主体
	msgSignature = "",	-- 数名信息
	msgStyle = "",	-- 消息风格
	sendTime = 0,	-- 消息发送时间
	senderCode = "",	-- 发送人编号
	subSenderCode = {}, -- 其他发送人编号
}

--[[
-- 消息类型预定,消息类型暂时默认有默认消息,广播公告消息,群组消息,短信消息,邮件消息,联合消息
-- 用于消息通信时候的不同消息类型调用不同的消息接收和发送处理
-- 
]] 
local MSG_TYPE = {
	MSG_TYPE_BRAODCAST = 1,		-- 广播公告类型
	MSG_TYPE_DEFAULT = 2,		-- 默认消息,类似即时通信中的消息
	MSG_TYPE_GROUP = 3,			-- 群组类型
	MSG_TYPE_MOBILE = 4,		-- 手机短信类型
	MSG_TYPE_EMAIL = 5,			-- 邮件类型
	MSG_TYPE_UNION = 6,			-- 联合消息
}

MSG_TYPE.__index = MSG_TYPE

_M.MSG_TYPE =  MSG_TYPE 

--[[
-- lua原表,一个lua表对象可以设定_ __index 进行设定其指向的表
-- 当设置 
--  local _M = {
		_VERSION_ = "1.0.0.2",
		name = "名字a",
-- 	}
-- _M.__index = _M

	local mImpl = setmetatable({}, _M)
	此时 mImpl.name 为 _M 父表的name 即当表mImpl
	自身空间无法找到name对象时,则遍历查询父类结构中的相关区域
	可以理解为一个对象的 __index 指向一张表 ,通过setmetatable完成一个对象的parent执行
	如一个表 A = {name = "名字a",},表  B = {}
	A表需要可以通过将 __index 属性指向一张表,然后通过setmetatable 功能将 表 B 的类似父对象指针指向被定义了__index的对象
	实现 __index 指向的对象成为B 的父对象,实现当 B 对象 没有属性的时候 查询返回父类对象的属性,以此类推,实现lua程序的继承
	
	所有lua的表都是引用关系!!!!!

--]] 
--[[
-- _M:new() 创建一个默认消息,消息体默认携带时间戳,
	标题名称,用户账户,账户类型,消息类型,消息内容,消息附件,消息默认署名,消息风格,抄送人,以及发送时间 

-- @param file_code 文件唯一编码code
-- @param md5_code 文件md5码
-- @param sha1_code 文件sha1码
--]]
_M.__index = _M




function _M:new()
	local msg = setmetatable({},_M)
	return msg
end


return _M
