local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require("zce.core")
local lu = require("luaunit")
local cjson = require("cjson")
local util = require("util")
local cfg = require("hawk.config")

local __SQL_INITDB = [[
CREATE TABLE public.users_package
(
    iid integer NOT NULL,
    "package" jsonb,
    CONSTRAINT users_package_pkey PRIMARY KEY (iid)
)
WITH (
    OIDS = FALSE
);
]]

_M.addPackage_FIELD = {
    {"pkgid", "ID"},
    {"pkgtype", "类型"},
    {"pkgnum", "数量"},
}

if cfg.siteid == nil then
    zce.log(4, "", "MUST has siteid")
end

function _M.initDB()
    local ok, res = zce.rdb_execute(cfg.pgsqldb.dbobj, __SQL_INITDB)
    return ok, res
end

function _M._getPackageFromCache(iid, pkgcatalog)
    local ok, res = zce.cache_get(cfg.package.cacheobj, 
        cfg.siteid .. ".package.".. pkgcatalog .. ":" .. iid)
    -- zce.log(1, "|","fromcache", pkgcatalog, zce.tojson(res, true))
    return ok, res
end

function _M._savePackageToCache(iid, pkgcatalog, catalogobj)
    local ok, res = zce.cache_set(cfg.package.cacheobj, 
        cfg.siteid .. ".package.".. pkgcatalog .. ":" .. iid,
        catalogobj)
    
    return ok, res
end

function _M._getPackageFromPgdb(iid, pkgcatalog)
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "select package->? as catalog from users_package where iid =?",
        pkgcatalog, iid)
    if not ok or res == nil then
        return ok, res
    end
    if #res == 0 then
        return ok, {}
    end
    zce.log(1, "|", ok, res[1]["catalog"])
    if res[1]["catalog"] == nil then
        return ok, {}
    end
    return true, cjson.decode(res[1]["catalog"])
end

function _M._savePackageToPgdb(iid, pkgcatalog, catalogobj)
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "select iid from users_package where iid = ?",
        iid)
    if not ok then
        return false
    end
    if res == nil or #res == 0 then
        local obj = {}
        obj[pkgcatalog] = catalogobj
        local json_text = cjson.encode(obj)
        local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
            "insert into users_package(iid, package) values(?, ?)",
            iid, json_text)
        return ok, res
    else
        local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
            "update users_package set package=jsonb_set(package, ?, ?, true)::jsonb  where iid =?",
            '{' .. pkgcatalog .. '}', cjson.encode(catalogobj), iid)
        return ok, res
    end    
end

function _M.getPackage(iid, pkgcatalog)
    local ok, res = _M._getPackageFromCache(iid, pkgcatalog)
    if ok and res ~= nil then
        return ok, res
    end
    ok, res = _M._getPackageFromPgdb(iid, pkgcatalog)
    return ok, res
end

function _M.savePackage(iid, pkgcatalog, catalogobj)
    local ok, res = _M._savePackageToPgdb(iid, pkgcatalog, catalogobj)
    if ok and res ~= nil then
        ok, res = _M._savePackageToCache(iid, pkgcatalog, catalogobj)
        return ok, res
    end
    return ok, res
end

-- 增加背包道具，如果ID重复，会增加其中的数量
function _M.addPackage(iid, pkgcatalog, pkgitem)
    local ok, catalogobj = _M.getPackage(iid, pkgcatalog)
    if not ok then
        zce.log(1, "|", ok, catalogobj)
        return false, catalogobj
    end

    if catalogobj == nil then
        catalogobj = {}
    end

    if (catalogobj[pkgitem.pkgid] == nil) then
        catalogobj[pkgitem.pkgid] = pkgitem
    else
        catalogobj[pkgitem.pkgid].pkgnum = catalogobj[pkgitem.pkgid].pkgnum + pkgitem.pkgnum
    end

    local ok, res = _M.savePackage(iid, pkgcatalog, catalogobj)
    zce.log(1, "|", ok, res)
    return ok, res
end

-- 删除背包中的道具
function _M.delPackage(iid, pkgcatalog, pkgid)
    local ok, catalogobj = _M.getPackage(iid, pkgcatalog)
    if not ok or catalogobj == nil then
        zce.log(1, "|", ok, catalogobj)
        return false, "not exists"
    end
    if catalogobj[pkgid] == nil then
        return true
    end
    catalogobj[pkgid] = nil
    local ok, res = _M.savePackage(iid, pkgcatalog, catalogobj)
    zce.log(1, "|", ok, res)
    return ok, res
end

-- 修改背包道具中的项目
function _M.updatePackageItem(iid, pkgcatalog, pkgid, itemobj)
    local ok, catalogobj = _M.getPackage(iid, pkgcatalog)
    if not ok or catalogobj == nil or catalogobj[pkgid] == nil then
        zce.log(1, "|", ok, catalogobj)
        return false, "not exists"
    end
    util.shallowMerge(catalogobj[pkgid], itemobj)
    local ok, res = _M.savePackage(iid, pkgcatalog, catalogobj)
    zce.log(1, "|", ok, res)
    return ok, res
end

-- 删除背包道具中的项目
function _M.deletePackageItem(iid, pkgcatalog, pkgid, itemname)
    local ok, catalogobj = _M.getPackage(iid, pkgcatalog)
    if not ok or catalogobj == nil or catalogobj[pkgid] == nil then
        zce.log(1, "|", ok, catalogobj)
        return false, "not exists"
    end
    catalogobj[pkgid][itemname] = nil
    local ok, res = _M.savePackage(iid, pkgcatalog, catalogobj)
    zce.log(1, "|", ok, res)
    return ok, res
end

-- 查询背包项目，每页几个，第几页，只需要总数，第0页即可
-- filter是过滤条件，不填是不过滤
function _M.queryPackageItem(iid, pkgcatalog, pageitems, pagenum, filter)
    local ok, catalogobj = _M.getPackage(iid, pkgcatalog)
    if not ok or catalogobj == nil then
        zce.log(1, "|", ok, catalogobj)
        return false, "not exists"
    end
    if filter ~= nil then
        util.filterTableItemInPlace(filter, catalogobj)
    end
    local objret = {}
    local count = 0
    local retcount = 0
    local startnum = pageitems * (pagenum - 1)
    local endnum = pageitems * pagenum
    for k, v in util.orderedPairs(catalogobj) do 
        if (count >= startnum and count < endnum) then
            objret[k] = v
            retcount = retcount + 1
        end
        count = count + 1
    end
    objret['total'] = count - 1
    objret['count'] = retcount
    return true, objret
end