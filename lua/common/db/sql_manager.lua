
local _M = {}

function _M.append(_s, _key, _value, _opt)
    if not _value then
        return _s
    end
    if string.len(_s) > 0 and _opt then
        _s = _s .. "" .. _opt .. " "
    end
    _s = _s .. _key .. "=" .. "'" .. _value .. "' "
    return _s
end

function _M.fmt_params(_params)
    local buf = nil
    for k, v in pairs(_params) do
        if buf then
            buf = buf .. ", "
        else
            buf = ""
        end
        buf = buf .. k .. "='" .. v .. "'"
    end
    return buf
end

function _M.fmt_insert(_tb_name, _params)
    local key = ""
    local value = ""
    for k, v in pairs(_params) do
        -- if v then
        if (string.len(key) > 0) then
            key = key .. ","
        end
        key = key .. k

        if (string.len(value) > 0) then
            value = value .. ","
        end
        value = value .. "\'" .. v .. "\'"
        -- else
        -- end
    end
    return string.format("INSERT INTO %s (%s) VALUES (%s)", _tb_name, key, value)
end

return _M
 