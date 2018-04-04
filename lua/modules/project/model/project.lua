--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:project.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  工程管理相关,工程包含多级工程,通过工程的任务流形成工程-任务-工序节点三级结构
--]]

local _M = {
	
}


--[[
-- add_project 添加工程,管理员添加工程信息,工程属于个人或者企业对象,通过唯一code约定 
--  
-- example 
   local _project = {
		project_code="", --  系统uuid生成
		project_name="工程1",
		parent_code="",
		owner_code ="",
		project_info="",
   }
    local res = ProjectDao.add_project(user)

-- @param  _project 工程基础属性 
-- @return  插入结果 或者 nil 代表错误
--]]
_M.add_project = function ( _project )
	-- body


end


--[[
-- update_project 修改工程各种属性字段,该类字段主要涉及工程名称,工程基础信息,工程状态
--  
-- example 
   local _project = {
		project_code="", --  系统uuid生成
		project_name="工程1",
		parent_code="",
		owner_code ="",
		project_info="",
   }
    local res = ProjectDao.update_project(user)

-- @param  _project 工程基础属性 
-- @return  插入结果 或者 nil 代表错误
--]]
_M.update_project = function ( _project )
	-- body


end



--[[
-- find_project 查询工程,根据输入的关键字段进行查询 
-- 查询通过工程状态进行查询,查询之后将会根据工作流将可以对外的信息展示出来
-- example 
   local _project = {
		project_code="", --  系统uuid生成
		project_name="工程1",
		parent_code="",
		owner_code ="",
		project_info="",
   }
    local res = ProjectDao.find_project(user)

-- @param  _project 工程基础属性 
-- @return  插入结果 或者 nil 代表错误
--]]
_M.find_project = function ( _project )
	-- body


end





return _M