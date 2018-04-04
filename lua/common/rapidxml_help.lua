--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:xml2lua_help.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  xml 转 lua表 或 lua表 转 xml
--]]

local lub    = require 'lub'
local lut    = require 'lut'
local xml    = require 'xml'

local _M = {

}

_M.__index = _M


--[[
-- 创建生成xml对象,该对象用于对于xml和lua表的转化和xml数据处理
-- ]]
function _M:new(_xml_str)
	-- body
	local rapid_xml =  setmetatable({}, _M);  
	
	if _xml_str then 
		rapid_xml.xml_data = xml.load(_xml_str) 
	end  
	return rapid_xml;
end

--[[
--	save2str 将xmldata 转为xml字符串
-- ]]
function _M:load_str( _xml_str )
	-- body
	self.xml_data = xml.load(_xml_str) 

end

--[[
--	get_key 获得key 字段内容 可能为字符串,也可能为xml对象本身,用户自行进行处理
-- ]]
function _M:get_key( _key_name, _data  )
	-- body
	if not _data then _data = self.xml_data end
 	local ss = xml.find(_data,_key_name)
	if not ss then return nil end 
	if type(ss[1]) == "table" then
		return ss
	end
	return ss[1] 
end 

--[[
--	set_key 设置key数据,key数据为字符串,或者符合xml的lua表结构,字符串不可!!!!! 
-- ]]
function _M:set_key( _key_name,_value, _data  )
	-- body
	if not _data then _data = self.xml_data end
 	local ss = xml.find(_data,_key_name)
	if ss then
		ss[1] = _value 
	else
		local _xml_note = {
			xml=_key_name 
		}
		table.insert(_xml_note,_value)
		table.insert(_data,_xml_note)
	end
  	
end 

--[[
--	save2str 将xmldata 转为xml字符串 
-- ]]
function _M:save2str(  )
	-- body
	if not self.xml_data then return nil end
	return xml.dump(self.xml_data)
end

--[[
--	save2json 将xmldata 转换为json,其中注意属性作为特殊的内嵌元素存在,
	不建议转换为子键存在 
-- ]]
function _M:save2json()
	-- body
	local resT = self:save2lua()
	if not resT then return nil end
	return cjson.encode(resT)
end

--[[
--	save2lua 将xmldata 转为xml字符串 
-- ]]
function _M:lua2xml(resp_data)
	-- body
	 local xml_data = xml.new("xml")
    for key, val in pairs(resp_data) do
        xml_data:append(key)[1] = val
    end
    return xml_data
end 


return _M