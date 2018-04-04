--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:request_help.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  post / get 数据数据获取, openresty的post key的数量最大不超过100,切记
--  
--]]

local cjson = require "cjson"
local _M = {} 
_M._VERSION = '0.01'
   
 --[[
   -- 获取http get/post 请求参数 
 --]]

--[[
-- getAllArgs 获取http get/post 请求参数  application/x-www-form-urlencoded 
-- example 
-- @param  无
-- @return 返回地址栏参数
--]] 
 _M.getAllArgs = function() 
    local request_method = ngx.var.request_method 
    local args = ngx.req.get_uri_args();
    if "GET" == request_method then
       return args
     -- 参数获取 
    elseif  "POST" == request_method then 
         ngx.req.read_body() 
         local postArgs = ngx.req.get_post_args() 
         if postArgs then 
             for k, v in pairs(postArgs) do 
                 args[k] = v 
             end 
         end  
     end 
     return args 
 end 

  _M.get_all_args = function()  
    local args = ngx.req.get_uri_args(); 
    ngx.req.read_body() 
    local postArgs = ngx.req.get_post_args() 
    if postArgs then 
     for k, v in pairs(postArgs) do 
         args[k] = v 
     end 
    end  
   
     return args 
 end 

 _M.get_post_json = function()  
     ngx.req.read_body()  
     local args = cjson.decode(ngx.req.get_body_data())
     
     return args 
 end


 _M.getPostJson = function() 
    local request_method = ngx.var.request_method 
     local args = {};
     if "GET" == request_method then
        args = ngx.req.get_uri_args()
     -- 参数获取 
    elseif  "POST" == request_method then 
         ngx.req.read_body() 
        
         args = cjson.decode(ngx.req.get_body_data())
     end 
     return args 
 end 

--[[
-- getUriArgs 将 专门取URI地址内的参数
-- example 
-- @param  无
-- @return 返回地址栏参数
--]] 
_M.getUriArgs = function()
     local args = nil 
     args = ngx.req.get_uri_args()
     return args
end

 
local function explode ( _str,seperator )  
    local pos, arr = 0, {}  
        for st, sp in function() return string.find( _str, seperator, pos, true ) end do  
            table.insert( arr, string.sub( _str, pos, st-1 ) )  
            pos = sp + 1  
        end  
    table.insert( arr, string.sub( _str, pos ) )  
    return arr  
end  

--[[
    当body有文件时使用获取参数接口
 --]]
function _M.init_form_args()  
    local receive_headers = ngx.req.get_headers()  
    local request_method = ngx.var.request_method  
  
        
    local args = {}  
    local file_args = {}  
    local is_have_file_param = false 

    if "GET" == request_method then  
        args = ngx.req.get_uri_args()  
    elseif "POST" == request_method then  
        ngx.req.read_body()  
        if string.sub(receive_headers["content-type"],1,20) == "multipart/form-data;" then--判断是否是multipart/form-data类型的表单  
            is_have_file_param = true  
            content_type = receive_headers["content-type"]  
            body_data = ngx.req.get_body_data()--body_data可是符合http协议的请求体，不是普通的字符串  
  
                        --请求体的size大于nginx配置里的client_body_buffer_size，则会导致请求体被缓冲到磁盘临时文件里，client_body_buffer_size默认是8k或者16k  
            if not body_data then  
                local datafile = ngx.req.get_body_file()  
                if not datafile then  
                    error_code = 1  
                    error_msg = "no request body found"  
                else  
                    local fh, err = io.open(datafile, "r")  
                    if not fh then  
                        error_code = 2  
                        error_msg = "failed to open " .. tostring(datafile) .. "for reading: " .. tostring(err)  
                    else  
                        fh:seek("set")  
                        body_data = fh:read("*a")  
                        fh:close()  
                        if body_data == "" then  
                            error_code = 3  
                            error_msg = "request body is empty"  
                        end  
                    end  
                end  
            end  
  
  
       local new_body_data = {}  
            --确保取到请求体的数据  
            if not error_code then  
                local boundary = "--" .. string.sub(receive_headers["content-type"],31)  
                local body_data_table = explode(tostring(body_data),boundary)  
  
  
                local first_string = table.remove(body_data_table,1)  
                local last_string = table.remove(body_data_table)  
  
  
                for i,v in ipairs(body_data_table) do  
                    local start_pos,end_pos,capture,capture2 = string.find(v,'Content%-Disposition: form%-data; name="(.+)"; filename="(.*)"')  
                    if not start_pos then--普通参数  
                        local t = explode(v,"\r\n\r\n")  
                        local temp_param_name = string.sub(t[1],41,-2)  
                        local temp_param_value = string.sub(t[2],1,-3)  
                        args[temp_param_name] = temp_param_value  
                    else--文件类型的参数，capture是参数名称，capture2是文件名  
                        file_args[capture] = capture2  
                        table.insert(new_body_data,v)  
                    end  
                end  
                table.insert(new_body_data,1,first_string)  
                table.insert(new_body_data,last_string)  
                --去掉app_key,app_secret等几个参数，把业务级别的参数传给内部的API  
                body_data = table.concat(new_body_data,boundary)--body_data可是符合http协议的请求体，不是普通的字符串  
            end  
        else  
            args = ngx.req.get_post_args()  
        end  
    end  
    args.body_data = body_data;
    return args;
end  

--[[
-- get_or_post 判断当前为post 还是 get 请求
-- example 
-- @param  无
-- @return true 表示post； false 表示 get 请求
--]] 
_M.get_or_post = function ()
    -- body
    local request_method = ngx.var.request_method; 
    if "GET" == request_method then  
       return false;
    elseif "POST" == request_method then  
        return true;
    end
    return nil
end


--[[
-- get_domain_url 获得域名
-- example 
-- @param  无
-- @return 获得协议+域名 http://www.goodtime.vip
--]] 
_M.get_domain_url = function()
    return ngx.var.scheme.."://"..ngx.var.host
end

--[[
-- get_curl_url 获得当前的访问的地址不包括参数
-- example 
-- @param  无
-- @return 返回除参数以外的地址信息
--]] 
_M.get_curl_url = function() 
    return ngx.var.scheme.."://"..ngx.var.host..ngx.var.request_uri
end


--[[
-- get_cli_ip 获得用户端ip地址
-- example 
-- @param  无
-- @return true 表示post； false 表示 get 请求
--]] 
_M.get_cli_ip = function()
    local headers=ngx.req.get_headers()
    local cli_ip=headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"
    return cli_ip
end
--[[
    http://127.0.0.1:80/testres.do
ngx.say( ngx.var.host)      -- 127.0.0.1
ngx.say( ngx.var.scheme ) -- http
ngx.say(ngx.var.remote_addr) -- 127.0.0.1 
ngx.say(ngx.var.scheme.."://"..ngx.var.remote_addr) 
ngx.say(ngx.var.server_addr) -- 127.0.0.1 
ngx.say(ngx.var.uri) -- /testres.do 


for k,v in pairs(ngx.var) do
    if type(k) == "string" then
        ngx.say(k)
        ngx.say(v)
    end

end
]]


return _M 


