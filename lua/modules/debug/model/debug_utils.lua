local _M = {}
_M.VERSION = "1.0"

_M.debug_args = function ( arg_tbl )
	for k, v in pairs(arg_tbl) do 
		ngx.log(ngx.ERR, "key: "..k.." val: "..v)
    	ngx.say("key: "..k.." val: "..v)
   	end 
end

return _M