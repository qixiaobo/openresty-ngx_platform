--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:user_info.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  获得用户基础信息,基础信息修改等
--]]

local cjson = require "cjson"
local regex = require "resty.core.regex"
local db_sql = require("common.db.db_sql")
local db_mysql = require("common.db.db_mysql")
local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help"
local base64_decoder = require("common.base64_decoder")

local user_dao = require "user.model.user_dao"
local user_ex_dao = require "user.model.user_ex_dao"
local user_address_dao = require "user.model.user_address_dao"
local user_account_tf_dao = require "user.model.user_account_tf_dao" 


local _M = {}

--[[
    @url:   
            user/api/user_info/change_user_name.action
            ?token=asda-asd_][as]
            &user_id=10000012
            &user_name=style
    @brief: 
            更改用户名
    @param: 
            [user_id:string] 用户唯一ID
            [token:string] token验证值，登录成功后返回的token值
            [user_name:string] 手机号
    @return:    
                {   
                    "code" : 200, 
                    "date" : {},
                    "msg" : "更改用户名成功."
                }
]]
function _M.change_user_name()
    local args = ngx.req.get_uri_args()
    local token = args['token']
    local phone_number = args['user_name']
    local user_id = args['user_id']

    --检查验证token值
    local res, msg = user_dao.is_keep_alived_login(user_id, token)
    if not res then
        return  api_data_help.new_failed("请重新登录. "..msg)
    end

    --检查参数
    if not user_id or user_id == '' then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "更改用户名失败, 参数[user_id] 为空.")
    end

    if not user_name or user_name == '' then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "更改用户名失败, 参数[user_name] 为空.")
    end

    --验证是否是合法用户名
    --to do ...

    --判断用户名是否已经注册
    local res, err = user_dao.is_user_name_exist(user_name)
    if res then
        return api_data_help.new(ZS_ERROR_CODE.SYSTEM_ERR, "更改用户名失败, 用户名已经被其它玩家绑定.")
    else
        if err then
            return api_data_help.new(ZS_ERROR_CODE.SYSTEM_ERR, "更改用户名失败, 系统错误, 请稍后尝试. err: "..err)
        end
    end

    --更新信息
    local res, err = user_dao.change_user_name(user_id, user_name)
    if res then
        api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "更改用户名成功.")
    else
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "更改用户名失败. err: "..err)
    end
end

--[[
    @url:   
            user/api/user_info/change_phone_number.action
            ?token=asda-asd_][as]
            &user_id=10000012
            &phone_number=1386543xxxx
    @brief: 
            更改手机号
    @param: 
            [user_id:string] 用户唯一ID
            [token:string] token验证值，登录成功后返回的token值
            [phone_number:string] 手机号
    @return:    
                {   
                    "code" : 200, 
                    "date" : {},
                    "msg" : "更改手机号成功."
                }
]]
function _M.change_phone_number()
    local args = ngx.req.get_uri_args()
    local token = args['token']
    local phone_number = args['phone_number']
    local user_id = args['user_id']

    --检查验证token值
    local res, msg = user_dao.is_keep_alived_login(user_id, token)
    if not res then
        return  api_data_help.new_failed("请重新登录. "..msg)
    end

    --检查参数
    if not user_id or user_id == '' then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "更改手机号失败, 参数[user_id] 为空.")
    end

    if not phone_number or #phone_number ~= 11 then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "更改手机号失败, 参数[phone_number] 为空.")
    end

    if tonumber(phone_number) == nil then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_PATTERN_ERR, "更改手机号失败, 参数[phone_number] 错误.")
    end

    --判断手机号是否已经注册
    local res, err = user_dao.is_mobile_phone_exist(phone_number)
    if res then
        return api_data_help.new(ZS_ERROR_CODE.SYSTEM_ERR, "更改手机号失败, 手机号已经被其它玩家绑定.")
    else
        if err then
            return api_data_help.new(ZS_ERROR_CODE.SYSTEM_ERR, "更改手机号失败, 系统错误, 请稍后尝试. err: "..err)
        end
    end

    --更新信息
    local res, err = user_dao.change_phone_number(user_id, phone_number)
    if res then
        api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "更改手机号成功.")
    else
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "更改手机号失败. err: "..err)
    end
end

--[[
    @url:   
            user/api/user_info/change_email.action
            ?token=asda-asd_][as]
            &user_id=10000012
            &email=abc@qq.com
    @brief: 
            更改邮箱
    @param: 
            [user_id:string] 用户唯一ID
            [token:string] token验证值，登录成功后返回的token值
            [email:string] 邮箱账号
    @return:    
                {   
                    "code" : 200, 
                    "date" : {},
                    "msg" : "更改邮箱账号成功."
                }
]]
function _M.change_email()
    local args = ngx.req.get_uri_args()
    local token = args['token']
    local email = args['email']
    local user_id = args['user_id']

    --检查验证token值
    local res, msg = user_dao.is_keep_alived_login(user_id, token)
    if not res then
        return  api_data_help.new_failed("请重新登录. "..msg)
    end

    --检查参数
    if not user_id or user_id == '' then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "更改邮箱失败, 参数[user_id] 为空.")
    end

    if not email or #email ~= 11 then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "更改邮箱失败, 参数[email] 为空.")
    end

    -- 验证是否符合email规则
    local regex_help = require "common.regex_help"
    local res = regex_help.isEmail(email) 
    if not res then 
        return api_data_help.new(ZS_ERROR_CODE.PARAM_PATTERN_ERR, "更改邮箱失败, 参数[email] 错误.")
    end

    --判断邮箱是否已经注册
    local res, err = user_dao.is_email_exist(email)
    if res then
        return api_data_help.new(ZS_ERROR_CODE.SYSTEM_ERR, "更改邮箱失败, 邮箱已经被其它玩家绑定.")
    else
        if err then
            return api_data_help.new(ZS_ERROR_CODE.SYSTEM_ERR, "更改邮箱失败, 系统错误, 请稍后尝试. err: "..err)
        end
    end

    --更新信息
    local res, err = user_dao.change_email(user_id, email)
    if res then
        api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "更改邮箱成功.")
    else
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "更改邮箱失败. err: "..err)
    end
end

--[[
    @url:   
            user/api/user_info/change_password.action
                ?user_id=10000029
                &password=123456
                &new_password=654321
                &need_force=false
                &token=asdas[xz__]a.,
    @brief: 
            用户修改密码, 主要用于密码修改,密码重置等场景
    @param:
            [user_id:string]   用户唯一ID
            [need_force:string]    是否强制修改密码
            [password:string]  原密码
            [new_password:string]  新密码
            [token:string] token值，登录后返回信息中包含token
    @return:
            {
                "code" : 200, 
                "data" : {}
                "msg" : "修改密码成功"
            } 

--]]
function _M.change_password()
    local args = ngx.req.get_uri_args() 
    local user_id = args['user_id']
    local token = args['token']
    local need_force = args['need_force']
    local password = args['password'] 
    
    --检查验证token值
    local res, msg = user_dao.is_keep_alived_login(user_id, token)
    if not res then
        return  api_data_help.new_failed("请重新登录. "..msg)
    end

    --修改密码
    if not need_force or need_force ~= 'true' then
        --验证原始密码
        if password then 
            password = user_dao.make_password(password)
        else
            return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, '修改密码失败,原密码不能为空')
        end

        local res = user_dao.get_use("", "", "", user_id)
        if res and res[1] then
            local  user_info = res[1]
            if user_info.password ~= password then
                return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, '修改密码失败,原密码不正确')
            end
        else
            return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, '修改密码失败,用户不存在')
        end
    end

    local new_password = args['new_password'] 
    if not new_password or new_password == "" then
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, '修改密码失败,新密码不能为空')
    end
    new_password = user_dao.make_password(new_password)

    -- 修改密码
    local res = user_dao.change_password(user_id, password, new_password) 
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "数据库异常")
    end

    if res.affected_rows > 0 then
        return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, '修改密码成功.')   
    else
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, '修改密码失败,密码错误'.. user_id)  
    end 
end

--[[
    @url:   
            user/api/user_info/update_user_ex.action
                ?user_id=10000029
                &token=asdas[xz__]a.
                &nick_name=海鲜炒饭
                &sex=男
                &signature=每天一顿蛋炒饭
                &home_town=江苏南京
                &cur_regional=江苏南京
                &birthday=1990-03-23 00:00:00
                &profession=民工
                &profession_own=自定义民工
                &blood_type=A
                &marriage=未婚

    @brief: 
            修改用户扩展信息
    @param:
            [user_id:string]   用户唯一ID
            [token:string] token值, 登录后返回信息中包含token
            [nick_name:string] 昵称
            [sex:string] 性别 男/女
            [signature:string] 个性签名
            [home_town:string] 故乡
            [cur_regional:string] 目前所在地
            [birthday:string] 生日
            [profession:string] 职业
            [profession_own:string] 自定义职业
            [blood_type:string] 血型 A/B/O/AB
            [marriage:string] 婚姻状况 已婚/未婚
    @return:
            {
                "code" : 200, 
                "data" : {}
                "msg" : "更改信息成功."
            } 

--]]
function _M.update_user_ex (  )
    local args = ngx.req.get_uri_args() 
    local user_id = args['user_id']  
    local token = args['token']  
    local nick_name = args["nick_name"]
    local sex = args['sex'] 
    local signature = args['signature']
    local home_town= args['home_town']
    local cur_regional = args['cur_regional']
    local birthday= args['birthday']
    local profession = args['profession']
    local profession_own = args['profession_own']
    local blood_type = args['blood_type']
    local marriage = args['marriage']

    --检查验证token值
    local res, msg = user_dao.is_keep_alived_login(user_id, token)
    if not res then
        return  api_data_help.new_failed("请重新登录. "..msg)
    end

    --检查参数
    if not user_id or user_id == '' then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "更改用户信息失败, 参数[user_id] 为空.")
    end

    --所有可修改的参数都为空，直接返回错误
    if (not nick_name or nick_name == '') and (not sex or sex == '') 
        and (not signature or signature == '') and (not home_town or home_town == '')
        and (not cur_regional or cur_regional == '') and (not birthday or birthday == '')
        and (not profession or profession == '') and (not profession_own or profession_own == '')
        and (not blood_type or blood_type == '') and (not marriage or marriage == '') then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "更改用户信息失败, 参数都为空.")
    end

    --检查参数是否合法 to do ...
    --性别检查
    if sex and sex ~= '男' and sex ~= '女' then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_PATTERN_ERR, "更改用户信息失败, 参数[sex] 错误.")
    end
    --血型检查
    if blood_type and blood_type ~= 'A' and blood_type ~= 'B' and blood_type ~= 'O' and blood_type ~= 'AB' then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_PATTERN_ERR, "更改用户信息失败, 参数[blood_type] 错误.")
    end 
    --婚姻检查
    if marriage and marriage ~= '已婚' and marriage ~= '未婚' then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_PATTERN_ERR, "更改用户信息失败, 参数[marriage] 错误.")
    end

    --更新信息
    local user_info = {}
    user_info.nick_name = nick_name
    user_info.sex = sex
    user_info.signature = signature
    user_info.cur_regional = cur_regional
    user_info.birthday = birthday
    user_info.profession = profession
    user_info.profession_own = profession_own
    user_info.blood_type = blood_type
    user_info.marriage = marriage
    
    local res, err = user_ex_dao.update_user_ex(user_id, user_info)
    if res then
        return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, '更改信息成功.') 
    else
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, '更改信息失败, err: '.. err) 
    end
end

--[[
    @url:   
            user/api/user_info/get_user_info.action
            ?token=asda-asd_][as]
            &user_id=10000012
    @brief: 
            更改邮箱
    @param: 
            [user_id:string] 用户唯一ID
            [token:string] token验证值，登录成功后返回的token值
    @return:    
                {   
                    "code" : 200, 
                    "date" : 用户信息,
                    "msg" : "获取用户信息成功."
                }
]]
function _M.get_user_info()
    local args = ngx.req.get_uri_args()
    local user_id = args['user_id']
    local token = args['token']

    --检查验证token值
    local res, msg = user_dao.is_keep_alived_login(user_id, token)
    if not res then
        return  api_data_help.new_failed("请重新登录. "..msg)
    end

    local res, errcode, errmsg = user_dao.get_user_info(user_id)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取用户信息失败", errmsg)
    end

    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取用户信息成功", res[1])
end

--[[
    @url:   user/api/user_info/get_points_detail.action?user_code=10000029    
    @brief: 获取用户积分明细
    @param: 
    @return:
]]
_M.get_points_detail  = function ()
    local args = ngx.req.get_uri_args()

    local user_code = args['user_code']
    local page = args['page'] or 1
    local page_size = args['page_size'] or 10

    if not user_code then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "请求参数[user_code]未设置")
    end

    local row_index = (page-1)*page_size
    local res = user_account_tf_dao.get_user_points_tf(user_code, row_index, page_size)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "数据库操作异常")
    end

    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取用户积分详情成功", res)
end

--[[
    @接口：user/api/user_info/get_balance_detail.action?user_code=10000035&page=1&page_size=8
    @说明：获取用户钻石明细
	@参数：[user_code] 用户code
		   [page] 页码
		   [page_size] 每页显示的数量
]]
_M.get_balance_detail = function ()
    local args = ngx.req.get_uri_args()

    local user_code = args['user_code']
    local page = args['page'] or 1
    local page_size = args['page_size'] or 10

    if not user_code then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "请求参数[user_code]未设置")
    end

    local row_index = (page-1)*page_size
    local res = user_account_tf_dao.get_user_balance_tf(user_code, row_index, page_size)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "数据库操作异常")
    end

    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取用户钻石详情成功", res)
end

--[[
    @url:   
            user/api/user_info/change_head_portrait.action
                ?user_id=10000029
                &token=asdas[xz__]a.,
    @brief: 
            更改用户头像, 使用post请求， 请求的data为图片二进制数据
    @param:
            [user_id:string]   用户唯一ID
            [token:string] token值，登录后返回信息中包含token
    @return:
            {
                "code" : 200, 
                "data" : {}
                "msg" : "设置成功."
            } 

--]]
function _M.change_head_portrait()
    local file_dao = require "files.model.file_dao"
    local args = ngx.req.get_uri_args()
    local user_id = args['user_id']
    local token = args['token']

    --检查验证token值
    local res, msg = user_dao.is_keep_alived_login(user_id, token)
    if not res then
        return  api_data_help.new_failed("请重新登录. "..msg)
    end

    local dir = 'upload/user_head'
    local name = string.format("%s_%s.jpg" , user_id, os.date("%Y%m%d%H%M", os.time()))
    local res, msg = file_dao.upload_file(dir, name)
    if not res then
        return api_data.new(ZS_ERROR_CODE.RE_FAILED, "设置用户头像失败, 上传头像失败.", msg)
    end

    local res = user_ex_dao.change_head_portrait(user_id, msg);
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "数据库异常，设置用户头像失败", res)
    end
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "设置用户头像成功", msg)
end

--[[
    @brief: 
            判断用户是否已经签到
    @param:
            [user_id:string]   用户唯一ID
    @return:
            返回签到信息
]]
local function has_user_signed(_user_id)
    local res, errcode, errmsg = user_dao.get_user_sign_info(_user_id)
    if not res then
        return false, "系统错误."
    end

    --如果没有记录，则改用户从未签到过
    if not res[#res] then
        return false
    end
 
    local sign_time = res[#res].sign_time
    ngx.log(ngx.ERR, "sign_time: ", sign_time)
    --如果没有签到时间，暂认为未签到
    --应该不会出现此情况
    if not sign_time or sign_time == '' then
        return false
    end

    --比较日期，一样则已经签到，反之未签到
    local sql_sign_date = string.sub(sign_time, 1, 10)
    ngx.log(ngx.ERR, "sql_sign_date: ", sql_sign_date)
    local sign_date = ngx.today()
    ngx.log(ngx.ERR, "sign_date: ", sign_date)
    if not sql_sign_date or not sign_date then
        return false, "系统错误."
    end

    if sql_sign_date == sign_date then
        return true
    else
        return false
    end
end 

--[[
    @url:   
            user/api/user_info/sign_in.action
                ?user_id=10000029
                &token=asdas[xz__]a.,
                &balance=100
    @brief: 
            用户签到
    @param:
            [user_id:string]   用户唯一ID
            [token:string] token值，登录后返回信息中包含token
            [balance:string] 签到奖励金额
    @return:
            {
                "code" : 200, 
                "data" : {}
                "msg" : "签到成功."
            } 

--]]
function _M.sign_in()
    local args = ngx.req.get_uri_args()
    local user_id = args["user_id"]
    local balance = args["balance"]
    local token = args["token"]

    --检查验证token值
    local res, msg = user_dao.is_keep_alived_login(user_id, token)
    if not res then
        return  api_data_help.new_failed("请重新登录. "..msg)
    end

    --检查用户是否已经签到
    local res, err = has_user_signed(user_id)
    if res then
        return api_data_help.new_failed("签到失败, 用户已签到.")
    else
        if err then
            ngx.log(ngx.ERR, "[sign_in] err: ", err)
            return api_data_help.new_failed("签到失败, 系统错误.")
        end
    end

    local res, msg = user_dao.set_sign_trade(user_id, balance)
    if not res then
        return api_data_help.new(code, "签到失败. err: ", msg)
    end
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "签到成功.", res)
end

--[[
    @url:   
            user/api/user_info/get_sign_info.action
                ?user_id=10000029
                &token=asdas[xz__]a.,
                &day=2
    @brief: 
            获取用户签到信息 暂定获取最近30条
    @param:
            [user_id:string]   用户唯一ID
            [token:string] token值，登录后返回信息中包含token
            [day:string] 获取记录的天数
    @return:
            {
                "code" : 200, 
                "data" : {
                            "sign_info": [
                                            {
                                                "user_id_fk":"10000022",
                                                "id_pk":"4",
                                                "sign_time":"2018-03-29 19:10:17"
                                            }
                                        ],
                            "day_count":1
                        }
                "msg" : "获取用户签到信息成功."
            } 

--]]
function _M.get_sign_info()
    local args = ngx.req.get_uri_args()
    local user_id = args["user_id"]
    local day = args['day']
    local token = args["token"]

    --检查验证token值
    local res, msg = user_dao.is_keep_alived_login(user_id, token)
    if not res then
        return  api_data_help.new_failed("请重新登录. "..msg)
    end

    local res
    local errcode
    local errmsg
    if day and tonumber(day) ~= nil then
        ngx.log(ngx.ERR, "get_sign_info day: ", day)
        res, errcode, errmsg = user_dao.get_user_sign_info_by_day(user_id, tonumber(day))
        if not res then
            return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "获取用户签到信息失败. err: "..(errmsg and errmsg or 'nil'))
        end
    else
        res, errcode, errmsg = user_dao.get_user_sign_info(user_id)
        if not res then
            return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "获取用户签到信息失败. err: "..(errmsg and errmsg or 'nil'))
        end
    end
    
    local data = {
        day_count = #res,
        sign_info = res
    }
    
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取用户签到信息成功.", data)
end

--[[
    @url:   
            user/api/user_info/get_user_address_info.action
                ?user_id=10000029
                &token=asdas[xz__]a.,
    @brief: 
            获取用户地址信息
    @param:
            [user_id:string]   用户唯一ID
            [token:string] token值，登录后返回信息中包含token
    @return:
            {
                "code" : 200, 
                "data" : {
                            地址信息
                        },
                "msg" : "获取用户地址信息成功."
            } 

--]]
function _M.get_user_address_info()
    local args = ngx.req.get_uri_args()
    local user_id = args["user_id"]
    local token = args["token"]

    --检查验证token值
    local res, msg = user_dao.is_keep_alived_login(user_id, token)
    if not res then
        return  api_data_help.new_failed("请重新登录. "..msg)
    end

    local res, errmsg = user_address_dao.get_user_address(user_id)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "获取用户地址信息失败. err: "..(errmsg and errmsg or 'nil'))
    end

    local data = {
        day_count = #res,
        address_info = res
    }
    
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取用户地址信息成功.", data)

end

--[[
    @url:   
            user/api/user_info/add_user_address_info.action
                ?user_id=10000029
                &token=asdas[xz__]a.,
                &accept_name=张三
                &phone_number=15261854062
                &mobile_number=15261854062
                &zip_code=213170
                &area_no=0086
                &address=南京市雨花区汇智大厦A-215
                &is_default=true
    @brief: 
            添加用户地址信息
    @param:
            [user_id:string]   用户唯一ID
            [token:string] token值，登录后返回信息中包含token
            [accept_name:string] 收货人姓名
            [phone_number:string] 收货人手机号
            [mobile_number:string] 收货人辅助电话号码
            [zip_code:string] 邮政编号
            [area_no:string] 区号
            [address:string] 详细地址
            [is_default:string] 是否为默认地址 1/0
    @return:
            {
                "code" : 200, 
                "data" : {
                            地址信息
                        },
                "msg" : "新增用户地址信息成功."
            } 

--]]
function _M.add_user_address_info()
    local args = ngx.req.get_uri_args()
    local user_id = args["user_id"]
    local accept_name = args['accept_name']
    local phone_number = args['phone_number']
    local mobile_number = args['mobile_number']
    local zip_code = args['zip_code']
    local area_no = args['area_no']
    local address = args['address']
    local is_default = args['is_default']
    local token = args["token"]

    --检查验证token值
    local res, msg = user_dao.is_keep_alived_login(user_id, token)
    if not res then
        return  api_data_help.new_failed("请重新登录. "..msg)
    end

    --验证参数
    if not accept_name or accept_name == '' or not phone_number or #phone_number ~= 11
        or not zip_code or zip_code == '' or not address or address == '' 
        or not area_no or area_no == '' then
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "参数错误，请核对参数.")
    end

    local param = {}
    param.user_id = user_id
    param.accept_name = accept_name
    param.phone_number = phone_number
    param.mobile_number = mobile_number
    param.zip_code = zip_code
    param.area_no = area_no
    param.address = address
    param.is_default = is_default == 'true' and 1 or 0
    
    local res, errmsg = user_address_dao.add_user_address(param)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "添加用户地址信息失败. err: "..(errmsg and errmsg or 'nil'))
    end
    
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "添加用户地址信息成功.")

end

--[[
    @url:   
            user/api/user_info/update_user_address_info.action
                ?user_id=10000029
                &token=asdas[xz__]a.,
                &accept_name=张三
                &phone_number=15261854062
                &mobile_number=15261854062
                &zip_code=213170
                &area_no=0086
                &address=南京市雨花区汇智大厦A-215
                &is_default=true
                &index=1
    @brief: 
            获取用户地址信息
    @param:
            [user_id:string]   用户唯一ID
            [token:string] token值，登录后返回信息中包含token
            [accept_name:string] 收货人姓名
            [phone_number:string] 收货人手机号
            [mobile_number:string] 收货人辅助电话号码
            [zip_code:string] 邮政编号
            [area_no:string] 区号
            [address:string] 详细地址
            [is_default:string] 是否为默认地址 1/0
            [index:string] 第几条记录，主要定位数据库记录的偏移
    @return:
            {
                "code" : 200, 
                "data" : {
                            地址信息
                        },
                "msg" : "更新用户地址信息成功."
            } 

--]]
function _M.update_user_address_info()
    local args = ngx.req.get_uri_args()
    local user_id = args["user_id"]
    local accept_name = args['accept_name']
    local phone_number = args['phone_number']
    local mobile_number = args['mobile_number']
    local zip_code = args['zip_code']
    local area_no = args['area_no']
    local address = args['address']
    local is_default = args['is_default']
    local index = args['index']
    local token = args["token"]

    --检查验证token值
    local res, msg = user_dao.is_keep_alived_login(user_id, token)
    if not res then
        return  api_data_help.new_failed("请重新登录. "..msg)
    end

    --验证参数
    if (not accept_name or accept_name == '') and (not phone_number or #phone_number ~= 11)
        and (not mobile_number or #mobile_number ~= 11) and (not area_no or area_no == '')
        and (not zip_code or zip_code == '') and (not address or address == '') 
        and (not is_default or is_default == '') then
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "参数为空，请核对参数.")
    end

    if not index or index == '' then
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "参数为空，[index] 不能为空.")
    end

    local param = {}
    param.user_id = user_id
    param.accept_name = accept_name
    param.phone_number = phone_number
    param.mobile_number = mobile_number
    param.zip_code = zip_code
    param.area_no = area_no
    param.address = address
    param.is_default = is_default == 'true' and 1 or 0
    param.index = index

    local res, errmsg = user_address_dao.update_user_address(param)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.RE_FAILED, "更新用户地址信息失败. err: "..(errmsg and errmsg or 'nil'))
    end
    
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "更新用户地址信息成功.")

end

--[[
    @接口：http://192.168.1.200:9000/user/api/user_info/feedback.action?user_code_fk=10000035&type=意见&content="我确实不知道说点啥"
    @说明：用户反馈
    @参数：
]]
function _M.feedback() 
    local args = ngx.req.get_uri_args()
    args.timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time())
    if not args.user_code_fk or not args.type or not args.content then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "参数异常: [user_code_fk or type or content is not set.")
    end

    local sql = string.format("INSERT INTO t_user_feedback (timestamp, user_code_fk, type, content) VALUES ('%s','%s','%s', '%s');", args.timestamp, args.user_code_fk, args.type, args.content)
    local res, msg = db_mysql:exec_once(sql)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "用户反馈失败", msg)
    end
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "用户反馈成功", res)
end


--[[
    @接口：http://192.168.1.200:9000/user/api/user_info/get_feedback.action?user_code=10000035
    @说明：获取用户反馈
    @参数：[user_code]
]]
function _M.get_feedback() 
    local args = ngx.req.get_uri_args()
    local user_code = args["user_code"]
    if not user_code then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "参数[user_code]未设置")
    end

    local sql = string.format( "SELECT * from t_user_feedback WHERE user_code_fk='%s';", user_code)
    local res, msg = db_mysql:exec_once(sql)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "获取用户反馈失败", msg)
    end
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取用户反馈成功", res)
end

--[[
    @接口：http://192.168.1.200:9000/user/api/user_info/get_exchange_recode.action?user_code=10000035
    @说明：获取用户兑换记录
    @参数：[user_code] 用户code
]]
function _M.get_exchange_recode()
    local args = ngx.req.get_uri_args()
    local user_code = args["user_code"]
    if not user_code then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "参数[user_code]未设置")
    end

    local sql = "SELECT A.*, B.*, C.* from t_order A, t_order_mem B, t_goods C "
    sql = sql .. string.format("WHERE A.user_code_fk='%s' AND B.order_code_fk=A.order_code AND B.goods_code_fk=C.goods_code;", user_code)
    local res, msg = db_mysql:exec_once(sql)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "获取用户兑换记录失败", msg)
    end
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取用户兑换记录成功", res)
end

--[[
    @接口：http://192.168.1.200:9000/user/api/user_info/get_public_recode.action?user_code=10000035
    @说明：获取众筹活动兑换记录
    @参数：[user_code] 用户code
]]
function _M.get_public_recode()
    local args = ngx.req.get_uri_args()
    local user_code = args["user_code"]
    if not user_code then
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "参数[user_code]未设置")
    end

    local page = tonumber(args["page"])
    local page_size = args["page_size"] or 8

    local index = 0
    if page and page>0 then
        index = (page-1)*page_size
    end

    local sql = string.format( [[
                SELECT t_activity_partake_tf.*, 
                t_release_activities.*,
                t_goods.goods_code, t_goods.title, t_goods.cover_url, t_goods.image_url
                from t_activity_partake_tf 
                left join t_release_activities on t_release_activities.id = t_activity_partake_tf.activity_id_fk 
                left join t_goods on t_goods.goods_code = t_release_activities.goods_code_fk 
                WHERE user_code_fk='%s' LIMIT %d,%d;
            ]], user_code,index,page_size)
    local res, msg = db_mysql:exec_once(sql)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.MYSQL_ERR, "获取用户兑换记录失败", msg)
    end
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取用户兑换记录成功", res)
end

return _M