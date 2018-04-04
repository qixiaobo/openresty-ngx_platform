
local cjson = require("cjson")

local _M = {}


function _M:parse_params(args, keys )
    if not args or not keys then
        return nil, false, "args=nil or keys = nil"
    end

    local result = true
    local params = nil
    local msg = ""

    for k, v in ipairs(keys) do
        if args[v] then
            if not params then params = {} end
            params[v] = args[v]
        else
            result = false
            msg = msg .. "[参数("..v..")] "
        end
    end
    return params, result, msg
end



function _M:format_insert(table_name, values)
    if not table_name then
        return nil
    end

    local sql = "INSERT INTO " .. table_name
    local str_values
    local str_conditions

    for k, v in pairs( values ) do
        if not str_conditions then
            str_conditions =  " (" .. k
        else
            str_conditions = str_conditions .. "," .. k
        end

        if not str_values then
            str_values = " VALUES (" .. ngx.quote_sql_str(v)
        else
            str_values = str_values .. "," .. ngx.quote_sql_str(v)
        end
    end

    str_conditions = str_conditions .. ")"
    str_values = str_values .. ")"

    if not str_conditions or not str_values then
        return nil
    end

    sql = sql .. str_conditions .. str_values .. ";"
    return sql
end


function _M:format_update(table_name, values, conditions) 
    if not table_name then
        return nil
    end

    local sql = "UPDATE " .. table_name
    local str_values
    local str_conditions

    for k, v in pairs(values) do 
        if not str_values then
            str_values = " SET "..k.. "="..ngx.quote_sql_str(v)
        else 
            str_values = str_values .. "," .. k.. "="..ngx.quote_sql_str(v)
        end
    end

    for k, v in pairs(self.data_conditions) do 
        if not str_conditions then
            str_conditions = " WHERE "..k.. "="..ngx.quote_sql_str(v)
        else 
            str_conditions = str_conditions.. ", AND " ..k.. "="..ngx.quote_sql_str(v)
        end
    end

    if not str_values or not str_conditions then
        ngx.log(ngx.ERR, "UPDATE SQL语句错误")
        return nil
    end

    sql = sql .. str_values .. str_conditions .. ";"
    return sql
end


function _M:format_select(table_name, keys, conditions)
    if not table_name or not keys then
        return nil
    end

    local sql = "SELECT " .. keys .. " from "..table_name
    if conditions then
        sql = sql .. " WHERE "..conditions
    end

    return sql..";"
end


return _M
