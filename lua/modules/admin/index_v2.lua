local sign = require "admin.auth.sign_in"
local cjson  = require "cjson" 
 
 --[[

    首先判断有无token,没有直接退出

 --]]    

local template = require "resty.template"

-- 定义lua session 状态数据关联
 local adminUser = sign.getFiled("admin_name")
ngx.log(ngx.ERR,"admin-----",adminUser)
template.render("admin/index_center.html", { })