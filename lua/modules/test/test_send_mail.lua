-- local mail = require "resty.mail"

-- local mailer, err = mail.new({
--   host = "smtp.126.com",
--   port = 25,
--   starttls = true,
--   username = "dongyf90@126.com",
--   password = "dongyf90",
-- })

-- local ok, err = mailer:send({
--   from = "dongyf90@126.com",
--   to = { "652493771@qq.com" },
--   --cc = { "leo@example.com", "Raphael <raph@example.com>", "donatello@example.com" },
--   subject = "Alex is here!!!!!!!!!!!!!",
--   text = "test from other email.",
--   --html = "<h1>There's pizza in the sewer.</h1>",
--   -- attachments = {
--   --   {
--   --     filename = "toppings.txt",
--   --     content_type = "text/plain",
--   --     content = "1. Cheese\n2. Pepperoni",
--   --   },
--   -- },
-- })

-- if not ok then
--   ngx.say("send mail fail. err: "..err)
-- else
--   ngx.say("send mail success.")
-- end

local mail = require "common.msg.email"

local ok, err = mail.send_simple_email("1251834951@qq.com", {"652493771@qq.com"}, nil, "test gmail", "This is a test mail!")
ngx.say(err)

