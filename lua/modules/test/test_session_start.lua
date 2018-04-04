local session = require "resty.session".start()

local args = ngx.req.get_uri_args()
local name = args['name']
-- session.data.name = "OpenResty qwqew222eFan"
-- session:save()
if session.present then
	local name = session.data.name or "Anonymous"
	session:save()
	ngx.say("work id: "..ngx.worker.id())
	ngx.say("name: "..name)
	ngx.say("session.id: "..ngx.encode_base64(session.id))
else
	session.data.name = name
	local ok ,msg = session:save()
	if ok then
		ngx.say("save ok. ")
	else
		ngx.say("save fail. msg: "..msg)
	end
	ngx.say("work id: "..ngx.worker.id())
	ngx.say('name: '..session.data.name)
	ngx.say("present: "..(session.present or "nil"))
	ngx.say("session.id: "..ngx.encode_base64(session.id))
end