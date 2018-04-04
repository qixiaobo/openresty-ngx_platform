--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:alipay_conf.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  支付宝商家各类字段定义与约定
--]]

local _M = {

-- 支付宝公钥
ALIPAY_PUBLIC_KEY=[[
-----BEGIN RSA PUBLIC KEY-----
MIIBCgKCAQEAzLZPWvLnsX4qmticShRhVJTU4VGBXzILxZXz6BPY6Fv0idYoV2Xf
wI8lgqck+Flowag+QB2rpcr+zjiu98zzYlxANXS/lFrVJ6iMHaM3X1ZoFP1Ij0MZ
NtFtsV1upDkhtg71mAOf95Fs62hFQsOLZeGAXkkP5LOzSMoB2FYp2XUbyBX0m/Q5
+0RvAxrLkngMx8nU5GZPvSOnmAhuUr6KITyG+dWYQ5dTq++BB1R/OBK12InenpYM
ak1RMIV/J7Zezakz8bwbRISWC+wUz/3JaEdENfGovlED7eKgskkkuiSkewtoYJir
k/Qk5oowbvdTKhBJ6SVcV5taBHkCyWFtnQIDAQAB
-----END RSA PUBLIC KEY-----
]],

RSA_PRIVATE_KEY=[[
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAw2g6sgHddMmiEzQSS2rXbLGBa937Nzfd5JUpc28y99fkmTxl
KlZdxV9g7F/ceCtuQIQIXNWO9vCnJajQvKofbZpzDpUU6eWlAQbtIZytJbwyp5OW
qiWuU5+otLMb0dImk0QLlpjVmaxwzQPrKHGRoXLe3+BN26rW+AZtlo2mGJ+B5aXU
tjBohON3yDbCgj0uyICJKT87EZow2efWXbZZU2Tw4MqbWH0S+d5NfmaiZZoUQB1R
iha/Q24iYxh7/yEJ/UunM/qpbCY92DlVEjMkEZswzGJ2K7tW/pnO1yAmASS44vwc
WpyZIZEVrGBzuj9FfGdYzyrtGtavP2xEQDz1nQIDAQABAoIBADS9+EG9oSF5nuZi
AqIah2TOEGml8712tcyRuitvEym0Ov5lP8UKpKq2ULncMey5hDujp4IvHjRmxiaz
Bww1OuBhdLa15HwxQLUjQnP1DwMFZgK3Ik5wdzoY+Pc09MhQWZscHaibPeQJmDSt
3xX+eVlDYQa6SymEVhuB2KhvOSqhweL6W1pN0zOZm4N9Q42omhnnvzztE+zTSaHo
mQwkWBcDHXBsOB+zgRAnLdzejhuq3cDvYQLtaRjxoSEMpBLRnaovoE+9phD/32KP
qGOq4s7m7C24gO5lhQQ+nOKAKJG8eGfsL/5H0gS+TdakO7KkjeFVLCFCH8VTsSJD
SDjsCYECgYEA8N6NNn0K1eogU0/PFplwsX6gkl/BHEv6C4/kfMCyHB1EGevpoZXy
9HDhS6+1mHyNQA6akWCy2BY/hvPYDn7103uwpcZQhKxMiXdraM0ynikgLqQo1uQ3
WeUc1I6hNoCwXzSWp+DUvqFb0gbKZRtZHWRPK+ubQwQcCpAjttm7FX0CgYEAz66Y
PoXkAYdBpJeJvRbNy56gbb1Jt+AivJ9wh41WYV9bWDNcTOd+HFcdBP2XE2akDto2
S12zjtyPnR411Q69WM70oAoGC5ZUkZDo20Y+H+kfBYFg/eaHxkDJKGeYm7zgKqtr
wGtedk0WW4bf/bRULoV9VG92ATDb+xIB2Sjo2qECgYBMEHvXsTUyyHTc2l8za9FC
vBJJJyP8o6Ga9R3ap5+XcUaISQ/Gj2vh9aOwGxTlyq9wgywcrMTNqHj3TRn1ufI3
juAB+daDj0W8Q5IPzn0lpScck4qyEe/I26l3FnOimpEX/6tz6HRGnv44HRzdQP2r
Ynn+DLFDQJD6ZPpiS+/goQKBgQDCXO4SpY+rdoASn9fCZVMYW05dJaeWNGeOC9Fu
qvHKk0mTlA2v036M22JHR2VaPNcRJ1tk0T64Vub47ksHKJJASP9bv8XEll5zFSE4
BdciWjQ0HM8/D77F5d/ctod2SR+qD1/6ZwGyyZZA9ksuztNx7nBK0z2nA6j8oe+k
4sp5wQKBgA0hKFwjvK8hckYweLFREeQRaygQI6bwZ9TjcgN6FX58rLhUlsmodYZ0
6cIMZjDsamW0Ux8cE15TZTsGhvp5utkK3F5S/wpfY6aCF9V0wgcFcyXeeM/65O7c
UNy0pCCE8uNBHVw+3q2QYtJhq8e1nEThU3RJ7K7OqJeP8eI87Ihe
-----END RSA PRIVATE KEY-----
]],

  
-- 系统默认公钥,该格式为rsa public ,本系统只支持 BEGIN RSA PUBLIC KEY 不支持 BEGIN PUBLIC KEY格式,遇到该格式需要用户自行转换一次
-- 该公钥需要配置在阿里云的商家应用配置上
RSA_PUBLIC_KEY=[[
-----BEGIN RSA PUBLIC KEY-----
MIIBCgKCAQEAw2g6sgHddMmiEzQSS2rXbLGBa937Nzfd5JUpc28y99fkmTxlKlZd
xV9g7F/ceCtuQIQIXNWO9vCnJajQvKofbZpzDpUU6eWlAQbtIZytJbwyp5OWqiWu
U5+otLMb0dImk0QLlpjVmaxwzQPrKHGRoXLe3+BN26rW+AZtlo2mGJ+B5aXUtjBo
hON3yDbCgj0uyICJKT87EZow2efWXbZZU2Tw4MqbWH0S+d5NfmaiZZoUQB1Riha/
Q24iYxh7/yEJ/UunM/qpbCY92DlVEjMkEZswzGJ2K7tW/pnO1yAmASS44vwcWpyZ
IZEVrGBzuj9FfGdYzyrtGtavP2xEQDz1nQIDAQAB
-----END RSA PUBLIC KEY-----
]],
 

RES_SECRET="CtXBf4mlkxPgt6meYcpCMg==",

-- 商户appid
APPID="2017122601230607",
 
-- 商家编号
UID="2088921272720486",

-- 默认异步通知地址,由支付宝回调之后主动通知
NOTIFY_URL = "/pay/alipay/alipay_notify.do", 
GAME_NOTIFY_URL = "/pay/alipay/alipay_game_notify.do", 
-- 指定的域名支付
YU_NAME = "http://www.91sweep.com",
}


return _M