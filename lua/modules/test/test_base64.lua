local json = [[{
	'test' : "test",
	'last' : 'last',
	'first': 'first'
}]]

ngx.say(json)

local code = ngx.encode_base64(json)
ngx.say('64code: '..code)
ngx.say('str: '..ngx.decode_base64(code))