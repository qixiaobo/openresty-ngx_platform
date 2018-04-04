--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:sign_help.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  关于签名相关应用帮助类
--]]
local cjson = require "cjson"
local aes = require "common.crypto.aes"
local rsa = require "common.crypto.rsa"

local _M = {}


local sign_compare = function ( v1,v2 ) 
	-- body
    local v1_str = v1[1]
    local v2_str = v2[1]

    local iLen_1 = #v1_str
    local iLen_2 = #v2_str
    local iLenLit = iLen_1 > iLen_2 and iLen_2 or iLen_1
    local _char_index = 1


    while _char_index < iLenLit do
        if string.sub(v1_str,_char_index,_char_index) < string.sub(v2_str,_char_index,_char_index) then 
            return true
        elseif string.sub(v1_str,_char_index,_char_index) > string.sub(v2_str,_char_index,_char_index) then 
            return false
        else
            _char_index = _char_index + 1
        end 
    end 

    if iLen_1 < iLen_2 then  
        return true
    else 
        return false
    end
end

--[[
make_sign_str_sort 创建等待加密的字符串,按照支付宝的规则进行ascii码排序
只排序单层表
]]
_M.make_sign_str_sort = function( _params )
	-- body
	local t_src = {}
	-- 首先生成数组
	for k,v in pairs(_params) do
		table.insert(t_src,{k,v})
	end
	table.sort(t_src,sign_compare)
	local res = ""
	for i=1,#t_src  do
		if  type(t_src[i][2]) == "table" then
			res = res..t_src[i][1].."="..cjson.encode(t_src[i][2]) 
		else
			res = res..t_src[i][1].."="..t_src[i][2]
		end
		if i ~= #t_src then
			res = res.."&"
		end
	end 
	return res
end

--[[
make_urlencode_str 创建最后的字符串,该字符串为的每个字段需要进行一次urlencode!!!!!
]]
_M.make_urlencode_str = function( _params )
	-- body  
	local res = ""
	for k,v in pairs(_params) do
		if  type(v) == "table" then
			res = res..k.."=".. ngx.escape_uri(cjson.encode(v))
		else
			res = res..k.."="..ngx.escape_uri(v)
		end 
		res = res.."&"
	end 
	return string.sub(res,1,#res-1)
end

--[[
-- rsa_verify 使用支付宝公钥匙验证 加密字段,系统返回的加密字段必须为base64,需要调用者提前将base64 解码!!!
--  
-- example 
   	local sign_help = require "pay.model.sign_help"
   	local _unsign_str = "hello"
   	local _private_key = '-----BEGIN RSA PRIVATE KEY-----  xxxxx -----BEGIN RSA PRIVATE KEY-----'
   	local _algorithm = "SHA256"
    local base64_signed_str = sign_help.sign(_unsign_str, _private_key ,_algorithm )
	
-- @param  _unsign_str 		未加密的字符串
-- @param  _signed_str 		签名字符串
-- @param  _public_key		对于私钥签名的公钥 key
-- @param  _algorithm  		hash方式 默认使用SHA256
-- @return  base64编码之后的字符串 或者 nil 代表错误
--]]
_M.rsa_verify = function(_unsign_str, _signed_str, _public_key, _algorithm)
	if not _algorithm then _algorithm = "SHA256" end

	local public_cli =  rsa:new_rsa_public(_public_key, _algorithm)
	if not public_cli then return nil end
	local res,err = public_cli:verify(_unsign_str,_signed_str)
	return res
end


--[[
-- signed 用指定密钥签名字符串,返回base64 字符串
--  
-- example 
   	local sign_help = require "pay.model.sign_help"
   	local _unsign_str = "hello"
   	local _private_key = '-----BEGIN RSA PRIVATE KEY-----  xxxxx -----BEGIN RSA PRIVATE KEY-----'
   	local _algorithm = "SHA256"
    local base64_signed_str = sign_help.sign(_unsign_str, _private_key ,_algorithm )
	
-- @param  _unsign_str 		未加密的字符串
-- @param  _private_key		私钥key
-- @param  _algorithm  		hash方式 默认使用SHA256
-- @return  base64编码之后的字符串 或者 nil 代表错误
--]]
_M.rsa_sign = function(_unsign_str,_private_key, _algorithm)
	if not _algorithm then _algorithm = "SHA256" end
	local private_cli = rsa:new_rsa_private(_private_key, _algorithm)
	if not private_cli then return nil end
	local signed_str = private_cli:sign(_unsign_str) 
	return ngx.encode_base64(signed_str)
end



return _M