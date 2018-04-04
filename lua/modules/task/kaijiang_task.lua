--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:kaijiang_task.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  开奖任务定时器,系统定时器主要用于到时间的任务奖项生成
--]]

local cjson = require "cjson"
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local uuid_help = require "common.uuid_help" 
local incr_help = require "common.incr_help"
local redis_queue_help = require "common.db.redis_queue_help"
 
local random_help = require "common.random_help"

local redis_queue_help = require "common.db.redis_queue_help"
-- local order_dao = require "e_commerce.model.order_dao"
local mail_dao = require "messages.model.mail_dao"

local _M = {}




_M.kaijiang_task1 = function() 
	-- 1 查询开奖任务------------------------------------------------
  	local mysql_cli = mysql_db:new();
    if not mysql_cli then 
    	ngx.log(ngx.ERR,"new mysql db error .");
        return nil,1041;
    end 	

	local str = string.format([[
		select t_release_activities.* from t_release_activities where start_time <= '%s' and activities_status = 1 ;
		]],ngx.localtime())
	
	-- local str = string.format([[
	-- select * from t_release_activities ;
	-- ]]) 
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	    
	    return nil,errcode;
	end 
    -- 1 查询开奖任务------------------------------------------------
 	-- if #res ~= 0 then ngx.log(ngx.ERR,"--------------- 开奖任务执行") end
    -- 2 执行开奖任务------------------------------------------------
    for i=1,#res do
    	-- 搜索参与流水
    	local str = string.format("select * from t_activity_partake_tf where activity_id_fk = %d;",res[i].id)
    	local res1, err, errcode, sqlstate = mysql_cli:query(str) 
		if not res1 then
		    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
		 
		elseif #res1 == res["raise_the_number"] then
		    --读取用户列表 进行随机计算
		    local index = math.random(1,res[i].raise_the_number)
		    local lucker = res1[index]
		    -- 自动发起订单申请  
	       local res_tr, err, errcode, sqlstate = mysql_cli:query("START TRANSACTION;") 
		    if not res_tr then
		        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
		    end   

		    local str_tf = mysql_help.update_help("t_activity_partake_tf",{status=1},{id_pk=lucker.id_pk})
		    local res_tf, err, errcode, sqlstate = mysql_cli:query(str_tf) 
			if not res_tf then
				 mysql_cli:query("ROLLBACK;") 
		    	ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
		    end

		    local str_ac = mysql_help.update_help("t_release_activities",{activities_status = 2},{id=res[i].id})
		    local res_ac, err, errcode, sqlstate = mysql_cli:query(str_ac) 
			if not res_ac then
				 mysql_cli:query("ROLLBACK;") 
		    	ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
		    end
 
	     	local res_co, err, errcode, sqlstate = mysql_cli:query("commit;") 
		    if not res_co then
		        mysql_cli:query("ROLLBACK;") 
		        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");  
		    end  
		    -- 系统通知
		    local _mail = {
		    	user_code_fk = lucker.user_code_fk,
		    	content = string.format("您参与的众筹活动【%s】拔得头筹,请登陆界面进行领取!",res[i].activity_name)
			}
		    mail_dao.add_mail(_mail)


		end  
    end
    -- 2 执行询开奖任务------------------------------------------------
 
    return true
end



_M.kaijiang_task = function() 
	-- 1 查询开奖任务------------------------------------------------
  	local mysql_cli = mysql_db:new();
    if not mysql_cli then 
    	ngx.log(ngx.ERR,"new mysql db error .");
        return nil,1041;
    end 	

	local str = string.format([[
		select t_release_activities.* from t_release_activities where end_time <= '%s' and activities_status = 1 ;
		]],ngx.localtime())
	
	-- local str = string.format([[
	-- select * from t_release_activities ;
	-- ]]) 
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    -- 1 查询开奖任务------------------------------------------------
 	-- if #res ~= 0 then ngx.log(ngx.ERR,"--------------- 开奖任务执行") end
    -- 2 执行开奖任务------------------------------------------------
    for i=1,#res do
    	-- 搜索参与流水
    	local str = string.format("select * from t_activity_partake_tf where activity_id_fk = %d;",res[i].id)
    	local res1, err, errcode, sqlstate = mysql_cli:query(str) 
		if not res1 then
		    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
		 
		else
		    --读取用户列表 进行随机计算
		    local index = math.random(1,res[i].raise_the_number)
		    local lucker = res1[index]
		    -- 自动发起订单申请  
	       local res_tr, err, errcode, sqlstate = mysql_cli:query("START TRANSACTION;") 
		    if not res_tr then
		        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. "."); 
		    end   

		    local str_tf = mysql_help.update_help("t_activity_partake_tf",{status=1},{id_pk=lucker.id_pk})
		    local res_tf, err, errcode, sqlstate = mysql_cli:query(str_tf) 
			if not res_tf then
				 mysql_cli:query("ROLLBACK;") 
		    	ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
		    end

		    local str_ac = mysql_help.update_help("t_release_activities",{activities_status = 2},{id=res[i].id})
		    local res_ac, err, errcode, sqlstate = mysql_cli:query(str_ac) 
			if not res_ac then
				 mysql_cli:query("ROLLBACK;") 
		    	ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
		    end
 
	     	local res_co, err, errcode, sqlstate = mysql_cli:query("commit;") 
		    if not res_co then
		        mysql_cli:query("ROLLBACK;") 
		        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");  
		    end  
		    -- 系统通知
		    local _mail = {
		    	user_code_fk = lucker.user_code_fk,
		    	content = string.format("您参与的众筹活动【】拔得头筹,请登陆界面进行领取!",res[i].activity_name)
			}
		    mail_dao.add_mail(_mail)


		end  
    end
    -- 2 执行询开奖任务------------------------------------------------
 
    return true
end

_M.activity_start_task = function()
	
-- 1 查询开奖任务------------------------------------------------
  	local mysql_cli = mysql_db:new();
    if not mysql_cli then 
    	ngx.log(ngx.ERR,"new mysql db error .");
        return nil,1041;
    end 	

	local str = string.format([[
		select t_release_activities.* from t_release_activities where start_time <= '%s' and activities_status = 0 ;
		]],ngx.localtime())
	
	-- local str = string.format([[
	-- select * from t_release_activities ;
	-- ]]) 
	-- ngx.log(ngx.ERR," ----  ", str)
	local res, err, errcode, sqlstate = mysql_cli:query(str) 
	if not res then
	    ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	     
	    return nil,errcode;
	end 
    -- 1 查询开奖任务------------------------------------------------
 	-- if #res ~= 0 then ngx.log(ngx.ERR,"--------------- 任务开始") end
    -- 2 执行开奖任务------------------------------------------------
    for i=1,#res do
		local str_ac = mysql_help.update_help("t_release_activities",{activities_status = 1},{id=res[i].id})
	    local res_ac, err, errcode, sqlstate = mysql_cli:query(str_ac) 
		if not res_ac then
			 mysql_cli:query("ROLLBACK;") 
	    	ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
	    end 
    end  
    return true
end

_M.activity_task = function()  
	-- 执行定时任务 
	-- local ok,res = pcall(_M.kaijiang_task)
	-- local ok,res = pcall(_M.activity_start_task)

	local redis_cli = redis_help:new()
	if redis_cli then
		redis_cli:expire("system_task_timer",30)   
	end 

	-- 执行完任务之后 进行 二次定时任务开启
	local ok, err = ngx.timer.at(1, _M.activity_task)
	if not ok then
	    ngx.log(ngx.ERR, "failed 活动任务", err) 
	    activity_task()
	end
end
 
  

return _M
