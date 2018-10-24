local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require("zce.core")
local lut = require("luaunit")
local cfg = require("hawk.config")

-- { orgid: { iid:{xxx} } }
local _ORG_USER = {}

function _M.setCache(orguser)
    zce.log(1, "|", zce.tojson(orguser, true))
    if _ORG_USER[orguser.orgid] == nil then
        _ORG_USER[orguser.orgid] = {}
    end
    _ORG_USER[orguser.orgid][orguser.iid] = orguser
end

function _M.upsertOrgUser(orgid, iid, name, cell, memo, opencard)
    local old_orguser = nil
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj,
        "select * from users_orgs where orgid=? and iid=?",
        orgid, iid)
    lut.ensureEquals(ok, true, res)
    if not ok then
        return ok, old_orguser
    end
    if #res >= 1 then
        old_orguser = res[1]
    end
    zce.log(1, "|",ok, #res, orgid, iid, name, cell, memo)
    if old_orguser == nil then
        ok, res = zce.rdb_query(cfg.pgsqldb.dbobj,
            "insert into users_orgs(orgid, iid, name, cell, memo, opencard, regtime) values(?,?,?,?,?,?,now())",
            orgid, iid, name, cell, memo, opencard)
        lut.ensureEquals(ok, true, res)
    else
        ok, res = zce.rdb_query(cfg.pgsqldb.dbobj,
            "update users_orgs set name=?,cell=?,memo=?,opencard=?,regtime=now() where orgid=? and iid=?",
            name, cell, memo, opencard, orgid, iid)
        lut.ensureEquals(ok, true, res)
        
    end

    _M.setCache({
        orgid = orgid,
        iid = iid,
        name = name,
        cell = cell,
        memo = memo,
        opencard = opencard,
    })

    return ok, old_orguser
end

function _M.getOrgUser2(orgid, iid)
    if _ORG_USER[orgid] ~= nil and _ORG_USER[orgid][iid] ~= nil then
        return true, _ORG_USER[orgid][iid]
    end

    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj,
        "select * from users_orgs where orgid=? and iid=?",
        orgid, iid)
    lut.ensureEquals(ok, true, res)
    if not ok then
        return false, "db failed"
    end
    
    if res == nil or #res == 0 then
        return false, nil
    end

    _M.setCache(res[1])

    return ok, res[1]
end
