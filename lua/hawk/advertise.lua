local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M
local c = require "zce.core"
local cjson = require "cjson"
local lu = require('luaunit')

local ok, hawkcacheobj = c.cache_init("local", "hawk.cache")
lu.assertEquals(ok, true)

local ok, pgdb = c.cache_get(hawkcacheobj, "pgdb")
lu.assertEquals(ok, true)

local ok, redisobj = c.cache_get(hawkcacheobj, "redis")
lu.assertEquals(ok, true)

local _AD_CACHE = {}

function _M:queryAd(parameters)
	if (_AD_CACHE[parameters.id] ~= nil) then
		return _AD_CACHE[parameters.id]
	end

	local ok, res = c.rdb_query(pgdb, "select width, height, properties from config_ad where id = ?", parameters.id)
	lu.assertEquals(ok, true)
	if not ok or #res < 1 then 
		return nil
	end
	
	local adobj = res[1]
	adobj.properties = cjson.decode(adobj.properties)

	_AD_CACHE[parameters.id] = adobj
	c.vmvar_expire(_AD_CACHE, parameters.id, 5 * 60) -- cache 5min
	return adobj
end

function _M:procHttpReq(data)
	local bodyobj = {}
	if string.len(data.body) > 0 then
		if ( data.header['Content-Type'] ~= nil and string.match(data.header['Content-Type'], "application/json") ) then
			bodyobj = cjson.decode(data.body)
		end
	end

	if (string.match(data.path, "/advertise/queryAd")) then
		local adobj = _M:queryAd(data.parameters)
		if (adobj == nil) then
			return ""
		else
			return cjson.encode(adobj), 200, { ['Content-Type'] = "application/json"}
		end
	else
		return nil, 404
	end
end