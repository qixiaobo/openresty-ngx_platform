--[[
	对查询出来的结果(二元table)做操作的工具类
]]
local cjson = require "cjson"

local _M = {}

_M._VERSION = '0.01'            
local mt = { __index = _M }                    

function _M.new()
    return setmetatable({}, mt)    
end




--[[
	从table中获取第几个字段的key，同排序一样，要纯数字或者纯字符串才能使用，我们先假设它是纯的
	由于本方法是针对left_join_add的，又由于在使用的地方，table是一个只有一个键值对的table,所以决定把方法简写
]]
function getKeyByIndex(tab)
	if type(tab)~="table" then 
		return {}
	end
	for k,v in pairs(tab) do 
		return k
	end
end

--[[
	从table中根据value取key的,如果value都一样的话，就返回第一个value的key，适用范围不大,但是这里是给rule_tab使用的，所以够了
]]
function getKeyByValue(tab,val)
	if type(tab)~="table" then 
		return {}
	end
	for k,v in pairs(tab) do
		if v==val then 
			return k
		end
	end
	return {}
end

--[[
	传入一个string，如果table中的第一个key与这个string相等，那么返回key，否则返回空table
]]
function getKeyByKeyString(tab,str)
	if type(tab)~="table" then 
		return {}
	end
	for k,v in pairs(tab) do
		if k == str then 
			return k
		end
	end
	return {}
end

function getTableCount(tab)
	local count = 0
	for k,v in pairs(tab) do
	    count = count + 1
	end
	return count
end

--给外面用的
function _M.returnTabCount(tab)
	local count = 0
	for k,v in pairs(tab) do
	    count = count + 1
	end
	return count
end
--连接中的替换，比如，sex=1,sex=2的替换成sex="男",sex="女"
--经过长时间的思考验证，如果在数据量大的情况下，是没有办法同时对多个字段进行替换的，因此决定将rule_tab修改成一维数组
--[[
	@param dataSource 查询出来的数据源
	@param key 关键字段 为string
	@param rule_tab 规则的table {["1"]="男",["2"]="女"} 这样的，key为原来的字段值，value为要替换的字段值   
	已验证，可行
]]
function _M.left_join_replace(dataSource,key,rule_tab)
	for ds_index,ds_value in pairs(dataSource) do
		for k,v in pairs(ds_value) do  --这里对单条数据进行操作
			if k == key then   --如果一条数据中的key就是关键字段,那么接下来的操作就是在rule_tab中找键与v相等的，然后把值替换
				for a,b in pairs(rule_tab) do
					if v==a then --这个就是我们要替换掉的字段了
						ds_value[k]=rule_tab[a]
					end
				end
			end
		end
	end
	return dataSource
end

--[[
	给如果table中有符合条件关键字段，那么在这条语句后面添加一个或多个键值对
	@param dataSource 查询出来的数据源
	@param key 关键字段 为string
	@param rule_tab 规则的table {["1"]={["nick"]="美女"},["2"]={["nick"]="帅哥"}} 这样的，key为原来的字段值，value为要替换的字段值  
	@param default 默认值  只是值
	-- table.insert(ds_value,{insert_key=b[insert_key]})
	已验证，可行
]]
function _M.left_join_add(dataSource,key,rule_tab,default)
	if not default then --先判断有无默认值比在赋值事判断有无默认值要高效得多
		for ds_key,ds_value in pairs(dataSource) do
			for k,v in pairs(ds_value)do
				if k == key then  -- 这条数据就是我们需要增添字段的数据
					------------------------table插入就在这里
					local insert_tab = {}
					for a,b in pairs(rule_tab) do
						local tmpKey = getKeyByIndex(b)
						--repeat 
							if v == a then --如果该条数据的key是我们的关键字，那么直接插入key,value
								local insert_value = b[tmpKey]
								insert_tab[tmpKey] = insert_value  --这里的b是{["nick"]="美女"},即一个被替换值只能被一个值替换
								break
							else  --插入默认值，如果没有默认值，就插入一个空字符串""
								insert_tab[tmpKey] = ""
							end
						--until true
					end
					------------------------table插入数据在这里
					table.merge(ds_value, insert_tab)
				end
			end
		end
		return dataSource
	else
		for ds_key,ds_value in pairs(dataSource) do
			for k,v in pairs(ds_value)do
				if k == key then  -- 这条数据就是我们需要增添字段的数据
					------------------------table插入就在这里
					local insert_tab={}
					for a,b in pairs(rule_tab) do
						local tmpKey = getKeyByIndex(b)
						--repeat 
							if v==a then --如果该条数据的key是我们的关键字，那么直接插入key,value
								local insert_value = b[tmpKey]
								insert_tab[tmpKey] = insert_value  --这里的b是{["nick"]="美女"},即一个被替换值只能被一个值替换
								break
							else  --插入默认值，如果没有默认值，就插入一个空字符串""
								insert_tab[tmpKey]=default
							end
						--until true
					end
					------------------------table插入数据在这里
					table.merge(ds_value, insert_tab)
				end
			end
		end
		return dataSource
	end
end

--[[
	象数据库一样使用limit
]]
function _M.limit(dataSource,index,pageSize)
	if type(dataSource)~="table" then 
		return {}
	end
	local start_index = tonumber(index+1)  
	local end_index = start_index+tonumber(pageSize)-1  
	local len=tonumber(getTableCount(dataSource))
	if start_index<=len+1 then 
		--分为两种情况，一种是end_index在len里面，一种是end_index在len外面
		if end_index>len then --在外面
			end_index=len
		end
	else
		--因为做了pager，页数和limit都是有限制的，所以其实不存在这种问题，
		return {}
	end
	local result_tab={}
	
	for i=start_index,end_index,1 do  --因为数据库中可以从0开始，并且2,5是不包括2的，为了和数据库一样，所以在start_index加个1
		local temp_tab=dataSource[i]
		table.insert(result_tab,temp_tab)
		-- table.merge(result_tab,temp_tab)
	end
	return result_tab
end

--[[
	像Union all 一样把所得的数据源合并起来
	因为不晓得数据源有几个，所以使用不定参数，使用不定参数时，lua会把函数的参数放在args表中
	@param 参数为基本的从数据库中查出来的table数组
]]
function _M.union_all(...)
	local result_tab = {}
	for k,v in pairs({...}) do --每个v代表的是capture中获取出来的数据源，二维数组
		for a,b in pairs(v) do  --每个b代表的是一条数据
			table.insert(result_tab,b)
		end
	end
	return result_tab
end

--[[
	排序
	lua自带的排序sort只能是针对纯numbern或者纯string的一元table进行排序，但数据库的要求是对数据列进行排序，所以只能自己再写个方法
	@param dataSource  数据源
	@param condition_tab 条件的table,{["updata"]="desc",["age"]="asc"} key是关键字段名，value是排序方式
]]
function _M.order_by(dataSource,condition_tab)
	
end


--[[
	分组
	
	如果是按照两个关键字来分组，按顺序
	@param dataSource 数据源
	@param key_tab 关键字段的table{"sex","age"}  --这里的关键点就是，不知道key_tab中的关键字段个数，一般来说是一个或者两个，最多三个，超过三个的还没见到过，但是不排除这种可能性
	if a~=a` or b~=b` or c~=c` then  这样才能判断new_tab中是否插入 新数据 在这里我做个
		local count=0
		for k,v in pairs(key_tab) do 
			if 不成立 then 
				table.insert(new_tab)
				count=1
				break  --这个是退出字段循环
			end
		end
		if count=1 then   
			break   --这个是退出new_tab 的循环
		end
			
	@param sum_key_tab 分组求和是很常见的，sum_key_tab={"gift_value"="user_income","XXXX"="xxxx"} 前面是求和的关键字段，后面是别名 sum_key_tab对应的数据必须是number，
					   就算不是number也必须可以tonumber，否则无法相加
]]
function _M.group_by(dataSource,key_tab,sum_key_tab)
	if type(dataSource) ~= "table" then 
		return {}
	end
	if tonumber(getTableCount(dataSource)) == 0 then
		return {}
	end

	
		local new_tab = {}
		local insert_index = dataSource[1]  --将dataSource的第一条数据给new_tab，使之有个比较的模板 
		new_tab = {insert_index}  --  new_tab=[{"user_code_fk":"wj_user_1","sex":"1","nickname":"兔儿"}] 的table形式

		for ds_key,ds_value in pairs(dataSource) do
			local clum_count = 0 -- 判断要不要将这条数据插入new_tab表中的重要依据，如果clum_count=key_tab的长度乘上new_tab的长度，那么需要将此条数据插入new_tab中
			for new_key,new_value in pairs(new_tab) do
				local count = 0 --如果所有字段值都不一样，才进入下一个判断
				for k,v in pairs(key_tab) do 
					local tmpKey = ""..v
					if new_value[tmpKey] == ds_value[tmpKey] then --说明这条数据是肯定在new_tab中，其他的情况都无法肯定，只好用排除法
						count=count+1
					end
				end
				if count==tonumber(getTableCount(key_tab)) then --一条数据中，关键字的所有字段值都相同
					--肯定在new_tab了，就不用继续了直接退出循环节省资源
					break
				else
					--有可能在，有可能不在，这时需要对整个new_tab循环进行判断
					clum_count=clum_count+1   --如果循环了整个new_tab表，都是有可能在，有可能不在的话，那一定不在
				end
			end
			if clum_count==tonumber(getTableCount(new_tab)) then
				table.insert(new_tab,ds_value)
				
			end
		end

		-- ngx.log(ngx.ERR,"让我们看看new_tab的值"..cjson.encode(new_tab))
	--在得到的new_tab上对数据进行求和操作
	if not sum_key_tab then  
		return new_tab 
	else
		-- local new_tab_temp=new_tab
		-- 这一步按组组装内容
		local array_tab={} --按组区分数据
		for new_key,new_value in pairs(new_tab) do --因为这次是以new_tab为标准，所以new_tab放在外面，for循环完了，也就结束了
			local middle_tab={}  --存放组内数据
			for ds_key,ds_value in pairs(dataSource) do
				local count=0
				for k,v in pairs(key_tab) do
					local tempKey = ""..v
					if ds_value[tempKey] == new_value[tempKey] then --如果每个关键字段的值都相等，可以把ds_value这条数据看成是new_value一组的,这条数据中对应的字段要求和并记录
						count=count+1
					end
				end
				if count==tonumber(getTableCount(key_tab)) then --把符合条件的ds_value组装成table，table
					table.insert(middle_tab,ds_value)
				end
			end
			table.insert(array_tab,middle_tab)
		end

		ngx.log(ngx.ERR,"让我们看看array_tab的值"..cjson.encode(array_tab))
		--然后再在array_tab中根据key取值求和
		local element_tab={}
		for a,b in pairs(sum_key_tab) do -- sum_key_tab={"gift_value"="user_income","XXXX"="xxxx"}
			
			local ele_tab_temp={}
			for i=1,tonumber(getTableCount(array_tab)),1 do  -- array_tab 指所有的数据包括N个分组，以及分组里面的table数组
				local temp_sum=0 --这里是指其中一个组的关键字a对应的字段的总和, 
				local tem_tab=array_tab[i]   -- 每个组的所有数据，一个temp就是一个组
				for k,v in pairs(tem_tab) do  --组内循环,v就是一个table
					local tempKey = ""..a
					for x,y in pairs(v) do
						if x==tempKey then  --如果两个字段名相等，说明这就是我们需要累加的字段了
							temp_sum=temp_sum+tonumber(v[tempKey])
						end
					end
					
				end
				local aa={}
				aa[""..b]=temp_sum
				table.merge(new_tab[i],aa)
			end
		end
		return new_tab
	end
	
end


return _M 