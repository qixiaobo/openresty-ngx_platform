--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:alipay_return.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  支付宝pc 页面充值调用成功返回地址
--]]
 
local request_help = require "common.request_help"
local cjson = require "cjson"

local args = request_help.get_all_args()

ngx.log(ngx.ERR,"return _data :",cjson.encode(args))
-- 判断结果是否正确
--[[
 {
 "timestamp":"2017-12-17 10:58:29",
 "method":"alipay.trade.page.pay.return",
 "sign":"R3SbaF\/pKolwiQkMLrBq+RFf1oSEaj535VYa7iHyewML2\/j44G7Liz\/wduidRdLs8CaczMCPAhkQTlUWfOy4WEK44d1m9Nbr6xyv6Qjso8mHgTvIMFwzJ00T+C2QZFBCoiNvAY0pOoCOSSAVfS\/fzdwpQeAYQHRgtNQgKq5d4BXu5ZYQDhZdAsMYFXZB\/YLM1+1sVlp9xTwPbDTAZjJifOiRyskaODlNJS7FsgB2EKNYlw4+fc0AcBtQxnPJmj0fnKQEVWrQVgFzLI1pC83RaJXbFSoY\/wgLCMm+rwIjimXDH2uHdKN5\/BNrDeMJIb\/qZha9\/zXZTRLeuYZinzFZPw==",
 "app_id":"2017121100557906",
 "trade_no":"2017121721001004970265915559",
 "sign_type":"RSA2",
 "version":"1.0",
 "out_trade_no":"201712171058105990541800008",
 "charset":"utf-8",
 "total_amount":"0.10",
 "seller_id":"2088821127488751",
 "auth_app_id":"2017121100557906"
 }

]] 
-- 获得交易编号,该编号用于系统支付存储
-- 验证成功之后,将最终的支付数据写入确认更新到用户账户
local out_trade_no = args.out_trade_no
local return_data = table.clone(args)
return_data.sign = nil

ngx.redirect("/pay/pay_test.html")
-- 验证确认订单是否正确


-- 在异步回调也将进行一次验证,验证成功之后将数据通知服务器


-- 需要获得当前调用的信息属于什么产品应用,pc, 手机, 或app支付的发起
