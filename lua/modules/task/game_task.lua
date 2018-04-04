
local cjson = require("cjson")
local task_manager = require("task.task_manager")
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local api_data_help = require "common.api_data_help"

local redis_help = require "common.db.redis_help"
local uuid_help = require "common.uuid_help" 
local incr_help = require "common.incr_help"
local redis_queue_help = require "common.db.redis_queue_help"
local random_help = require "common.random_help"
-- local order_dao = require "e_commerce.model.order_dao"
local mail_dao = require "messages.model.mail_dao"


local _M = {
}

--[[
    @uri:   
    @brief: 接口，添加单个活动定时任务
]]
function _M.activities_add()
    local args = ngx.req.get_uri_args()
    local id = args[id]
    if not id then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "paramter error", "参数[id]不存在")
    end

    local sql = string.format("SELECT * FROM t_release_activities WHERE id='id';", id)
    local res, err = mysql_db:exec_once(sql);
    if not res then
        return nil, "get activities data failed: " .. err
    end
    if not res[1] then
        return api_data_help(ZS_ERROR_CODE.PARAM_NULL_ERR, "paramter error", string.format("activity [%s] is not exist", id))
    end

    _M.create_activity_task(res)
end

--[[
    @brief: 初始化系统任务
]]
function _M.init()
    _M.init_activities()
end

--[[
    @brief: 初始化活动定时任务
]]
function _M.init_activities()
    local sql = "SELECT * FROM t_release_activities;"
    local res, err = mysql_db:exec_once(sql);
    if not res then
        return nil, "get activities data failed: " .. err
    end
    _M.create_activity_task(res)
    return cjson.encode(res)
end


function _M.create_activity_task(res)
    for i=1, #res do 
        local item = res[i]
        local name = item.id
        if res[i].activity_name then
            name = name .. ":" .. item.activity_name
        end
        local params = item
        if item.activities_status == 0 then
            -- 未开始的活动
            task_manager.new_task(task_manager.TYPE.TASK_TIMED, name, params, _M.activities_start, item.start_time)
        elseif item.activities_status == 1 then
            -- 进行中的活动
            task_manager.new_task(task_manager.TYPE.TASK_TIMED, name, params, _M.activities_end, item.end_time)
        end
    end
end

--[[
    @brief: 开始活动
]]
function _M.activities_start(params)
    ngx.log(ngx.ERR, "====> [TASK HANDLER] start activitiy: " ..  params.id .. "\n")

    -- 更新数据库活动状态，设置为1:活动中
    local sql = string.format("UPDATE t_release_activities SET activities_status='1' WHERE id='%s';", params.id)
    local res, err = mysql_db:exec_once(sql)
    if not res then
        ngx.log(ngx.ERR, "====> [TASK HANDLER] start activitiy failed: database err, " .. err)
    end

    -- 通知在线用户

    return true
end

function _M.activities_end(params)
    ngx.log(ngx.ERR, "====> [TASK HANDLER] end activitiy: " .. params.id .. "\n")

    -- 更新数据库活动状态，设置为2:活动结束
    local sql = string.format("UPDATE t_release_activities SET activities_status='2' WHERE id='%s';", params.id)
    local res, err = mysql_db:exec_once(sql)
    if not res then
        ngx.log(ngx.ERR, "====> [TASK HANDLER] end activitiy failed: database err, " .. err)
        return false
    end

    -- 开奖
    local mysql_cli = mysql_db:new();
    if not mysql_cli then 
    	ngx.log(ngx.ERR, "database error: mysql new failed.");
        return false
    end 

    -- 搜索参与流水
    local str = string.format("select * from t_activity_partake_tf where activity_id_fk = %d;", params.id)
    local res1, err, errcode, sqlstate = mysql_cli:query(str) 
    if not res1 then
        ngx.log(ngx.ERR,"bad result: ".. err.. ": ".. errcode.. ": ".. sqlstate.. ".");
     
    else
        --读取用户列表 进行随机计算
        local index = math.random(1,params.raise_the_number)
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

        local str_ac = mysql_help.update_help("t_release_activities",{activities_status = 2},{id=params.id})
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
            content = string.format("您参与的众筹活动【】拔得头筹,请登陆界面进行领取!",params.activity_name)
        }
        mail_dao.add_mail(_mail)
    end 
    return true
end


return _M