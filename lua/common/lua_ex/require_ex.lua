--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:myrequire.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  系统引入函数的封装,用于系统的文件导入
--  
--]]

local cjson = require "cjson"
local _api_data = require "common.api_data_help"

local prefix = "web."       
-- local path = prefix .. moduleName


--[[
-- 将 myrequire 引入系统模块的封装函数,如果出错,直接返回指定信息或者模块
-- example
      
-- @param moduleName 模块名称
-- @param _api_or_web 返回方式,如果是web(false),如果是api(true)访问,
						则直接返回错误data
-- @param is_debug 是否开启debug

--]]

function myrequire(moduleName, _api_or_web, is_debug)
	-- body
	-- 尝试引入模块，不存在则报错
	local ret, ctrl, err = pcall(require, moduleName)

	-- local is_debug = true       -- 调试阶段，会输出错误信息到页面上
	if ret == false then
	    if is_debug then
	        ngx.status = 404
	        -- ngx.say("<p style='font-size: 50px'>Error: <span style='color:red'>" .. ctrl .. "</span> module not found !</p>")
	    	ngx.log(ngx.ERR,"require module name error ,module name is ",moduleName)
	    end
	    
	    -- 执行api回调函数 错误返回
	    if _api_or_web then
	    	local res = _api_data.new(ZS_ERROR_CODE.ERROR_NO_MODULE,{},"failed")
	    	-- ngx.exit(404)
	    	ngx.say(cjson.encode(res))
	    	ngx.eof()
	    else
	    	ngx.exit(404)
	    end
	    
	end

	return ctrl
end

--[[
 for i,v in ipairs{...} do      --{...} 代表一个由变长参数组成的数组

                       s = s+v

                 end
]]

function mypcall(module, method , ... )
	-- body
	-- 尝试获取模块方法，不存在则报错
	local req_method = ctrl[method]

	if req_method == nil then
	    if is_debug then
	        ngx.status = 404
	        ngx.say("<p style='font-size: 50px'>Error: <span style='color:red'>" .. method .. "()</span> method not found in <span style='color:red'>" .. moduleName .. "</span> lua module !</p>")
	    end
	    ngx.exit(404)
	end

	-- 执行模块方法，报错则显示错误信息，所见即所得，可以追踪lua报错行数
	ret, err = pcall(req_method)

	if ret == false then
	    if is_debug then
	        ngx.status = 404
	        ngx.say("<p style='font-size: 50px'>Error: <span style='color:red'>" .. err .. "</span></p>")
	    else
	        ngx.exit(500)
	    end
	end
end


local cjson = require "cjson"
function requireEx( _lua_file_ )
    local ok, app = pcall(require, _lua_file_)
    if not ok then 
        local serverType = ngx.var.serverType;
        local res = {code=404,st = serverType, msg="the resources is not found or load err ! ".._lua_file_} 
        ngx.log(ngx.ERR,app)
        if serverType == '1' then 
            ngx.say(cjson.encode(res))
            ngx.exit(200)
            -- ngx.eof()
        elseif serverType == '2' then
            ngx.redirect("/403.html") 
            ngx.exit(200)
            -- ngx.eof()
        else  
            ngx.say(cjson.encode(res))
            ngx.exit(200)
            -- ngx.eof()
        end 
    else
        return app
    end
end
 --[[
-- 函数返回多个值的时候需要将多个返回值 合并为一个表返回!!!!!!!!!!
-- example
	 local MyClazz = {
	    VERSION = "1.0.0.1"
	}
	MyClazz.version = function ( _str )
	    -- body
	    -- local aa = ""..nil
	    ngx.say(MyClazz.VERSION)
	      ngx.say(_str)
	      return 1,2
	end

	local a1,a2 = pActionCall(MyClazz,testAction,'1234') 

 ]]
function pcallAction( _module, _method , ... ) 
	local req_method = _module[_method] 
	local msg_t
	if not req_method then
		local serverType = ngx.var.serverType; 
		msg_t = {code=404,st = serverType, msg = "the function is not found! class:" .. ngx.var.clazz.." action:".. _method}  
	else
		-- pcall执行action函数不会有效值,值已经通过ngx.say 或者 print 执行 
		local ok, res = pcall(req_method, ... )  
	    if not ok then 
	        local serverType = ngx.var.serverType;
	        local actionName = ngx.var.server
	        msg_t = {code=404,st = serverType, msg = "the action has error! ".. ngx.var.clazz.." action:".. _method} 
	        ngx.log(ngx.ERR,res)
	    else 
	    	-- 返回用户 需要的数据结果
	    	ngx.say(res)
	    	return true,"success"
	    end 
	end 

    if serverType == '2' then
            ngx.redirect("/404.html") 
            -- ngx.exit(200)
            ngx.eof() 
        else  
            ngx.say(cjson.encode(msg_t))
            -- ngx.exit(200)
            ngx.eof()
        end 
    return false, msg_t.msg
end


-- 打印错误信息
local function __TRACKBACK__(errmsg)
    local track_text = debug.traceback(tostring(errmsg), 6);
    ngx.log(ngx.ERR, "---------------------------------------- TRACKBACK ----------------------------------------");
    ngx.log(ngx.ERR, track_text, "LUA ERROR");
    ngx.log(ngx.ERR, "---------------------------------------- TRACKBACK ----------------------------------------");
    local exception_text = "LUA EXCEPTION\n" .. track_text;
    return errmsg;
end


function requireExx( _lua_file_ )
    -- local ok, app = xpcall(require, _lua_file_)
    local ok , app = xpcall(require , __TRACKBACK__, _lua_file_) 
    if not ok then 
        local serverType = ngx.var.serverType;
        local res = {code=404,st = serverType, msg="the resources is not found or load err ! ".._lua_file_}

        if serverType == '1' then 
            ngx.say(cjson.encode(res))
            ngx.exit(200)
            -- ngx.eof()
        elseif serverType == '2' then
            ngx.redirect("/403.html") 
            ngx.exit(200)
            -- ngx.eof()
        else  
            ngx.say(cjson.encode(res))
            ngx.exit(200)
            -- ngx.eof()
        end 
    else
        return app
    end
end



function xcallAction( _module, _method , ... )
 local req_method = _module[_method] 
	local msg_t
	if not req_method then
		local serverType = ngx.var.serverType; 
		msg_t = {code=404,st = serverType, msg = "the function is not found! class:" .. ngx.var.clazz.." action:".. _method}  
	else
		-- pcall执行action函数不会有效值,值已经通过ngx.say 或者 print 执行
		-- local ok, res = pcall(req_method, ... ) 
		local ok , res = xpcall(req_method , __TRACKBACK__, ...) 
	    if not ok then 
	        local serverType = ngx.var.serverType;
	        local actionName = ngx.var.server
	        msg_t = {code=404,st = serverType, msg = "the action has error! ".. ngx.var.clazz.." action:".. _method}  
	    else
	    	ngx.say(res)
	    	return true,"success"
	    end
	   
	end 
    if serverType == '2' then
            ngx.redirect("/404.html") 
            -- ngx.exit(200)
            ngx.eof() 
        else  
            ngx.say(cjson.encode(msg_t))
            -- ngx.exit(200)
            ngx.eof()
        end 
    return false,msg_t.msg
end
 
