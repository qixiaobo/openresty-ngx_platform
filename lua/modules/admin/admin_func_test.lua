--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:admin_func_test.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  后台管理功能函数的访问测试脚本,不作为其他用途
--  
--]]

local menu = require "admin.model.menu"
local cjson = require "cjson"
--local menuList = menu.getMenuList()
--ngx.say(cjson.encode(menuList))
local neteaseHeader = require "netease_header"

 
local ffi = require "ffi"
 
ffi.cdef[[



void *curl_easy_init();
int curl_easy_setopt(void *curl, int option, ...);
int curl_easy_perform(void *curl);
void curl_easy_cleanup(void *curl);
char *curl_easy_strerror(int code);
int curl_easy_getinfo(void *curl, int info, ...);
typedef unsigned int (*WRITEFUNC)(void *ptr, unsigned int size, unsigned int nmemb, void *userdata);

typedef struct {
  char *data;
  struct curl_slist *next;
}curl_slist;
struct curl_slist *curl_slist_append(struct curl_slist *,const char *);

]]
 
local libcurl = ffi.load("libcurl") 
 
local curl = libcurl.curl_easy_init()

-- local http = require "resty.http" 
-- local httpc = http:new()


-- local postData = "DaylightSavingsUsed=1&Dscp=-1";
-- local res, err = httpc:request_uri("http://127.0.0.1:8080/api/sue?user_name=test&password=e10adc3949ba59abbe56e057f20f883e",{
--         method = "POST",
--         body = postData,
--         ssl_verify = true, -- 需要关闭这项才能发起https请求
--         --headers = headr,
--       })
-- if not res then
-- 	ngx.say(cjson.encode(err))
-- 	return
-- else
-- 	ngx.say(res.body)
-- end

local function widthSingle(inputstr)
    -- 计算字符串宽度
    -- 可以计算出字符宽度，用于显示使用
   local lenInByte = #inputstr
   local width = 0
   local i = 1
    while (i<=lenInByte) 
    do
        local curByte = string.byte(inputstr, i)
        local byteCount = 1;
        if curByte>0 and curByte<=127 then
            byteCount = 1                                               --1字节字符
        elseif curByte>=192 and curByte<223 then
            byteCount = 2                                               --双字节字符
        elseif curByte>=224 and curByte<239 then
            byteCount = 3                                               --汉字
        elseif curByte>=240 and curByte<=247 then
            byteCount = 4                                               --4字节字符
        end
         
        --local char = string.sub(inputstr, i, i+byteCount-1)
		--print(char)                                                          --看看这个字是什么
        i = i + byteCount                                              -- 重置下一字节的索引
        width = width + 1                                             -- 字符的个数（长度）
    end
    return width
end
local header = ngx.req.get_headers();
ngx.say(cjson.encode(header))

--curl = false;-- 主要测试所用
if curl then
 
local version=""
-- local function(ptr,size,nmemb,userdata)
-- version=version..ffi.string(ptr)
-- --ngx.log(ngx.ERR,ffi.string(ptr))
-- return size*nmemb
-- end
--这是把LUA函数转换成c回调函数
local getVersionCode = ffi.cast("WRITEFUNC",function(ptr,size,nmemb,userdata)
 
	version=version..ffi.string(ptr)
 	 
return size*nmemb
end)


local CURLOPT_URL = 10002 -- 参考 curl/curl.h 中定义
local CURLOPT_WRITEFUNCTION = 20011
local CURLOPT_VERBOSE = 41
local CURLOPT_HEADER = 42
local CURLOPT_POSTFIELDS = 10015
local CURLOPT_HTTPHEADER = 46
local CURLOPT_POST = 47
local CURLOPT_FOLLOWLOCATION = 52
local CURLOPT_SSL_VERIFYPEER = 64
local CURLOPT_SSL_VERIFYHOST = 81
local CURLOPT_NOSIGNAL = 99
local CURLOPT_PUT = 54
local CURLOPT_CUSTOMREQUEST = 10036
libcurl.curl_easy_setopt(curl, CURLOPT_VERBOSE, 1)

libcurl.curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, getVersionCode)
libcurl.curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0)
libcurl.curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0)
libcurl.curl_easy_setopt(curl, CURLOPT_POST, 1) 
libcurl.curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1)
--libcurl.curl_easy_setopt(curl, CURLOPT_HEADER, 1)  
libcurl.curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "GET")  
libcurl.curl_easy_setopt(curl, CURLOPT_URL, "http://localhost:8080/api/sue")
--libcurl.curl_easy_setopt(curl, CURLOPT_URL,  "http://139.196.180.249:6677/api/user/login?user_name=test&password=e10adc3949ba59abbe56e057f20f883e")

--libcurl.curl_easy_setopt(curl, CURLOPT_POSTFIELDS, "email=myemail@163.com&password=mypassword&autologin=1&submit=登 录&type=")
--libcurl.curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 0); 
--libcurl.curl_easy_setopt(curl, CURLOPT_COOKIEFILE, "/Users/zhu/CProjects/curlposttest.cookie");  


-- libcurl.curl_easy_setopt(curl, CURLOPT_URL, "http://localhost/admin/web/yumxintest.do")
--libcurl.curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0)
-- 设置头
	-- local esheaderdata = neteaseHeader.getNeteaseHttpHeadr(0) 
	-- -- ngx.log(ngx.ERR,'-----------1')
	-- --//增加HTTP header
	-- 另一种很常见的情况是需要一个空指针。请使用0 as *const _ 或者 std::ptr::null()来生产一个空指针。
	local c_slist_t = ffi.typeof("struct curl_slist*")
	local headers = ffi.cast(c_slist_t, 0)       -- 转换为指针地址
	 
	headers = libcurl.curl_slist_append(headers, "Content-Type:application/x-www-form-urlencoded"); 
 	headers = libcurl.curl_slist_append(headers, "AppKey:93c2730be068bfa8557eca30c56287bb");
 --    headers = libcurl.curl_slist_append(headers, "CurTime:"..esheaderdata.CurTime);
 --    headers = libcurl.curl_slist_append(headers, "Nonce:"..esheaderdata.Nonce);
 --    headers = libcurl.curl_slist_append(headers, "CheckSum:"..esheaderdata.CheckSum); 
	libcurl.curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers); 
  
local res = libcurl.curl_easy_perform(curl)
if res ~= 0 then 
 	ngx.log(ngx.ERR,'-----------5  ',ffi.string(libcurl.curl_easy_strerror(res)))
end
libcurl.curl_easy_cleanup(curl)
getVersionCode:free()
--remoteVersion=tonumber(version)
ngx.say("result is ",version)
end