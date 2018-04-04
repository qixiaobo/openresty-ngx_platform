local session = require "resty.session".open()
local name = session.data.name or "Anonymous"
ngx.say("name: "..name)

ngx.say("work id: "..ngx.worker.id())