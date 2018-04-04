--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:workflow.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  lua文件帮助文件的封装
--]]


--[[
-- -- 遍历node-node表,完成关系级联
--  工作流初始化函数,函数需要两个入参,具体模型可查看例子中的模板格式
--  task_code 表示该初始化一个工作流之后,该工作流属于哪一个任务
--  task_temp 任务模板格式,结构如下
--  makeNodeCode 用于生成nodecode唯一编码的lua函数
]]
-- 0 发起，1 结束，2 审核，3 工作，4 通知，默认节点为发起 ,
-- -- coefficient 操作人存在系数，由其他系统得出,没有的关键字表示默认1.0
 

local TASK_NOTE_TYPE={
    NODE_BEGIN = 0,   --  当前任务流 start
    NODE_END = 1,     --  当前任务流 end
    NODE_TIME = 2,    --  时间定时任务
    NODE_REVIEW = 3,  --  审核类型
    NODE_WORK = 4,    --  工作执行类型
    NODE_NOTE = 5,    --  通知类型
}

local TASK_NOTE_STATUS={
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

--[[
-- 可能忽略的关键字主要有weight 和 revert 即权重和滚回, 权重默认为1.0,权重为负时,执行滚回操作, 其他关键字表示必须需要存在一个或者多个

--  1,  模版编辑  每个节点都将绑定节点,该节点可以绑定一个通知子节点,只有note节点 和 end节点才可以没有后续节点
--  2,  节点绑定制定用户, 当节点
--

local node_temp={
    node_id = 0_1, node_name="任务1", parent_node=nil
    }
local sub_node = {
    {node_id=1,node_name='开始',node_type=TASK_NOTE_TYPE.NODE_BEGIN},
    {node_id=2,node_name='工作1',last_nodes={{node_id=1}},node_type=TASK_NOTE_TYPE.NODE_WORK},
    {node_id=3,node_name='审核1_1',last_nodes={{node_id=2}},node_type=TASK_NOTE_TYPE.NODE_REVIEW},
    {node_id=4,node_name='审核1_2',last_nodes={{node_id=2}},node_type=TASK_NOTE_TYPE.NODE_REVIEW},
    {node_id=5,node_name='工作2',last_nodes={{node_id=3,weight=0.8},{node_id=4,weight=0.2}},
            node_type=TASK_NOTE_TYPE.NODE_WORK,revert = true},
    {node_id=6,node_name='审核2',last_nodes={{node_id=5}},node_type=TASK_NOTE_TYPE.NODE_REVIEW, note_revert = NODE_REVIEW.REVERT_ERR},
    {node_id=7,node_name='工作3',last_nodes={{node_id=6}},node_type=TASK_NOTE_TYPE.NODE_WORK},
    {node_id=8,node_name='审核3',last_nodes={{node_id=7}},node_type=TASK_NOTE_TYPE.NODE_REVIEW}, -- 如果note_revert 为nil 表示不操作 直接下一步骤
    {node_id=9,node_name='结束',last_nodes={{node_id=8}},node_type=TASK_NOTE_TYPE.NODE_END},
}
--  系统需要提供一个函数供本函数调用,即node_code  生成的回调函数
-- ]]--

local _M = {}
_M.__index = _M

function _M.init_task_node(task_temp,task_code,makeNodeCode)
    local len = table.getn(task_temp);
    local node_resultTable={};
    local hash_table={};
    local nn_resultTable={};
    local nn_index=1;
  
    --遍历task_temp 生成需要创建的表结构
    for i=1,len,1 do
        local _node_id=task_temp[i].node_id;
        local _node_name=task_temp[i].node_name;
        local _last_nodes=task_temp[i].last_nodes;
        local _node_type=task_temp[i].note_type;
        local _node_code=makeNodeCode();
        -- 创建需要创建的node 记录
        node_resultTable[i]={node_code=_node_code,
            node_name=_node_name,
            node_type=_node_type,
            task_code=task_code,
        }
        hash_table[''.._node_id]=node_resultTable[i];
        if _last_nodes then
            -- 创建node数组
            local nnlen = table.getn(_last_nodes);

            for j=1,nnlen,1 do
                nn_resultTable[nn_index]={
                    task_last_code='',
                    task_next_code=_node_code,
                    node_temp_last=_last_nodes[j].node_id;
                }
                if(_last_nodes[j].weight) then
                    nn_resultTable[nn_index].weight=_last_nodes[j].weight;
                else
                    nn_resultTable[nn_index].weight=1.0;
                end
                nn_index = nn_index+1;
            end

        end
    end
    --[[  遍历node-node表,完成关系级联 ]]--
    local iLen=table.getn(nn_resultTable);

    while(iLen>0) do
        local last_temp_id= nn_resultTable[iLen].node_temp_last;
        if(hash_table[''..last_temp_id]) then
            nn_resultTable[iLen].task_last_code=hash_table[''..last_temp_id].node_code;
        else
            table.remove(nn_resultTable,iLen);
        end
        iLen = iLen-1;
    end
    return node_resultTable, nn_resultTable;

end

--[[
    写入数据库
]]
--[[
    总工程
        --子1级工程a
            --子2级工程---------
        --子1级工程b
            --task1
            --task2
            --task3
                --node1--node2--node3--node4
    
    

    工程管理 分为总工程, 子工程, 工程进行任务分解, 任务存在前后关系和状态,
    任务下一级为节点 也成为工序, 任务默认包含开始节点和结束节点(该节点由任务负责人激活和确认,以此来激活后续工作以及工序的执行是否符合,
        如果该工序只有默认节点,说明该任务只有自己的状态,由任务执行者直接进行状态处理,即任务开始,任务完成,同样的存在任务完成也存在项目管理者进行任务的认可和判断
        所以任务,节点都存在上一级负责人的打分和判断是否执行正确)
]]



return _M