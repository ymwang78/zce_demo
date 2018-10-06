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

function _M.upsertOrgUser(orgid, iid, name, cell, memo)
    local ok, res = zce.rdb_query(cfg.pgsqldb,
        "select count(*) as num from users_orgs where orgid=? and iid=?",
        orgid, iid)
    lut.ensureEquals(ok, true, res)
    if not ok then
        return ok
    end
    zce.log(1, "|",ok, res[1]["num"], orgid, iid, name, cell, memo)
    if res[1]["num"] == 0 then
        ok, res = zce.rdb_query(cfg.pgsqldb,
            "insert into users_orgs(orgid, iid, name, cell, memo, regtime) values(?,?,?,?,?,now())",
            orgid, iid, name, cell, memo)
        lut.ensureEquals(ok, true, res)
    else
        ok, res = zce.rdb_query(cfg.pgsqldb,
            "update users_orgs set name=?,cell=?,memo=?,regtime=now() where orgid=? and iid=?",
            name, cell, memo, orgid, iid)
        lut.ensureEquals(ok, true, res)
    end

    _M.setCache({
        orgid = orgid,
        iid = iid,
        name = name,
        cell = cell,
        memo = memo
    })

    return ok
end

function _M.getOrgUser2(orgid, iid)
    if _ORG_USER[orgid] ~= nil and _ORG_USER[orgid][iid] ~= nil then
        return true, _ORG_USER[orgid][iid]
    end

    local ok, res = zce.rdb_query(cfg.pgsqldb,
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
