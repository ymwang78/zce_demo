local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M
local c = require "zce.core"
local cjson = require "cjson"
local lu = require('luaunit')

local session = require("auth.session")

local ok, hk_cache = c.cache_init("local", "hawk.cache")
lu.assertEquals(ok, true)

local ok, pgdb = c.cache_get(hk_cache, "hawk.db.pgsql")
lu.assertEquals(ok, true)

local ok, redisobj = c.cache_get(hk_cache, "hawk.db.redis")
lu.assertEquals(ok, true)

local _PID_USERS = {}

local _IID_USERS = {}

local _ALLOW_UPDATE_PROP = {
	cellid = true,
	emailid = true,
	idcard = true,
	idname = true
}

function _M.getUserFromIid(iid)
	if (_IID_USERS[iid] ~= nil) then
		return true, _IID_USERS[iid]
	end
	local ok, res = c.rdb_query(pgdb, "select * from users where iid = ?", iid)
	if not ok or #res == 0 then
		return false, nil
	end
	_IID_USERS[iid] = res[1]
	_PID_USERS[res[1].pid] = res[1]
	return ok, res[1]
end

function _M.getUserFromPid(pid)
	if (_PID_USERS[pid] ~= nil) then
		return true, _PID_USERS[pid]
	end

	local ok, res
	if pid > 10000000000 then
		ok, res = c.rdb_query(pgdb, "select * from users where cellid = ?", tostring(pid))
	else
		ok, res = c.rdb_query(pgdb, "select * from users where pid = ?", pid)
	end
	if not ok or #res == 0 then
		return false, nil
	end

	_PID_USERS[pid] = res[1]
	_IID_USERS[res[1].iid] = res[1]
	return ok, res[1]
end

function _M.updateUserIdInfo(user, propertie, value)
	if not _ALLOW_UPDATE_PROP[propertie] then
		return false
	end

	local ok, res = c.rdb_query(pgdb, "update users set " .. propertie .. "=? where iid = ?", value, user.iid)
	if not ok or #res == 0 then
		return false
	end
	user[propertie] = value
	return true
end
