--[[
    序列化到本地

]]

local _M = {}
_M._VERSION = '0.01'            
local mt = { __index = _M }                    

function _M.new()
    return setmetatable({}, mt)    
end


function _M.serialize(t, sort_parent, sort_child)  
    local mark={}  
    local assign={}  
      
    local function ser_table(tbl,parent)  
        mark[tbl]=parent  
        local tmp={}  
        local sortList = {};  
        for k,v in pairs(tbl) do  
            sortList[#sortList + 1] = {key=k, value=v};  
        end  
  
        if tostring(parent) == "ret" then  
            if sort_parent then table.sort(sortList, sort_parent); end  
        else  
            if sort_child then table.sort(sortList, sort_child); end  
        end  
  
        for i = 1, #sortList do  
            local info = sortList[i];  
            local k = info.key;  
            local v = info.value;  
            local key= type(k)=="number" and "["..k.."]" or k;  
            if type(v)=="table" then  
                local dotkey= parent..(type(k)=="number" and key or "."..key)  
                if mark[v] then  
                    table.insert(assign,dotkey.."="..mark[v])  
                else  
                    table.insert(tmp, "\n"..key.."="..ser_table(v,dotkey))  
                end  
            else  
                if type(v) == "string" then  
                    table.insert(tmp, key..'="'..v..'"');  
                else  
                    table.insert(tmp, key.."="..tostring(v));  
                end  
            end  
        end  
  
        return "{"..table.concat(tmp,",").."}";  
    end  
   
    -- return "do local ret=\n\n"..ser_table(t,"ret")..table.concat(assign," ").."\n\n return ret end"
    return   ser_table(t,"ret")..table.concat(assign," ")
end  

function _M.split(str, delimiter)   --根据一个符号delimiter，将str隔开，隔成table
    if (delimiter=='') then return false end  
    local pos,arr = 0, {}  
    -- for each divider found  
    for st,sp in function() return string.find(str, delimiter, pos, true) end do  
        table.insert(arr, string.sub(str, pos, st - 1))  
        pos = sp + 1  
    end  
    table.insert(arr, string.sub(str, pos))  
    return arr  
end  
  
function _M.writefile(file_str_path,str)   --传入要写入的内容(string)，以及要写入的文件的路径(包括文件)
    local file=io.open(file_str_path,"ab");  
  
    local len = string.len(str);  
    local tbl = _M.split(str, "\n");   --将字符串的每行都隔成一个table
    for i = 1, #tbl do  
        file:write(tbl[i].."\n");  
    end  
    file:close();  
end  


-- 反序列化
function _M.t_S2T(_szText)  
    --栈  
    function stack_newStack()  
        local first = 1  
        local last = 0  
        local stack = {}  
        local m_public = {}  
        function m_public.pushBack(_tempObj)  
            last = last + 1  
            stack[last] = _tempObj  
        end  
        function m_public.temp_getBack()  
            if m_public.bool_isEmpty() then  
                return nil  
            else  
                local val = stack[last]  
                return val  
            end  
        end  
        function m_public.popBack()  
            stack[last] = nil  
            last = last - 1  
        end  
        function m_public.bool_isEmpty()  
            if first > last then  
                first = 1  
                last = 0  
                return true  
            else  
                return false  
            end  
        end  
        function m_public.clear()  
            while false == m_public.bool_isEmpty() do  
                stack.popFront()  
            end  
        end  
        return m_public  
    end 


    function getVal(_szVal)  
        local s, e = string.find(_szVal,'"',1,string.len(_szVal))  
        if nil ~= s and nil ~= e then  
            --return _szVal  
            return string.sub(_szVal,2,string.len(_szVal)-1)  
        else  
            return tonumber(_szVal)  
        end  
    end  
  
    local m_szText = _szText  
    ngx.log(ngx.ERR,"************_szText*****************".._szText)
    ngx.log(ngx.ERR,"aaaaaaaaaaaaaam_szTextaaaaaaaaaaaaaa"..m_szText)
    local charTemp = string.sub(m_szText,1,1)  
    if "{" == charTemp then  
        m_szText = string.sub(m_szText,2,string.len(m_szText))  
    end  

    function doS2T()  
        local tRet = {}  
        local tTemp = nil  
        local stackOperator = stack_newStack()  
        local stackItem = stack_newStack()  
        local val = ""  
        while true do  
            local dLen = string.len(m_szText)  
            if dLen <= 0 then  
                break  
            end  
  
            charTemp = string.sub(m_szText,1,1)  
            if "[" == charTemp or "=" == charTemp then  
                 ngx.log(ngx.ERR,"111111111111111")
                stackOperator.pushBack(charTemp)  
                m_szText = string.sub(m_szText,2,dLen)  
            elseif '"' == charTemp then  
                 ngx.log(ngx.ERR,"2222222222222")
                local s, e = string.find(m_szText, '"', 2, dLen)  
                if nil ~= s and nil ~= e then  
                    val = val .. string.sub(m_szText,1,s)  
                    m_szText = string.sub(m_szText,s+1,dLen)  
                else  
                    return nil  
                end  
            elseif "]" == charTemp then  
                ngx.log(ngx.ERR,"33333333333333")
                if "[" == stackOperator.temp_getBack() then  
                    stackOperator.popBack()  
                    stackItem.pushBack(val)  
                    val = ""  
                    m_szText = string.sub(m_szText,2,dLen)  
                else  
                    return nil  
                end  
            elseif "," == charTemp then  
                 ngx.log(ngx.ERR,"44444444444444")
                if "=" == stackOperator.temp_getBack() then  
                    stackOperator.popBack()  
                    local Item = stackItem.temp_getBack()  
                    Item = getVal(Item)  
                    stackItem.popBack()  
                    if nil ~= tTemp then  
                        tRet[Item] = tTemp  
                        tTemp = nil  
                    else  
                        tRet[Item] = getVal(val)  
                    end  
                    val = ""  
                    m_szText = string.sub(m_szText,2,dLen)  
                else  
                    return nil  
                end  
            elseif "{" == charTemp then  
                ngx.log(ngx.ERR,"55555555555555")
                m_szText = string.sub(m_szText,2,string.len(m_szText))  
                local t = doS2T()  
                if nil ~= t then  
                    szText = sz_T2S(t)  
                    tTemp = t  
                    --val = val .. szText  
                else  
                    return nil  
                end  
            elseif "}" == charTemp then  
                ngx.log(ngx.ERR,"666666666666")
                m_szText = string.sub(m_szText,2,string.len(m_szText))  
                return tRet  
            elseif " " ~= charTemp then  
                ngx.log(ngx.ERR,"777777777777")
                val = val .. charTemp  
                m_szText = string.sub(m_szText,2,dLen)  
            else  
                ngx.log(ngx.ERR,"888888888888")
                m_szText = string.sub(m_szText,2,dLen)  
            end  
        end  
        return tRet  
    end  
    local t = doS2T()  
    return t  
end


return _M