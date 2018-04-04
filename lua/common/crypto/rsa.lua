--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:rsa.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  RSA非对称加密技术的功能,用于通信过程开始以及中间过程的加密处理,进一步保护数据的安全性
--  由于非对称加密技术的计算量比较大,所以系统在接入时进行一次加密处理,后续采用ace堆成加密
--  

技巧:  
一.将BEGIN PUBLIC KEY的公钥拼接成格式如下:

-----BEGIN PUBLIC KEY-----

MIGJAoGBAKDdUTw0Vfho0wvvVdaFuNX7t2IL8CiEz19rderRwOU8X2JTRc5hEbch
JlGcBUNPfT/kJD49pCkWJsj5Tyg9swDh1cqyq7GAtkdYyB44lKvpEZecExu7MCwmj
7hUq1MzfyBlY63523ROWDaBK2x4QPPTPsUBxF/UtWojz61FIil3BAgMBAAE=

-----END PUBLIC KEY-----

存储为文件pub.key   

二. 用命令解析出BEGIN RSA PUBLIC KEY格式的公钥

openssl rsa -pubin -in pub.key -RSAPublicKey_out



--]]

-- 对于公钥私钥的提取，详细请看http://www.cnblogs.com/dreamer-One/p/5621134.html
-- 另外付在线加解密工具链接：http://tool.chacuo.net/cryptrsaprikey

-- 生成或者已经生成的公key 格式如下

-- rsa_public_key = [[
--     -----BEGIN RSA PUBLIC KEY-----
--     MIGJAoGBAJ9YqFCTlhnmTYNCezMfy7yb7xwAzRinXup1Zl51517rhJq8W0wVwNt+
--     mcKwRzisA1SIqPGlhiyDb2RJKc1cCNrVNfj7xxOKCIihkIsTIKXzDfeAqrm0bU80
--     BSjgjj6YUKZinUAACPoao8v+QFoRlXlsAy72mY7ipVnJqBd1AOPVAgMBAAE=
--     -----END RSA PUBLIC KEY-----
-- ]]
    -- 私钥或者系统生成的私钥 格式如下
-- rsa_private_key = [[
--     -----BEGIN RSA PRIVATE KEY-----
--     MIICXAIBAAKBgQCfWKhQk5YZ5k2DQnszH8u8m+8cAM0Yp17qdWZedede64SavFtM
--     FcDbfpnCsEc4rANUiKjxpYYsg29kSSnNXAja1TX4+8cTigiIoZCLEyCl8w33gKq5
--     tG1PNAUo4I4+mFCmYp1AAAj6GqPL/kBaEZV5bAMu9pmO4qVZyagXdQDj1QIDAQAB
--     AoGBAJega3lRFvHKPlP6vPTm+p2c3CiPcppVGXKNCD42f1XJUsNTHKUHxh6XF4U0
--     7HC27exQpkJbOZO99g89t3NccmcZPOCCz4aN0LcKv9oVZQz3Avz6aYreSESwLPqy
--     AgmJEvuVe/cdwkhjAvIcbwc4rnI3OBRHXmy2h3SmO0Gkx3D5AkEAyvTrrBxDCQeW
--     S4oI2pnalHyLi1apDI/Wn76oNKW/dQ36SPcqMLTzGmdfxViUhh19ySV5id8AddbE
--     /b72yQLCuwJBAMj97VFPInOwm2SaWm3tw60fbJOXxuWLC6ltEfqAMFcv94ZT/Vpg
--     nv93jkF9DLQC/CWHbjZbvtYTlzpevxYL8q8CQHiAKHkcopR2475f61fXJ1coBzYo
--     suAZesWHzpjLnDwkm2i9D1ix5vDTVaJ3MF/cnLVTwbChLcXJSVabDi1UrUcCQAmn
--     iNq6/mCoPw6aC3X0Uc3jEIgWZktoXmsI/jAWMDw/5ZfiOO06bui+iWrD4vRSoGH9
--     G2IpDgWic0Uuf+dDM6kCQF2/UbL6MZKDC4rVeFF3vJh7EScfmfssQ/eVEz637N06
--     2pzSvvB4xq6Gt9VwoGVNsn5r/K6AbT+rmewW57Jo7pg=
--     -----END RSA PRIVATE KEY-----
-- ]]
-- rsa_private_password = "password", 
-- algorithm = "SHA1",  -- md4 md5 ripemd160 sha0 sha1 sha224 sha256 sha384 sha512
-- padding = resty_rsa.PADDING.RSA_PKCS1_PADDING, -- 

-- bits = 2048

   
local resty_rsa = require "resty.rsa"

--公钥
local RSA_PUBLIC_KEY = [[
-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAJ9YqFCTlhnmTYNCezMfy7yb7xwAzRinXup1Zl51517rhJq8W0wVwNt+
mcKwRzisA1SIqPGlhiyDb2RJKc1cCNrVNfj7xxOKCIihkIsTIKXzDfeAqrm0bU80
BSjgjj6YUKZinUAACPoao8v+QFoRlXlsAy72mY7ipVnJqBd1AOPVAgMBAAE=
-----END RSA PUBLIC KEY-----
]]

 

-- 私钥 pkcs1格式的私钥结构,java 需要使用pkcs8格式的
--[[
PKCS#8 私钥加密格式:
-----BEGIN ENCRYPTED PRIVATE KEY-----  
BASE64私钥内容  
-----ENDENCRYPTED PRIVATE KEY-----  

PKCS#8 私钥非加密格式:
-----BEGIN PRIVATE KEY-----  
BASE64私钥内容  
-----END PRIVATEKEY----- 

Openssl ASN格式:

-----BEGIN RSA PRIVATE KEY-----  
Proc-Type: 4,ENCRYPTED  
DEK-Info:DES-EDE3-CBC,4D5D1AF13367D726  
BASE64私钥内容  
-----END RSA PRIVATE KEY-----  
]]

local RSA_PRIV_KEY = [[
-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQCfWKhQk5YZ5k2DQnszH8u8m+8cAM0Yp17qdWZedede64SavFtM
FcDbfpnCsEc4rANUiKjxpYYsg29kSSnNXAja1TX4+8cTigiIoZCLEyCl8w33gKq5
tG1PNAUo4I4+mFCmYp1AAAj6GqPL/kBaEZV5bAMu9pmO4qVZyagXdQDj1QIDAQAB
AoGBAJega3lRFvHKPlP6vPTm+p2c3CiPcppVGXKNCD42f1XJUsNTHKUHxh6XF4U0
7HC27exQpkJbOZO99g89t3NccmcZPOCCz4aN0LcKv9oVZQz3Avz6aYreSESwLPqy
AgmJEvuVe/cdwkhjAvIcbwc4rnI3OBRHXmy2h3SmO0Gkx3D5AkEAyvTrrBxDCQeW
S4oI2pnalHyLi1apDI/Wn76oNKW/dQ36SPcqMLTzGmdfxViUhh19ySV5id8AddbE
/b72yQLCuwJBAMj97VFPInOwm2SaWm3tw60fbJOXxuWLC6ltEfqAMFcv94ZT/Vpg
nv93jkF9DLQC/CWHbjZbvtYTlzpevxYL8q8CQHiAKHkcopR2475f61fXJ1coBzYo
suAZesWHzpjLnDwkm2i9D1ix5vDTVaJ3MF/cnLVTwbChLcXJSVabDi1UrUcCQAmn
iNq6/mCoPw6aC3X0Uc3jEIgWZktoXmsI/jAWMDw/5ZfiOO06bui+iWrD4vRSoGH9
G2IpDgWic0Uuf+dDM6kCQF2/UbL6MZKDC4rVeFF3vJh7EScfmfssQ/eVEz637N06
2pzSvvB4xq6Gt9VwoGVNsn5r/K6AbT+rmewW57Jo7pg=
-----END RSA PRIVATE KEY-----
]]
local  opts = {
        rsa_public_key = RSA_PUBLIC_KEY,
        rsa_private_key = RSA_PRIV_KEY,
        algorithm = "SHA1",
        padding = resty_rsa.PADDING.RSA_PKCS1_PADDING, 
   } 



--[[
-- 定义rsa简单封装函数 简化数据加密通信服务
    -- _M = {  
    public_obj 
    -- or private_obj
-- } 

-- ]]


local _M = {  
   bits = 2048,
}
_M.__index = _M

local rsa_private_key_match = "-----BEGIN RSA PRIVATE KEY(a*)END RSA PRIVATE KEY-----"
local rsa_public_key_match = "-----BEGIN RSA PRIVATE KEY(a*)END RSA PRIVATE KEY-----"

local rsa_private_key_match1 = "-----BEGIN RSA PRIVATE KEY-----"
local rsa_private_key_match2 = "-----END RSA PRIVATE KEY-----"


local rsa_public_key_match1 = "-----BEGIN RSA PUBLIC KEY-----"
local rsa_public_key_match2 = "-----END RSA PUBLIC KEY-----"


local rsa_keys_pre = function(_rsa_public_key, _rsa_private_key )
  

    local pubst2,pubre2 = string.find(_rsa_public_key, rsa_public_key_match2,1,true)
    local str_public = string.sub(_rsa_public_key,1,pubre2)


    -- local prist1,prise1 = string.find(_rsa_private_key, rsa_private_key_match1,1,true)
    local prist2,prise2 = string.find(_rsa_private_key, rsa_private_key_match2,1,true)
    -- local temp_private = string.gsub(string.sub(rsa_private_key_match2,1,se2),"\n","")
    local str_private = string.sub(_rsa_private_key,1,prise2)



    return str_public,str_private

end

--[[
-- _M.generate_rsa_keys() 
--  创建服务端随机的 public_key and private_key ,通过key进行后续操作
-- example
    local rsaImpl = require "common.crypto.rsa":generate_rsa_keys(2048)
 
-- @param bits    specifying the number of bits. 
-- @return  public_key,private_key
--]]
function _M.generate_rsa_keys(bits)
     
    local rsa_public_key, rsa_private_key, err = resty_rsa:generate_rsa_keys(bits)
    if not rsa_public_key then
       ngx.log(ngx.ERR,"rsa error ,err is ",err)
       return nil
    end 
    ngx.log(ngx.ERR,"public: ",_rsa_public_key)
    ngx.log(ngx.ERR,"private: ",_rsa_private_key)
    -- 清理后缀无用字符串
    return rsa_keys_pre(rsa_public_key,rsa_private_key)
end

--[[
--  将非 pkcs8 格式的 rsa 私钥 key 转 java 使用的 _private_key_not_pkcs8 格式 私钥
-- example 
 
-- @param _private_key_not_pkcs8  非 pkcs8 格式key 
-- @return  _private_key_pkcs8 
]]
function _M.rsa_private_key_to_pkcs8(_private_key_not_pkcs8)




end

--[[
--  将 pkcs8 格式的 key 转 非 pkcs8 格式的 密钥 
-- example
    local rsaImpl = require "common.crypto.rsa":generate_rsa_keys(2048)
 
-- @param _private_key_pkcs8  非 pkcs8 格式key 
-- @return  _private_key_not_pkcs8 
]]
function _M.rsa_private_key_to_not_pkcs8(_private_key_pkcs8)
  
end

--[[
--  将非 pkcs8 格式的 rsa 公钥 key 转 java 使用的 _private_key_not_pkcs8 格式 公钥
-- example 
 
-- @param _public_key_not_pkcs8  非 pkcs8 格式key 
-- @return  _public_key_pkcs8 
]]
function _M.rsa_public_key_to_npkcs8(_public_key_not_pkcs8)
  
end

--[[
--  将非 pkcs8 格式的 rsa 公钥 key 转 java 使用的 _private_key_not_pkcs8 格式 公钥
-- example 
 
-- @param _private_key_pkcs8  非 pkcs8 格式key 
-- @return  _public_key_not_pkcs8 
]]
function _M.rsa_public_key_to_not_pkcs8(_private_key_pkcs8)

end

--[[
--  将非 pkcs8 格式的 rsa 私钥 转换为 字符串  需要调用一次rsa_public_key_to_not_pkcs8 进行转换
-- example 
 
-- @param _private_key_not_pkcs8  非 pkcs8 格式key 
-- @return  _private_key_str
]]
function _M.rsa_private_key_to_str(_private_key_not_pkcs8)
    local st1,se1 = string.find(_private_key_not_pkcs8, rsa_private_key_match1,1,true)
    local st2,se2 = string.find(_private_key_not_pkcs8, rsa_private_key_match2,1,true)
    -- return string.gsub(string.sub(_private_key_not_pkcs8,se1+1,st2-1),"\n","")
    
    local res_str = string.gsub(string.sub(string.sub(_private_key_not_pkcs8,se1+1,st2-1),se1+1,st2-1),"\n","")
    return res_str
end

--[[
--  将非 pkcs8 格式的 rsa 公钥 转换为 字符串  需要调用一次rsa_public_key_to_not_pkcs8 进行转换
-- example 
 
-- @param _public_key_not_pkcs8  非 pkcs8 格式key 
-- @return  _public_key_str
]]
function _M.rsa_public_key_to_str(_public_key_not_pkcs8)
    local st1,se1 = string.find(_public_key_not_pkcs8, rsa_public_key_match1,1,true)
    local st2,se2 = string.find(_public_key_not_pkcs8, rsa_public_key_match2,1,true)
    
    local res_str = string.gsub(string.sub(_public_key_not_pkcs8,se1+1,st2-1),"\n","")
    return res_str
end


--[[
--  将 rsa 私钥字符串  转换为 非 pkcs8 格式的 key格式  
-- example 
 
-- @param _rsa_private_str_ rsa 私钥字符串
-- @return  _private_key_not_pkcs8
]]
function _M.rsa_private_str_to_key(_rsa_private_str_)
    local begin_str = rsa_private_key_match1
    local end_str = rsa_private_key_match2

    local len =  string.len(_rsa_private_str_)
   -- for i=0,
end

--[[
-- 将 rsa 公钥字符串  转换为 非 pkcs8 格式的 key 格式  
-- example 
 
-- @param _rsa_public_str rsa 公钥字符串
-- @return  _public_key_not_pkcs8
]]
function _M.rsa_public_str_to_key(_rsa_public_str)
  
end


--[[
-- _M.new_rsa_public(self,public_key)  _M:new_rsa_public(public_key) 
--  创建服务端随机的 public_key and private_key ,通过key进行后续操作
-- example
    local rsaImpl = require "common.crypto.rsa":generate_rsa_keys(2048)
 
-- @param bits    specifying the number of bits. 
-- @return  public_key,private_key
--]]
function _M:new_rsa_public(public_key,algorithm)
    -- body 
    local opts = { 
    }
    opts.public_key = public_key and public_key or RSA_PUBLIC_KEY
    opts.algorithm = algorithm and algorithm or "SHA1"

    local pub, err = resty_rsa:new(opts)
    if not pub then
        ngx.log(ngx.ERR, "new public rsa err: ", err)
        return
    end
    local _rsaImp = setmetatable({}, _M)   
    _rsaImp.rsa_obj = pub
    return _rsaImp
end
function _M:new_rsa_private(private_key,algorithm,pwd)
    -- body 
    local opts = { 
    }
    opts.private_key = private_key and private_key or RSA_PRIV_KEY
    opts.algorithm = algorithm and algorithm or "SHA1"

    opts.password = pwd and pwd or nil

    local priv, err = resty_rsa:new(opts)
    if not priv then
        ngx.log(ngx.ERR, "new private rsa err: ", err)
        return
    end
    local _rsaImp = setmetatable({}, _M)   
    _rsaImp.rsa_obj = priv
    return _rsaImp
end


function _M:encrypt( str )
    -- body
    if not self.rsa_obj or type(str) ~= "string" then return nil end

    local encrypted, err = self.rsa_obj:encrypt(str)
    if not encrypted then
        ngx.log(ngx.ERR,"failed to encrypt: ", err)
        return
    end
    return encrypted 
end

function _M:decrypt( encrypted )
    -- body
    if not self.rsa_obj then return nil end

    local decrypted, err = self.rsa_obj:decrypt(encrypted)
    if not decrypted then
        ngx.log(ngx.ERR,"failed to decrypt: ", err)
        return
    end
    return decrypted 
end


function _M:sign(str) 

    local sig, err = self.rsa_obj:sign(str)
    if not sig then
        ngx.say("failed to sign:", err)
        return
    end
    return sig
end
 

function _M:verify(str,sig)
    local verify, err = self.rsa_obj:verify(str, sig)
    if not verify then
        ngx.say("verify err: ", err)
        return
    end
    return verify
end 


return _M