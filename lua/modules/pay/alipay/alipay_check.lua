

local cjson = require "cjson"
ngx.log(ngx.ERR,"--------",cjson.encode(ngx.req.get_uri_args()))