local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local c = require "zce.core"
local lu = require('luaunit')
local cjson = require("cjson")
local session = require("auth.session")

local ok, hawkcacheobj = c.cache_init("local", "hawk.cache")
lu.assertEquals(ok, true)

local ok, pgdb = c.cache_get(hawkcacheobj, "pgdb")
lu.assertEquals(ok, true)

local ok, redisobj = c.cache_get(hawkcacheobj, "redis")
lu.assertEquals(ok, true)

local _APP_SESCRET = {}

local function _get_appsecret(appid)
	if (_APP_SESCRET[appid] ~= nil) then
		return _APP_SESCRET[appid]
	end

	local ok, res = c.rdb_query(pgdb, "select * from config_oauth2 where appid = ?", appid)
	lu.assertEquals(ok, true)
	lu.assertEquals(#res, 1) -- 如果这里错误，需要到config_oauth2表里去添加appid, appsecret
	if not ok or #res < 1 then
		c.log(3, "\t", "appid not exists in table(config_oauth2): " .. appid)
		return nil
	end

	_APP_SESCRET[appid] = res[1].secret;
	return res[1].secret
end

-- 微信客户端登陆后拿到code从服务端取获取OPENID, SESSIONID, 以及UNIONID(如果有)
function _M:authCode2Session(parameters)
	c.log(1, "\t", "authCode2Session:", c.tojson(parameters, true))

	local secret = _get_appsecret(parameters.appid)
	if (secret == nil) then
		return nil
	end

	local url = "https://api.weixin.qq.com/sns/jscode2session?appid=" .. parameters.appid ..
		"&secret=" .. secret .. 
		"&js_code=" .. parameters.code ..
		"&grant_type=authorization_code"

	local ok, code, param, body = c.http_request("GET", url, {}, "")
	lu.assertEquals(ok, true)
	lu.assertEquals(code, 200)

	local resobj = cjson.decode(body)
	if (resobj.openid == nil) or (resobj.session_key == nil) then
		c.log(1, "\t", "weixin:jscode2session return:", ok, code, param, body )
		return nil
	end

	local ok, resiid = c.rdb_query(pgdb, "select * from users_oauth2 where openid = ?", resobj.openid)
	if (ok and #resiid == 0) then
		local ok, resiid = c.rdb_query(pgdb, "insert into users(passwd) values (?) returning iid", "")
		lu.assertEquals(ok, true)
		c.log(1, "\t", "auth:", c.tojson(resiid[1], true))
		
		local ok, res = c.rdb_query(pgdb, "insert into users_oauth2(openid, iid) values (?, ?)", resobj.openid, resiid[1].iid)
		lu.assertEquals(ok, true)
	end

	local login_session = { iid = resiid[1].iid, openid = resobj.openid, session_key = resobj.session_key }

	session:saveSession(resobj.session_key, login_session)

	return login_session
end

function _M:sessionKeyLogin(parameters)
	c.log(1, "\t", "sessionKeyLogin:", c.tojson(parameters, true))

	return session:getSession(parameters.session_key)
end

function _M:updateUserInfo(parameters)
	c.log(1, "\t", "updateUserInfo:", c.tojson(parameters, true))

	local login_session =session:getSession(parameters.session_key)
	if login_session == nil then 
		return nil
	end

	local ok, res = c.rdb_query(pgdb, "update users set nick=?, avatar=? where iid=?", 
		parameters.nickname, parameters.avatarUrl, login_session.iid)
	lu.assertEquals(ok, true)
	lu.assertEquals(#res, 1)
	--c.log(1, "\t", "auth:", c.tojson(res[1], true))
	login_session.nick = parameters.nickname
	login_session.avatar = parameters.avatarUrl

	session:saveSession(parameters.session_key, login_session)

	return login_session
end

function _M:procHttpReq(data)
	local bodyobj = {}
	if string.len(data.body) > 0 then
		if ( data.header['Content-Type'] ~= nil and string.match(data.header['Content-Type'], "application/json") ) then
			bodyobj = cjson.decode(data.body)
		end
	end

	if (string.match(data.path, "/auth/wechat/codeLogin")) then
		local user_session = _M:authCode2Session(data.parameters)
		if (user_session == nil) then
			return ""
		else
			return cjson.encode(user_session)
		end

	elseif (string.match(data.path, "/auth/wechat/sessionKeyLogin")) then
		local user_session = _M:sessionKeyLogin(data.parameters)
		-- c.log(1, "\t", c.tojson(user_session, true))
		if (user_session == nil) then
			return ""
		else
			return cjson.encode(user_session)
		end

	elseif (string.match(data.path, "/auth/wechat/updateUserInfo")) then
		local user_session = _M:updateUserInfo(bodyobj)
		if (user_session == nil) then
			return ""
		else
			return cjson.encode(user_session)
		end
	else
		return nil, 404
	end
end