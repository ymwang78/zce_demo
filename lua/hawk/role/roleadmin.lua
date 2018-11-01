--[[
    为了统一角色权限管理，
    roles_acl_user 的角色ID为用户ID，objid才是角色ID，
    即用户对于角色的权限的含义
--]]

local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require("zce.core")
local lu = require("util.luaunit")
local cjson = require("cjson")
local cfg = require("hawk.config")
local hr = require("hawk.role.role")
local hro = require("hawk.role.org")
local session = require("hawk.auth.session")
local dd = require("dian_device")

function _M.getRoleAdminIids(orgid, roleid)
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj,
        "select roleid from roles_acl_user where orgid=? and objid=? order by roleid",
        orgid,
        roleid)
    if not ok or not res then return ok, {} end

    local resdata = {}
    for i=1, #res do 
        resdata[#resdata + 1] = res[i].roleid
    end
    zce.log(1, "|", orgid, roleid, zce.tojson(resdata, true))
    return ok, resdata
end

function _M.addRoleAdmin(creatoriid, iid, orgid, roleid)
    if (creatoriid == nil or iid == nil or orgid == nil or roleid == nil) then
        print(debug.traceback())
    end

    auth_roleid = roleid
    if (roleid == '*') then
        auth_roleid = 0
    end

    local allow = hr.canAdminRole(creatoriid, orgid, auth_roleid)
    if (not allow) then
        return false, "now allowed"
    end

    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "insert into roles_acl_user(orgid, roleid, objid) values(?, ?, ?)",
        orgid,
        iid,
        roleid)
    return ok
end

function _M.delRoleAdmin(creatoriid, iid, orgid, roleid)
    if (creatoriid == nil or iid == nil or orgid == nil or roleid == nil) then
        print(debug.traceback())
    end

    auth_roleid = roleid
    if (roleid == '*') then
        auth_roleid = 0
    end

    local allow = hr.canAdminRole(creatoriid, orgid, auth_roleid)
    if (not allow) then
        return false, "now allowed"
    end

    if (roleid == '*') then
        local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
                "delete from roles_acl_user where roleid = ? and orgid = ?", 
                iid, 
                orgid)
        return true
    else
        local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
            "delete from roles_acl_user where orgid = ? and roleid = ? and objid = ?",
            orgid, 
            iid, 
            roleid)  
        return true
    end
end
