local _M = {}

--[[
    解析请求参数（GET）
]]
function _M.get_req_args(_keys1, _keys2)
    if not _keys1 then
        return nil, false, "keys is nil"
    end

    local args = {}
    local key_status = true
    local err = nil

    local req_args = ngx.req.get_uri_args()
    for k, v in pairs(_keys1) do
        if req_args[v] then
            args[v] = req_args[v]
        else
            key_status = false
            if not err then
                err = ""
            end
            err = err .. "[" .. v .. "]"
        end
    end
    if err then
        err = err .. " doesn't exist"
    end

    if _keys2 then
        for k, v in pairs(_keys2) do
            if req_args[v] then
                args[v] = req_args[v]
            end
        end
    end
    return args, key_status, err
end

--[[
    发送 HTTP 请求
]]
local resty_http = require("resty.http")

function _M.http_req(_url)
    local http = resty_http.new()
    http:set_timeout(10000)
    -- local param = {
    -- method = "POST",
    -- ssl_verify = false, -- 进行https访问
    -- body =  ngx.encode_args(_msg)
    -- }
    local param = {}
    local res, err = http:request_uri(_url, param)

    if not res then
        return nil, err
    else
        if res.status == 200 then
            return res.body, err
        else
            return nil, "HTTP response status error: status=" .. res.status .. "," .. err
        end
    end
end

--[[
    二进制转字符串
]]
function _M.to_hex(data)
    local resty_string = require("resty.string")
    return resty_string.to_hex(data)
end

return _M
