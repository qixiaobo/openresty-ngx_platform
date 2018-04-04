--local uuid_help = require "common.uuid_help"
local jit_uuid = require 'resty.jit-uuid'
ngx.say(os.time().." | "..ngx.time())
math.randomseed(tostring(os.time()):reverse():sub(1, 7)) --设置时间种子
 -- ngx.say(math.random(1,100))
--jit_uuid.seed()

--ngx.sleep()
--ngx.say(uuid_help.get())
-- ngx.say(uuid_help:get64())
--ngx.say(ngx.time())
local  num = math.random(1,100)
ngx.say(num)
local seed = num + ngx.time()
ngx.say(seed)
jit_uuid.seed(seed)
ngx.say(jit_uuid.generate_v4())