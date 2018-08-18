--[[
本模块提供会话存取管理功能
--]]

local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M
local c = require "zce.core"
local lu = require('luaunit')
local cjson = require "cjson"

local ok, hawkcacheobj = c.cache_init("local", "hawk.cache")
lu.assertEquals(ok, true)

local ok, pgdb = c.cache_get(hawkcacheobj, "pgdb")
lu.assertEquals(ok, true)

local ok, redisobj = c.cache_get(hawkcacheobj, "redis")
lu.assertEquals(ok, true)

local _APP_SESCRET = {}
local _REDIS_SESSION_KEY_PREFIX = "hawk.auth.session:"

function _M:saveSession(sessionKey, sessionData)
	c.cache_set(redisobj,  _REDIS_SESSION_KEY_PREFIX .. sessionKey, sessionData)
end

function _M:getSession(sessionKey)
	local ok, login_session = c.cache_get(redisobj, _REDIS_SESSION_KEY_PREFIX .. sessionKey)
	if not ok then -- logion_session now is an error string
		c.log(1, "\t", "session not found: " .. sessionKey, login_session)
		return nil
	end
	return login_session
end
