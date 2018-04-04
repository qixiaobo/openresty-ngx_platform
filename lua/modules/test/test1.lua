-- local session = require "resty.session".open()
-- local name = session.data.name or "Anonymous"
-- ngx.say("name: "..name)


-- local user_dao = require "user.model.user_dao" 

-- local s1 = "12345678"
-- ngx.say("1: "..user_dao.make_password(s1))
-- ngx.say("2: "..user_dao.make_password(s1))

local cjson = require "cjson"
local regex = require "resty.core.regex"
local db_sql = require("common.db.db_sql")
local db_mysql = require("common.db.db_mysql")
local request_help = require "common.request_help"
local api_data_help = require "common.api_data_help"
local base64_decoder = require("common.base64_decoder")

local user_dao = require "user.model.user_dao"
local user_ex_dao = require "user.model.user_ex_dao"
local user_account_tf_dao = require "user.model.user_account_tf_dao" 

local function update_user_ex (  )
    local args = ngx.req.get_uri_args() 
    local user_id = args['user_id']  
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

    --检查参数
    if not user_id or user_id == '' then
    	ngx.say('1')
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "更改用户信息失败, 参数[user_id] 为空.")
    end

    --所有可修改的参数都为空，直接返回错误
    if (not nick_name or nick_name == '') and (not sex or sex == '') 
        and (not signature or signature == '') and (not home_town or home_town == '')
        and (not cur_regional or cur_regional == '') and (not birthday or birthday == '')
        and (not profession or profession == '') and (not profession_own or profession_own == '')
        and (not blood_type or blood_type == '') and (not marriage or marriage == '') 
    then
    	ngx.say('2')	
        return api_data_help.new(ZS_ERROR_CODE.PARAM_NULL_ERR, "更改用户信息失败, 参数都为空.")
    end

    --检查参数是否合法 to do ...
    --性别检查
    if sex and sex ~= '男' and sex ~= '女' then
    	ngx.say('3')
        return api_data_help.new(ZS_ERROR_CODE.PARAM_PATTERN_ERR, "更改用户信息失败, 参数[sex] 错误.")
    end
    --血型检查
    if blood_type and blood_type ~= 'A' and blood_type ~= 'B' and blood_type ~= 'O' and blood_type ~= 'AB' then
        ngx.say('4')
        return api_data_help.new(ZS_ERROR_CODE.PARAM_PATTERN_ERR, "更改用户信息失败, 参数[blood_type] 错误.")
    end 
    --婚姻检查
    if marriage and marriage ~= '已婚' and marriage ~= '未婚' then
        ngx.say('5')
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

local function get_user_info()
    local args = ngx.req.get_uri_args()
    local user_id = args['user_id']

    local res, errcode, errmsg = user_dao.get_user_info(user_id)
    if not res then
        return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取用户信息失败", errmsg)
    end
    ngx.say(cjson.encode(res))
    return api_data_help.new(ZS_ERROR_CODE.RE_SUCCESS, "获取用户信息成功", res)
end
--get_user_info()
-- local timestamp = os.date("%Y-%m-%d", os.time())
-- ngx.say('time: '..os.time())
-- ngx.say(ngx.time())
local res, errcode, errmsg = user_dao.get_user_sign_info_by_day('10000022', 1)

ngx.say(cjson.encode(res))