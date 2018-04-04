 
local resty_rsa = require "resty.rsa"
    local rsa_public_key, rsa_private_key, err = resty_rsa:generate_rsa_keys(2048)
    if not rsa_public_key then
        ngx.say('generate rsa keys err: ', err)
    end
-- ngx.say(rsa_public_key)
    if not rsa_private_key then
        ngx.say('generate rsa keys err: ', err)
    end
-- ngx.say(rsa_private_key)
 local pub, err = resty_rsa:new({ public_key = rsa_public_key })
    if not pub then
        ngx.say("new rsa err: ", err)
        return
    end
 local encrypted, err = pub:encrypt("hello")
    if not encrypted then
        ngx.say("failed to encrypt: ", err)
        return
    end
    ngx.say("encrypted length: ", #encrypted)
local priv, err = resty_rsa:new({ private_key = rsa_private_key })
    if not priv then
        ngx.say("new rsa err: ", err)
        return
    end
    local decrypted = priv:decrypt(encrypted)
    ngx.say(decrypted == "hello")

 local algorithm = "SHA1"
    local priv, err = resty_rsa:new({ private_key = rsa_private_key, algorithm = algorithm })
    if not priv then
        ngx.say("new rsa err: ", err)
        return
    end

    local str = "hello"
    local sig, err = priv:sign(str)
    if not sig then
        ngx.say("failed to sign:", err)
        return
    end
    ngx.say("sig length: ", #sig)

    local pub, err = resty_rsa:new({ public_key = rsa_public_key, algorithm = algorithm })
    if not pub then
        ngx.say("new rsa err: ", err)
        return
    end
    local verify, err = pub:verify(str, sig)
    if not verify then
        ngx.say("verify err: ", err)
        return
    end
    ngx.say(verify)

----------------------------------------------------------------------------

local RSA_PUBLIC_KEY = [[
-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAJ9YqFCTlhnmTYNCezMfy7yb7xwAzRinXup1Zl51517rhJq8W0wVwNt+
mcKwRzisA1SIqPGlhiyDb2RJKc1cCNrVNfj7xxOKCIihkIsTIKXzDfeAqrm0bU80
BSjgjj6YUKZinUAACPoao8v+QFoRlXlsAy72mY7ipVnJqBd1AOPVAgMBAAE=
-----END RSA PUBLIC KEY-----
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

--

local resty_rsa = require "resty.rsa"
local algorithm = "SHA"

local pub, err = resty_rsa:new({
    public_key = RSA_PUBLIC_KEY,
    padding = resty_rsa.PADDING.RSA_PKCS1_PADDING,
    algorithm = algorithm,
})
if not pub then
    ngx.say("new rsa public err: ", err)
    return
end

local priv, err = resty_rsa:new({
    private_key = RSA_PRIV_KEY,
    padding = resty_rsa.PADDING.RSA_PKCS1_PADDING,
    algorithm = algorithm,
})
if not priv then
    ngx.say("new rsa err: ", err)
    return
end


local num = 5 * 10000

local str = "hello test"

local encrypted, decrypted, err, sig, verify

ngx.update_time()
local now = ngx.now()

local function timer(operation)
    ngx.update_time()
    local t = ngx.now()

    ngx.say(operation, " for ", num, " times cost : ", t - now, "s")
    now = t
end

for i = 1, num do
    encrypted, err = pub:encrypt(str)
    if not encrypted then
        ngx.say("failed to encrypt: ", err)
        return
    end
end

timer("encrypt")

for i = 1, num do
    decrypted = priv:decrypt(encrypted)
    if decrypted ~= str then
        ngx.say("decrypted not match")
        return
    end
end

timer("decrypt")

for i = 1, num do
    sig, err = priv:sign(str)
    if not sig then
        ngx.say("failed to sign:", err)
        return
    end
end

timer("sign")

for i = 1, num do
    verify, err = pub:verify(str, sig)
    if not verify then
        ngx.say("verify err: ", err)
        return
    end
end

timer("verify")
