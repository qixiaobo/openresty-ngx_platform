
--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:add_files.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  系统标准的玩家接口, 其他游戏的用户集成该对象可以获得该类的基础函数
--]]
local mysql_db = require "common.db.db_mysql" 
local mysql_help = require "common.db.mysql_help"
local redis_help = require "common.db.redis_help"
local bit_help = require "common.bit_help" 
local uuid_help = require "common.uuid_help"
local online_union_help = require "common.online_union_help"
local timer_help = require "common.timer_help"
local resty_lock = require "resty.lock"


local _M = {
     --用户id
    player_no = "",
    --昵称
    name = "",
    --1男2女，默认男
    sex  = 1,
    --头像
    icon = "",
    --是否是虚拟玩家
    is_virtual_player = nil
}
_M._VERSION = '0.01'  
_M._CLAZZ = "game.base.player"          
_M. __index = _M   


--[[
初始化 主要用于用户ws登陆时候的用户初始化
-- @param _user_no 玩家编号
-- @param _user_token 玩家token
-- @param is_virtual_player 是否为虚拟玩家
]]
function _M:new(_user_no,_user_token,is_virtual_player)
    local  player = setmetatable({}, self);
   
    -- 判断用户账户信息是否正确
    player.online_uuion = uuid_help:get64() 

    player.is_virtual_player = is_virtual_player
    
    -- 权限与登录管理
 
    return player
end

--[[
    根据属性直接初始化用户数据,该函数内部调用,不得用于用户端
-- @param _user_prop 玩家属性 
-- @return player 实例对象
]]

function _M:new2(_user_prop)
    if not _user_prop then return nil end
    local  player = setmetatable(_user_prop, self);
    if not player.online_uuion then
        player.online_uuion = uuid_help:get64() 
    end

    return player
end

function _M.create_redis_cli()
-- 超过一定时间未获取,就该优化该代码了

    while true do
        local redis_cli = redis_help:new();
        if redis_cli then 
            return redis_cli
        else
            ngx.sleep(0.1)
        end 
    end

end

function _M.redis_publish(_redis_cli,_channel_name,_msg_data)
    -- redis_cli:publish(channel_name, cjson.encode(_process))
    while true do
        local res,err = _redis_cli:publish(_channel_name,_msg_data)
        if res and res ~= 0 then
            return true 
        else
            ngx.sleep(0.1)
        end

    end

end 

--[[
-- subscribe_channel  -- 订阅新频道 收到指令执行该操作 在用户的redis客户端完成长链接订阅
-- example 
     
-- @param _self 当前用户对象
-- @param _channel_name 订阅频道
-- @param _process 协议结构表  
--]]
_M.subscribe_channel = function (_self, _channel_name )
    -- body
    -- 1, 基础判断,参数和属性是否正确 
    if not _channel_name or not _self.redis_cli_msg then  
        return nil
    end
    
    local res, err = _self.redis_cli_msg:subscribe(_channel_name)
    if not res and err ~= "socket busy reading" then
        ngx.log(ngx.ERR,"subscribe err:",err,", channel_name is ",_channel_name,".")
        return nil 
    end  
   
    _self.subscript_map[_channel_name] = _channel_name
    return true
end


--[[
-- on_unsubscribe_new_channel  -- 取消订阅
-- example 
    
    UNSUBSCRIBE_NEW_CHANNEL = 0x16,
    -- {process_type=PROCESS_TYPE.UNSUBSCRIBE_NEW_CHANNEL,  user_code="xxx",  channel_name="xxxx"}

-- @param _self 当前用户对象
-- @param _channel_name 订阅频道
-- @param _process 协议结构表  
--]]
_M.unsubscribe_channel = function (_self, _channel_name )
    -- body
        -- 1, 基础判断,参数和属性是否正确 
    if not _channel_name or not _self.redis_cli_msg then  
        return nil
    end

    if _self.subscript_map[_channel_name] then
        return nil
    end

    local res, err = _self.redis_cli_msg:unsubscribe(_channel_name)
    if not res and err ~= "socket busy reading" then
        ngx.log(ngx.ERR,"unsubscribe err:",err,", channel_name is ",_channel_name,".",_channel_name == "")
        return nil 
    end  
 
    _self.subscript_map[_channel_name] = _channel_name 
    return true  
end

return _M
