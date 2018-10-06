--[[
    本模块提供会话存取管理功能
--]]
local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local c = require("zce.core")
local lu = require("luaunit")
local cjson = require("cjson")
local cfg = require("hawk.config")

local _APP_SESCRET = {}
local _REDIS_SESSION_KEY_PREFIX = "hawk.auth.session:"

function _M.saveSession(sessionKey, sessionData)
    c.log(1, "\t", "saveSession: " .. sessionKey, c.tojson(sessionData, true))
    c.cache_set(cfg.redisdb,  _REDIS_SESSION_KEY_PREFIX .. sessionKey, sessionData)
end

function _M.getSession(sessionKey)
    local ok, login_session = c.cache_get(cfg.redisdb, _REDIS_SESSION_KEY_PREFIX .. sessionKey)
    if not ok then -- logion_session now is an error string
        c.log(1, "\t", "session not found: " .. sessionKey, login_session)
        return nil
    end
    return login_session
end
