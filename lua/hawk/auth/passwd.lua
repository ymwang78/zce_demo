local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local c = require("zce.core")
local lu = require("luaunit")
local cjson = require("cjson")
local util = require("util")
local cfg = require("hawk.config")
local user = require("hawk.user")
local session = require("hawk.auth.session")

local _APP_SESCRET = {}

local function _get_appsecret(appid)
    if (_APP_SESCRET[appid] ~= nil) then
        return _APP_SESCRET[appid]
    end

    local ok, res = c.rdb_query(cfg.pgsqldb, "select * from config_oauth2 where appid = ?", appid)
    lu.ensureEquals(ok, true, res)
    lu.assertEquals(#res, 1) -- 如果这里错误，需要到config_oauth2表里去添加appid, appsecret
    if not ok or #res < 1 then
        c.log(3, "\t", "appid not exists in table(config_oauth2): " .. appid)
        return nil
    end

    _APP_SESCRET[appid] = res[1].secret;
    return res[1].secret
end

-- appid=&iid=&unixtime=&sign=&
function _M.pwdChallengeLogin(parameters)
    c.log(1, '\t', 'pwdChallengeLogin:', c.tojson(parameters, true))

    local now = c.time_now();

    if math.abs(parameters.unixtime - now) > 300 then
        return nil, "unixtime expire"
    end

    local secret = _get_appsecret(parameters.appid)
    if (secret == nil) then
        return nil, "invalid appid"
    end

    local ok, user = user.getUserFromPid(parameters.pid)
    lu.ensureEquals(ok, true, user);
    if (not ok) then
        return nil, "invalid pid"
    end

    parameters.passwd = user.passwd
    parameters.secret = secret

    local paramstr = ''
    local sign = ''
    for k, v in util.orderedPairs(parameters) do
        if (k ~= 'sign') then
            paramstr = paramstr .. k .. '=' .. v .. '&'
        else
            sign = v
        end
    end
    mysign = c.encode_md5(paramstr)
    c.log(1, "\t", paramstr, sign, mysign)

    if sign ~= mysign then
        return nil, "invalid sign"
    end

    local login_session = util.shallowCopy(user)
    login_session.passwd = nil
    login_session.session_key = c.guid()

    session.saveSession(login_session.session_key, login_session)

    return login_session
end

function _M.sessionKeyLogin(parameters)
    c.log(1, "\t", "sessionKeyLogin:", c.tojson(parameters, true))

    return session.getSession(parameters.session_key)
end

function _M.updateUserInfo(parameters)
    c.log(1, "\t", "updateUserInfo:", c.tojson(parameters, true))

    local login_session = session.getSession(parameters.session_key)
    if login_session == nil then 
        c.log(1, "\t", "updateUserInfo not found:", parameters.session_key)
        return nil
    end

    local ok, res = c.rdb_query(cfg.pgsqldb, "update users set nick=?, avatar=? where iid=?", 
        parameters.nickname, parameters.avatarUrl, login_session.iid)
    lu.assertEquals(ok, true)
    lu.assertEquals(#res, 1)
    --c.log(1, "\t", "auth:", c.tojson(res[1], true))
    login_session.nick = parameters.nickname
    login_session.avatar = parameters.avatarUrl

    session.saveSession(parameters.session_key, login_session)

    return login_session
end

function _M.procHttpReq(data)
    local bodyobj = {}
    if string.len(data.body) > 0 then
        if (data.header['Content-Type'] ~= nil 
            and string.match(data.header['Content-Type'], "application/json")) then
            bodyobj = cjson.decode(data.body)
        end
    end

    local retbody = {}

    if (string.match(data.path, "/auth/passwd/pwdChallengeLogin")) then
        local user_session, hint = _M.pwdChallengeLogin(data.parameters)
        if (user_session == nil) then            
            retbody = { code = -501, desc = hint }
        else
            retbody = { code = 0, data = user_session}
        end

    elseif (string.match(data.path, "/auth/passwd/sessionKeyLogin")) then
        local user_session = _M.sessionKeyLogin(data.parameters)
        -- c.log(1, "\t", c.tojson(user_session, true))
        if (user_session == nil) then            
            retbody = { code = -501, desc = hint }
        else
            retbody = { code = 0, data = user_session}
        end

    elseif (string.match(data.path, "/auth/passwd/updateUserInfo")) then
        local user_session = _M.updateUserInfo(bodyobj)
        if (user_session == nil) then            
            retbody = { code = -404, desc = hint }
        else
            retbody = { code = 0, data = user_session}
        end
    else
        return nil, 404
    end

    return cjson.encode(retbody)
end