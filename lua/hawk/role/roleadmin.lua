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

-- { iid : { orgid : { roleid1, roleid2 ...}}}
local _ADMIN_ORG_ROLEIDVEC = {}


-- 获取roleid的前缀，例如 0x1234 得到 level 2
local function _getRoleIdLevel(roleid)
    zce.log(1, " ", "_getRoleIdLevel", "roleid:" .. roleid)
    -- if (type(roleid) ~= "number") then
    --     print(debug.traceback())
    -- end
    if (roleid == 0) then
        return 0
    end
    local role_level = 0
    while roleid ~= 0 do
        if (roleid & 0xff) ~= 0 then 
            roleid = roleid >> 8
            role_level = role_level + 1
        else
            return role_level
        end
    end
    return role_level
end

function _M.canAdminRole(iid, orgid, roleid)
    -- if owner ,allow
    local org = hro.getOrg(orgid)
    if (org ~= nil and org.owneriid == iid) then
        zce.log(1, "|", "canAdminRole", iid, orgid, roleid, "true", "owner")
        return true
    end

    -- roles_acl_user 特殊处理，useriid作为role, roleid作为obj
    local vec = _M.getAdminRoleIdVec(iid, orgid)

    if vec == nil then
        return false
    end

    for k, v in pairs(vec) do
        if v == roleid then
            zce.log(1, "|", "canAdminRole", iid, orgid, roleid, "true", "admin")
            return true; 
        end
    end

    local level = _getRoleIdLevel(roleid)
    if level == 0 then
        return false
    end

    if aclall == nil then return false end

    local mask = 0xffffffffffffffff >> ((8-level)*8)

    for k, v in pairs(vec) do
        if ((v & mask) == (roleid & mask)) then
            zce.log(1, "|", "canAdminRole", iid, orgid, roleid, "true", "fatheradmin")
            return true; 
        end
    end

    return false    
end

-- { iid : { orgid : { roleid1, roleid2 ...}}}
function _M.getAdminRoleIdVec(iid, orgid)
    zce.log(1, "|", "getAdminRoleIdVec", "iid:" .. iid, "orgid:" .. orgid)
    local user_org_roleidvec = _ADMIN_ORG_ROLEIDVEC[iid]
    if (user_org_roleidvec == nil) then
        user_org_roleidvec = {} --{ orgid : { roleid1, roleid2 ...}}
        _ADMIN_ORG_ROLEIDVEC[iid] = user_org_roleidvec
    end

    local roleids_vec = user_org_roleidvec[orgid]
    if (roleids_vec ~= nil) then
        return roleids_vec
    end

    local roles = {}

    local org = hro.getOrg(orgid)
    if (org ~= nil and org.owneriid == iid) then
        roles[0] = true
    end

    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "select objid from roles_acl_user where roleid = ? and orgid = ? order by roleid",
        iid,
        orgid)
    if res and #res > 0 then
        for i = 1, #res do
            roles[res[i].objid] = true
        end
    end

    roleids_vec = {}

    for k, v in pairs(roles) do
        roleids_vec[#roleids_vec + 1] = k
    end

    user_org_roleidvec[orgid] = roleids_vec
    return roleids_vec
end

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

    local allow = _M.canAdminRole(creatoriid, orgid, auth_roleid)
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
