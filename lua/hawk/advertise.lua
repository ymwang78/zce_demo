local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require("zce.core")
local cjson = require("cjson")
local lu = require("util.luaunit")
local cfg = require("hawk.config")

local _AD_CACHE = {}
local _MESSAGE_CACHE = {}

function _M.queryAd(parameters)
    local cacheid =  parameters.id
    if (_AD_CACHE[cacheid] ~= nil) then
        return _AD_CACHE[parameters.id]
    end

    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "select width, height, properties from config_ad where id = ?",
        parameters.id)
    lu.assertEquals(ok, true)
    if not ok or #res < 1 then 
        return nil
    end
    
    local adobj = res[1]
    adobj.properties = cjson.decode(adobj.properties)

    _AD_CACHE[cacheid] = adobj
    zce.vmvar_expire(_AD_CACHE, parameters.id, 5 * 60) -- cache 5min
    return adobj
end

function _M.queryAdvertise(parameters)
    if parameters.areaid == nil then
        parameters.areaid = ''
    end

    local cacheid =  parameters.areaid .. '.' .. parameters.adid
    if (_AD_CACHE[cacheid] ~= nil) then
        return _AD_CACHE[parameters.adid]
    end

    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "select width, height, properties from config_ad where appid = ? and areaid = ? and adid = ?",
        cfg.appid, parameters.areaid, parameters.adid)
    lu.assertEquals(ok, true)
    if not ok or #res < 1 then 
        return nil
    end
    
    local adobj = res[1]
    adobj.properties = cjson.decode(adobj.properties)

    _AD_CACHE[cacheid] = adobj
    zce.vmvar_expire(_AD_CACHE, parameters.adid, 5 * 60) -- cache 5min
    return adobj
end

function _M.queryMessage(parameters)
    local cacheid = parameters.areaid .. parameters.catalog
    if (_MESSAGE_CACHE[parameters.id] ~= nil) then
        return _MESSAGE_CACHE[parameters.id]
    end

    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "select width, height, properties from config_ad where appid = ? and adid = ?",
        cfg.appid, parameters.id)
    lu.assertEquals(ok, true)
    if not ok or #res < 1 then 
        return nil
    end
    
    local adobj = res[1]
    adobj.properties = cjson.decode(adobj.properties)

    _AD_CACHE[parameters.id] = adobj
    zce.vmvar_expire(_AD_CACHE, parameters.id, 5 * 60) -- cache 5min
    return adobj
end

function _M.procHttpReq(data)
    local bodyobj = {}
    if string.len(data.body) > 0 then
        if ( data.header['Content-Type'] ~= nil and string.match(data.header['Content-Type'], "application/json") ) then
            bodyobj = cjson.decode(data.body)
        end
    end

    local adobj

    if (string.match(data.path, "/advertise/queryAdvertise")) then
        adobj = _M.queryAdvertise(data.parameters)
    elseif (string.match(data.path, "/advertise/queryAd")) then
        adobj = _M.queryAd(data.parameters)
    else
        return nil, 404
    end

    if (adobj == nil) then
        return ""
    else
        return cjson.encode(adobj), 200, { ['Content-Type'] = "application/json"}
    end
end