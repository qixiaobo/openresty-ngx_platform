

 

local TASK_NOTE_TYPE={
    NODE_BEGIN = 0,   --  当前任务流 start
    NODE_END = 1,     --  当前任务流 end
    NODE_TIME = 2,    --  时间定时任务
    NODE_REVIEW = 3,  --  审核类型
    NODE_WORK = 4,    --  工作执行类型
    NODE_NOTE = 5,    --  通知类型
}

local NOTE_STATUS={
    NORMAL = 0x00,  -- 正确
    PAUSE = 0x01,   -- 暂停
    WARNING = 0x02, -- 警告
    ERROR = 0x04,   -- 出错
    FAULT = 0x08,   -- 失败
    SYS_PAUSE = 0xff,   -- 系统进行暂停操作,用户无法进行执行操作
}

--[[
--  节点被执行之后返回状态决定了该节点之间的执行情况,用于节点或者任务之间的连接
-- 下一个节点认为失败的时候对该任务线的操作类型,0 表示不操作, 直接进行下一步 ; 1表示就此失败,停止执行
-- 2表示失败 需要重来,滚回上一步骤,从新执行
-- 默认0不操作 直接进行下一步
]]

local TASK_REVERT={
    REVERT_NO=0,
    REVERT_STOP=1,
    REVERT_AGAIN=2, 
}

local EVENT={
    EXECUTE = 0,    -- 执行操作
    CANCEL = 1,     -- 取消操作
    PAUSE = 2,      -- 暂停操作
}

local nodes = {
    {node_id=1,node_name='开始',node_type=TASK_NOTE_TYPE.NODE_BEGIN},
    {node_id=2,node_name='工作1',last_nodes={{node_id=1}},node_type=TASK_NOTE_TYPE.NODE_WORK},
    {node_id=3,node_name='审核1_1',last_nodes={{node_id=2}},node_type=TASK_NOTE_TYPE.NODE_REVIEW},
    {node_id=4,node_name='审核1_2',last_nodes={{node_id=2}},node_type=TASK_NOTE_TYPE.NODE_REVIEW},
    {node_id=5,node_name='工作2',last_nodes={{node_id=3,weight=0.8},{node_id=4,weight=0.2}},
            node_type=TASK_NOTE_TYPE.NODE_WORK,revert = true},
    {node_id=6,node_name='审核2',last_nodes={{node_id=5}},node_type=TASK_NOTE_TYPE.NODE_REVIEW, note_revert = TASK_REVERT.REVERT_NO},
    {node_id=7,node_name='工作3',last_nodes={{node_id=6}},node_type=TASK_NOTE_TYPE.NODE_WORK},
    {node_id=8,node_name='审核3',last_nodes={{node_id=7}},node_type=TASK_NOTE_TYPE.NODE_REVIEW}, -- 如果note_revert 为nil 表示不操作 直接下一步骤
    {node_id=9,node_name='结束',last_nodes={{node_id=8}},node_type=TASK_NOTE_TYPE.NODE_END},
}


local node1={
    node_id=1,node_name='开始',node_type=TASK_NOTE_TYPE.NODE_BEGIN,
    parent_node = 01,
}

local node2={
    {node_id=2,node_name='工作1',node_type=TASK_NOTE_TYPE.NODE_WORK},
    last_nodes={{node_id=1} },
     parent_node = 01,
}


local cjson = require "cjson"
ngx.say(cjson.encode(nodes))