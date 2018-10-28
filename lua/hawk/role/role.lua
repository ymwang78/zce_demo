local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local c = require("zce.core")
local lu = require("util.luaunit")
local cjson = require("cjson")
local cfg = require("hawk.config")
local hr = require("hawk.role.role")
local hro = require("hawk.role.org")
local session = require("hawk.auth.session")
local dd = require("dian_device")

--[[
{
    roleid : { chile_roleid1, chile_roleid2 }
}
--]]
local _ROLE_CHILDREN = {}

--[[
{
    "dian_roles_acl_device" : { -- objtable
        1 : { -- orgid
            0x1 : { --roleid
                20201 : { -- objid
                    indoor : true
                }
            }
        }
    }
}
--]]
local _ROLE_ACL = {}

--[[
{
    iid: { 
        orgid : {
            roleid1, roleid2 
        }
    }
}
--]]
local _USER_ORG_ROLEIDVEC = {} 

--[[
{
    iid : { orgid1: true, orgid2: true}
}
--]]
local _USER_ORG = {}

--[[
{
    orgid : {
        roleid : { orgid : xxx, roleid : xxx, rolename : xxx, roledesc : xxx},
    }
}
--]]
local _ROLES = {}

--[[
{
    orgid:{
        roleid : {iids...}
    }
}
--]]
local _ORG_ROLE_IID = {}
-------------------------------------------------------------------------------
-- 0级角色ID 0x00 
-- 1级角色ID 0x01   0x02
-- 2级角色ID 0x0102 0x0202

function _M.clearUserRoleCache(iid)
    _USER_ORG_ROLEIDVEC[iid] = nil
    _USER_ORG[iid] = nil
end

-- 获取roleid的前缀，例如 0x1234 得到 level 2
local function _getRoleIdLevel(roleid)
    c.log(1, " ", "_getRoleIdLevel", "roleid:" .. roleid)
    -- if (type(roleid) ~= "number") then
    --     print(debug.traceback())
    -- end
    if (roleid == 0 or roleid == 1) then
        return 0
    end
    local role_level = 0
    while roleid ~= 0 do
        if (roleid & 0xff) ~= 0 and roleid ~= 1 then 
            roleid = roleid >> 8
            role_level = role_level + 1
        else
            return role_level
        end
    end
    return role_level
end

-- 获取上一级的ROLEID，例如 0x011234 得到  0x1234
local function _getRoleIdUpperLevel(roleid)
    local level = _getRoleIdLevel(roleid)
    local uproleid = roleid & (0xffffffffffffffff >> ((8-(level - 1)) * 8))
    c.log(1, "|", "_getRoleIdUpperLevel", level, 'x' .. string.format("%x", roleid), string.format("%x", uproleid))
    return uproleid
end

-- 查看这个是否本级管理员，例如 0x011234 得到  true
local function _isRoleIdAdmin(roleid)
    local level = _getRoleIdLevel(roleid)
    local isadmin = ((roleid >> (level * 8)) & 0xff) ==  1
    c.log(1, "|", "_isRoleIdAdmin", "roleid:" .. roleid, isadmin)
    return isadmin
end

local function _getNextRoleId(orgid, father_roleid)
    local level = _getRoleIdLevel(father_roleid) -- 0x1234
    local public_roleid = father_roleid
    local admin_roleid = father_roleid + (1 << (level * 8))
    local father_mask =0xffffffffffffffff - (0xffffffffffffffff << ((level+0)*8))
    local mask = 0xffffffffffffffff - (0xffffffffffffffff << ((level+1)*8))
    local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
        [[select * from (select (roleid & ?) as role_id, (roleid & ?) as father_roleid from roles where orgid = ?) as foo where foo.father_roleid = ? order by foo.role_id desc limit 1]],
        mask, father_mask, orgid, father_roleid)
    c.log(1, "|", "_getNextRoleId",
        level,
        father_roleid, 
        string.format("x%x", mask), 
        string.format("x%x", father_mask),
        orgid, 
        string.format("x%x", father_roleid))
    if (res[1].role_id == res[1].father_roleid) then
        return res[1].role_id + (2 << (level * 8))
    end
    return res[1].role_id + (1 << (level * 8))
end

function _M.getRoleAdminId(roleid)
    if (_isRoleIdAdmin(roleid)) then
        return roleid
    end
    local level = _getRoleIdLevel(roleid)
    return roleid + (1 << ((level) * 8))
end

function _M.getRoleNonAdminId(roleid)
    if (not _isRoleIdAdmin(roleid)) then
        return roleid
    end
    return _getRoleIdUpperLevel(roleid)
end

function _M._getRole2(orgid, roleid)
    c.log(1, " ", "getRole2:", "orgid:" .. orgid, "roleid:" .. roleid)

    if (_ROLES[orgid] ~= nil) then
        local org_roles = _ROLES[orgid]
        if (org_roles[roleid] ~= nil) then
            return true, org_roles[roleid]
        end

        local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, "select * from roles where orgid = ? and roleid = ? order by roleid", orgid, roleid)
        if not ok or #res == 0 then
            return false, nil
        end
        if (_isRoleIdAdmin(res[1].roleid)) then
            res[1].isadmin = true
        end
        org_roles[res[1].roleid] = res[1]
        return true, res[1]
    end

    local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, "select * from roles where orgid = ? order by roleid", orgid)
    if not ok or #res == 0 then
        return false, nil
    end
    local org_roles = {}
    for i = 1, #res do
        if (_isRoleIdAdmin(res[i].roleid)) then
            res[i].isadmin = true
        end
        org_roles[res[i].roleid] = res[i]
        c.log(1, " ", "getRole2:", "orgid:" .. orgid, c.tojson(res[i], true))
    end

    _ROLES[orgid] = org_roles
    if org_roles[roleid] == nil then
        return false, nil
    end
    return true, org_roles[roleid]
end

function _M.checkRoleRoot(orgid, roleid, owneriid)
    c.log(1, " ", "checkRoleRoot:", "roleid:" .. roleid)
    local level = _getRoleIdLevel(roleid) -- 0x1234
    local public_roleid = roleid
    local admin_roleid = roleid + (1 << (level * 8))

    local ok, res =  c.rdb_query(cfg.pgsqldb.dbobj, "select count(*) as rownum from roles where orgid = ? and roleid = ?", orgid, public_roleid)
    if (ok and res[1].rownum < 1) then
        local ok, res = c.rdb_query(cfg.pgsqldb.dbobj,
            "insert into roles(orgid, roleid, owneriid, rolename, roledesc) values(?, ?, ?, ?, ?)",
            orgid, public_roleid, owneriid, "全体成员", "普通成员")
    end    

    local ok, res =  c.rdb_query(cfg.pgsqldb.dbobj, "select count(*) as rownum from roles where orgid = ? and roleid = ?", orgid, admin_roleid)
    if (ok and res[1].rownum < 1) then
        local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
            "insert into roles(orgid, roleid, owneriid, rolename, roledesc) values(?, ?, ?, ?, ?)",
            orgid, admin_roleid, owneriid, "管理员", "管理成员")
    end
end

function _M.getRole2(orgid, roleid)
    local ok, role = _M._getRole2(orgid, roleid)
    if ((not ok or role == nil) and (roleid == 0 or roleid == 1)) then
        local org = hro.getOrg(orgid)
        _M.checkRoleRoot(orgid, 0, org.owneriid)
        return _M._getRole2(orgid, roleid)
    end
    return ok, role 
end

function _M.addRole(orgid, father_roleid, owneriid, name, desc)
    c.log(1, " ", "addRole:", father_roleid)

    if (_isRoleIdAdmin(father_roleid)) then
        -- can't add role under admin
        return nil
    end

    if owneriid == nil then
        owneriid = 0
    end

    local next_roleid = _getNextRoleId(orgid, father_roleid)
    c.log(1, "\t", "addRole:", string.format("%x", father_roleid), string.format("%x", next_roleid))
    
    local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, "insert into roles(orgid, roleid, owneriid, rolename, roledesc) values(?, ?, ?, ?, ?)",
        orgid, next_roleid, owneriid, name, desc)
    if not ok or #res < 1 then
        return nil
    end

    while father_roleid ~= 0 do
        local role_children = _ROLE_CHILDREN[father_roleid]
        if (role_children == nil) then
            role_children = {}
            _ROLE_CHILDREN[father_roleid] = role_children
        end
        role_children[#role_children + 1] = next_roleid
        father_roleid = _getRoleIdUpperLevel(father_roleid)
    end

    return next_roleid
end

function _M.updateRole2(orgid, roleid, owneriid, rolename, roledesc)
    local ok, role = _M.getRole2(orgid, roleid)
    if (not ok or role == nil) then
        c.log(1, " ", "updateRole2 not found:", orgid, roleid)
        return false, nil
    end

    local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, "update roles set owneriid=?, rolename=?, roledesc=? where orgid=? and roleid=?",
        owneriid, rolename, roledesc, orgid, roleid)

    if not ok then
        c.log(1, " ", "updateRole2 update:", ok, res)
        return false, nil
    end

    role.owneriid = owneriid
    role.rolename = rolename
    role.roledesc = roledesc

    return true, role
end

function _M.deleteRole(orgid, roleid)
    local ok, role = _M.getRole2(orgid, roleid)
    if (not ok or role == nil) then
        return false
    end

    local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, "delete from roles where orgid=? and roleid=?",
        orgid, roleid)

    if not ok then
        return false
    end

    _ROLES[orgid][roleid] = nil

    while father_roleid ~= 0 do
        local role_children = _ROLE_CHILDREN[father_roleid]
        if (role_children == nil) then
            return true
        end
        for i=1, #role_children do
            if role_children[i] == roleid then
                role_children[i] = role_children[#role_children]
                role_children[#role_children] = nil
                break
            end
        end
        father_roleid = _getRoleIdUpperLevel(father_roleid)
    end
    return true
end

--获取用户所在组织列表 { orgid1 : true, orgid2 : true,}
local function _getUserOrgs(objtable, iid)
    if (_USER_ORG[iid] ~= nil) then
        return true, _USER_ORG[iid]
    end

    local orgs = {}

    local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
        "select DISTINCT orgid from roles_users where iid = ? and orgid in (select DISTINCT orgid from " .. objtable .. ")", iid)
    if not ok then
        return false, "dbquery failed"
    end

    for i = 1, #res do
        c.log(1, " ", "_getUserOrgs roles_users:", res[i].orgid)
        orgs[res[i].orgid] = true
    end

    -- and orgid in (select DISTINCT orgid from " .. objtable .. ")
    local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
        "select orgid from roles_orgs where owneriid = ? and enabled = true", iid)
    if not ok then
        return false, "dbquery failed"
    end

    for i = 1, #res do
        -- c.log(1, " ", "_getUserOrgs roles_orgs:", res[i].orgid)
        orgs[res[i].orgid] = true
    end

    _USER_ORG[iid] = orgs
    return true, orgs
end

-- 只获取子部门列表，不包含自身以及孙部门
function _M.getRoleDirectChildrenIds(orgid, roleid)
    c.log(1, "|", "getRoleDirectChildrenIds ", "orgid:" .. orgid, "roleid:x" .. string.format("%x", roleid))
   
    local ok, res;

    local level = _getRoleIdLevel(roleid)
    local roleid_prefix = roleid - (roleid >> (level*8) << (level*8))
    local next_startroleid = roleid_prefix + (2 << (level * 8)) -- 0x3512
    local next_endroleid = roleid_prefix + (255 << (level * 8)) -- 0x3512
    local mask = 0xffffffffffffffff - (0xffffffffffffffff << (level*8))
    c.log(1, "|", "getRoleDirectChildrenIds:",
        string.format("%d", orgid),
        string.format("x%x", mask),
        string.format("x%x", roleid),
        string.format("x%x", roleid_prefix),
        string.format("x%x", next_startroleid),
        string.format("x%x", next_endroleid),
        string.format("%d", next_endroleid)
        )
    ok, res = c.rdb_query(cfg.pgsqldb.dbobj, "select roleid from roles where orgid = ? and (roleid & ?) = ? and roleid between ? and ? order by roleid", 
        orgid, mask, roleid, next_startroleid, next_endroleid)
    
    if not ok then
        return {}
    end

    role_children = {}
    for i = 1, #res do
        role_children[i] = res[i].roleid
    end
    _ROLE_CHILDREN[roleid] = role_children
    return role_children
end

--获取所有自身，子部门，孙部门的列表
function _M.getRoleChildrenIds(orgid, roleid)
    c.log(1, "|", "getRoleChildrenIds ", "orgid:" .. orgid, "roleid:x" .. string.format("%x", roleid))
   
    local ok, res;

    if (roleid == 0) then
        ok, res = c.rdb_query(cfg.pgsqldb.dbobj, "select roleid from roles where orgid = ? order by roleid", orgid)
        c.log(1, "|", "getRoleChildrenIds getAll: ", "orgid:" .. orgid, "reslen:" .. #res)
    else
        local level = _getRoleIdLevel(roleid)
        -- local next_roleid = roleid + (1 << (level * 8)) -- 0x3512
        local mask = 0xffffffffffffffff - (0xffffffffffffffff << (level*8))
        c.log(1, "|", "getRoleChildrenIds:", string.format("%x", roleid),  string.format("%x", mask))
        ok, res = c.rdb_query(cfg.pgsqldb.dbobj, "select roleid from roles where orgid = ? and (roleid & ?) = ? order by roleid", 
            orgid, mask, roleid, roleid)
    end
    if not ok then
        return {}
    end

    role_children = {}
    for i = 1, #res do
        role_children[i] = res[i].roleid
    end
    _ROLE_CHILDREN[roleid] = role_children
    return role_children
end

-----------------------------------------------------------------------------------------------------

-- 返回两个对象，第一个是具体设备的对象，第二个是角色对所有设备的集合对象
function _M.getRoleRightItem(objtable, orgid, roleid, objid, aclitem)
    c.log(1, " ", "getRoleRightItem:", objtable, orgid, roleid, objid, aclitem)

    local root_acl_cache = _ROLE_ACL[objtable]
    if (root_acl_cache == nil) then
        root_acl_cache = {}
        _ROLE_ACL[objtable] = root_acl_cache
    end

    local org_acl_cache = root_acl_cache[orgid]
    if (org_acl_cache == nil) then
        org_acl_cache = {}
        root_acl_cache[orgid] = org_acl_cache
    end

    local role_acl_cache = org_acl_cache[roleid]
    if (role_acl_cache == nil) then
        role_acl_cache = {}
        org_acl_cache[roleid] = role_acl_cache

        local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
            "select * from " .. objtable .. " where orgid = ? and roleid = ?", -- objid, " .. aclitem .. "
            orgid, roleid)
        for i = 1, #res do
            -- c.log(1, "\t", "getRoleRightItem:", c.tojson(res[i]))
            role_acl_cache[res[i].objid] = res[i]
        end
    end

    if (objid == '*') then
        return nil, role_acl_cache
    end

    local obj_acl_cache = role_acl_cache[objid]
    if (obj_acl_cache ~= nil) then
        return obj_acl_cache, role_acl_cache
    else
        local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
            "select * from " .. objtable .. " where orgid = ? and roleid = ? and objid = ?", -- " .. aclitem .. "
                orgid, roleid, objid)
        if (ok and #res > 0) then
            obj_acl_cache = res[1]
            role_acl_cache[objid] = obj_acl_cache
            return obj_acl_cache, role_acl_cache
        else
            return nil, role_acl_cache
        end
    end
end

function _M.getRoleRightRecur(objtable, orgid, roleid, objid, aclitem)

    -- global admin, just allow everything
    if (_isRoleIdAdmin(roleid) and _getRoleIdUpperLevel(roleid) == 0) then
        return { [aclitem] = true }
    end

    -- check self 
    local objitem, roleitem = _M.getRoleRightItem(objtable, orgid, roleid, objid, aclitem)
    if (objitem and objitem[aclitem] == true) then
        return objitem
    end

    -- find parent share obj acl
    local father_roleid = roleid
    while father_roleid~=0 do
        father_roleid = _getRoleIdUpperLevel(father_roleid)
        c.log(1, "", "check father:", father_roleid)
        local objitem, roleitem = _M.getRoleRightItem(objtable, orgid, father_roleid, objid, aclitem)
        if (objitem and objitem[aclitem] == true) then
            return objitem
        end
    end

    -- if is admin, check children's acl
    local children = _M.getRoleChildrenIds(orgid, roleid)
    c.log(1, "", "check children", c.tojson(children))
    for i = 1, #children do
        if (children[i] ~= roleid) then
            local objitem, roleitem = _M.getRoleRightItem(objtable, orgid, children[i], objid, aclitem)
            if (objitem and objitem[aclitem] == true) then
                return objitem
            end
        end
    end

    return nil
end

-- 返回 { { devid: { aclojb} }, ... }
function _M.getRoleRightAllItemDict(objtable, orgid, roleid, aclitem, objitem_array)
    c.log(1, " ", "getRoleRightAllItemDict:", "objtable:" .. objtable, "orgid:" .. orgid, "roleid:" .. roleid, "aclitem:" .. aclitem)
    -- global admin, just allow everything
    if (roleid == 1) then
        local ok, devs = dd.getUnitDianDevice(orgid)
        if not ok or #devs == 0 then
            return {}
        end
        for k,v in pairs(devs) do 
            objitem_array[v.devid] = { orgid = orgid, roleid = roleid, objid = v.devid, admin = true}
        end
        -- c.log(1, " ", "getUnitDianDevice:", ok, c.tojson(objitem_array, true))
        return objitem_array
    end

    -- check self 
    local objitem, roleitem = _M.getRoleRightItem(objtable, orgid, roleid, '*', aclitem)
    for k,v in pairs(roleitem) do objitem_array[k] = v end

    -- find parent share obj acl
    local father_roleid = roleid
    while father_roleid~=0 do
        father_roleid = _getRoleIdUpperLevel(father_roleid)
        c.log(1, "", "check father:", father_roleid)
        local objitem, roleitem = _M.getRoleRightItem(objtable, orgid, father_roleid, '*', aclitem)
        for k,v in pairs(roleitem) do objitem_array[k] = v end
    end

    -- if is admin, check children's acl
    if (_isRoleIdAdmin(roleid)) then
        local uproleid = _getRoleIdUpperLevel(roleid)
        local children = _M.getRoleChildrenIds(orgid, uproleid)
        c.log(1, "", "check children", c.tojson(children))
        for i = 1, #children do
            if (children[i] ~= roleid) then
                local objitem, roleitem = _M.getRoleRightItem(objtable, orgid, children[i], '*', aclitem)
                for k,v in pairs(roleitem) do objitem_array[k] = v end
            end
        end
    end

    return objitem_array
end

function _M.getRoleRight(objtable, orgid, roleid, objid, aclitem)
    local objitem = _M.getRoleRightRecur(objtable, orgid, roleid, objid, aclitem)
    if (objitem == nil) then
        return { [aclitem] = false }
    else
        return objitem
    end
end

function _M.setRoleRight(objtable, orgid, roleid, objid, aclitem, allow)
    local objitem, roleitem = _M.getRoleRightItem(objtable, orgid, roleid, objid, aclitem)
    if objitem == nil then
        local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
            "insert into " .. objtable .. "(orgid, roleid, objid, " .. aclitem .. ") values(?, ?, ?, ?)",
                orgid, roleid, objid, allow)
        lu.assertEquals(ok, true)
        objitem = { [aclitem] = allow }
        roleitem[objid] = objitem
    else
        if (objitem[aclitem] == allow) then
            return objitem
        end

        local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
            "update " .. objtable .. " set " .. aclitem .. " = ? where orgid = ? and roleid = ? and objid = ?",
                allow, orgid, roleid, objid)
        lu.assertEquals(ok, true)
        objitem[aclitem] = allow
    end
    return objitem
end


function _M.getRoleUserIds2(orgid, roleid)
    if (_ORG_ROLE_IID[orgid] == nil) then
        _ORG_ROLE_IID[orgid] = {}
    end
    local roleid_iids = _ORG_ROLE_IID[orgid]
    if (roleid_iids[roleid] == nil) then
        roleid_iids[roleid] = {}
    else
        return true, roleid_iids[roleid]
    end

    local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
        "select iid from roles_users where orgid=? and roleid=?", orgid, roleid)
    if not ok then
        return false, "dbquery failed"
    end

    local iids = {}
    for i = 1, #res do
        iids[#iids + 1] = res[i].iid
    end
    roleid_iids[roleid] = iids
    return true, iids
end
-----------------------------------------------------------------------------------------------------

-- 查询用户在该组织的所有角色
function _M.getUserRoleIdVec(iid, orgid)
    c.log(1, " ", "getUserRoleIdVec:", "iid:" .. iid, "orgid:" .. orgid)
    local user_org_roleidvec = _USER_ORG_ROLEIDVEC[iid]
    if (user_org_roleidvec == nil) then
        user_org_roleidvec = {} --{ orgid : { roleid1, roleid2 ...}}
        _USER_ORG_ROLEIDVEC[iid] = user_org_roleidvec
    end

    local roleids_vec = user_org_roleidvec[orgid]
    if (roleids_vec ~= nil) then
        return roleids_vec
    end

    roleids_vec = {}
    local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
        "select roleid from roles_users where iid = ? and orgid = ?", iid, orgid)
    if not ok then
        return {}
    end

    local is_root_admin = false
    for i = 1, #res do 
        roleids_vec[#roleids_vec + 1] = res[i].roleid
        if (res[i].roleid == 1) then
            is_root_admin = true
        end
    end

    if not is_root_admin then
        local org = hro.getOrg(orgid)
        if (org.owneriid == iid) then
            is_root_admin = true
            roleids_vec[#roleids_vec + 1] = 1
        end
    end

    user_org_roleidvec[orgid] = roleids_vec
    return roleids_vec
end

function _M.canAdminRole(iid, orgid, roleid)
    c.log(1, "|", "_canAdminRole", iid, orgid, roleid)
    -- if owner ,allow
    local org = hro.getOrg(orgid)
    if (org ~= nil and org.owneriid == iid) then
        return true
    end

    local roleids = _M.getUserRoleIdVec(iid, orgid)
    for i = 1, #roleids do
        if (_isRoleIdAdmin(roleids[i])) then
            local level = _getRoleIdLevel(roleids[i]) - 1
            local mask = 0xffffffffffffffff >> ((8-level)*8)
            c.log(1, "\t", "_canAdminRole:", string.format("%x", roleid),  string.format("%x", roleids[i]), level, newlevel)
            if ((roleids[i] & mask) == (roleid & mask)) then
                return true
            end
        end
    end
    return false    
end
-- 查询用户在该组织的所有角色
function _M.getUserOrgRoles2(iid, orgid, roles)
    c.log(1, "|", "getUserOrgRoles2", "iid:" .. iid, "orgid:" .. orgid, "roles:" .. c.tojson(roles, true))

    local roleids = _M.getUserRoleIdVec(iid, orgid)
    for i = 1, #roleids do
        local ok, role = _M.getRole2(orgid, roleids[i])
        if ok and role ~= nil then
            if (_isRoleIdAdmin(roleids[i])) then
                role.isadmin = true
            end
            roles[#roles + 1] = role
        end
    end

    return true, roles
end

-- 查询用户在该组织的所有管理员角色
function _M.getUserOrgAdminRoles2(iid, orgid, adminroles)
    local roles = {}
    local ok, roles = getUserOrgRoles2(iid, orgid, roles)

    for i = 1, #roles do 
        if (roles[i].isadmin) then
            adminroles[#adminroleids + 1] = roles[i]
        end
    end

    return true, adminroles
end

-- 增加用户在该组织的角色
function _M.addUserRole(creatoriid, iid, orgid, roleid)
    c.log(1, "|", "addUserRole", creatoriid, iid, orgid, roleid)
    local roles = _M.getUserRoleIdVec(iid, orgid)
    local allow = _M.canAdminRole(creatoriid, orgid, roleid)
    if (not allow) then
        return false, "now allowed"
    end

    for i = 1, #roles do
        if (roles[i] == roleid) then
            return true
        end
    end

    local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
        "insert into roles_users(orgid, roleid, iid) values(?, ?, ?)", orgid, roleid, iid)
    if not ok then return false; end
    roles[#roles + 1] = roleid

    _M.clearUserRoleCache(iid)
    _ORG_ROLE_IID = {}
    return true
end

-- 删除用户在该组织的所有角色, *表示所有
function _M.delUserRole(creatoriid, iid, orgid, roleid)
    if (creatoriid == nil or iid == nil or orgid == nil or roleid == nil) then
        print(debug.traceback())
    end

    if (roleid == '*') then
        local allow = _canAdminRole(creatoriid, orgid, 0)
        if (not allow) then
            return false, "now allowed"
        end

        local roles = _M.getUserRoleIdVec(iid, orgid)
        local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
                "delete from roles_users where iid = ? and orgid = ?", iid, orgid)
        for k,v in pairs (roles) do
            roles [k] = nil
        end

        _M.clearUserRoleCache(iid)
        _ORG_ROLE_IID = {}
        return true
    end

    local allow = _M.canAdminRole(creatoriid, orgid, roleid)
    if (not allow) then
        return false, "now allowed"
    end

    local roles = _M.getUserRoleIdVec(iid, orgid)
    for i = 1, #roles do
        if (roles[i] == roleid) then
            local ok, res = c.rdb_query(cfg.pgsqldb.dbobj, 
                "delete from roles_users where orgid = ? and roleid = ? and iid = ?", orgid, roleid, iid)

            _USER_ORG[iid] = {}
            _ORG_ROLE_IID = {}
            
            roles[i] = nil
            return true
        end
    end
    return false
end

-- 查询用户在该组织内对objtable有aclitem权限的所有对象
function _M.getUserRoleRightAllitem(objtable, iid, orgid, aclitem, objitem_array)
    local roleids = {}
    local org = hro.getOrg(orgid)
    if (org == nil) then
        c.log(1, " ", orgid, "not exists")
        return objitem_array
    end
    if (iid == org.owneriid) then 
        roleids[#roleids + 1] = 1
    else
        roleids = _M.getUserRoleIdVec(iid, orgid)
        if (roleids == nil) then
            return objitem_array
        end
    end

    for i = 1, #roleids do
        _M.getRoleRightAllItemDict(objtable, orgid, roleids[i], aclitem, objitem_array)
    end
    return objitem_array
end

-- 查询用户在所有组织内对objtable有aclitem权限的所有对象
function _M.getUserRightAllitem(objtable, iid, aclitem)
    local ok, orgids = _getUserOrgs(objtable, iid)
    lu.ensureEquals(ok, true, orgids)
    c.log(1, "\t", "getUserRightAllitem", "iid:" .. iid, c.tojson(orgids, true))

    local objitem_array = {}
    for k in pairs(orgids) do
        _M.getUserRoleRightAllitem(objtable, iid, k, aclitem, objitem_array)
    end
    return ok, objitem_array
end

function _M.getUserOrgs(objtable, iid)
    local ok, orgids = _getUserOrgs(objtable, iid)
    lu.ensureEquals(ok, true, orgs)

    local orgs = {}
    for k in pairs(orgids) do
        c.log(1, "\t", "getUserOrgs:", k)
        local org = hro.getOrg(k)
        if org ~= nil then
            orgs[org.orgid] = org
        end
    end

    return orgs
end

-- 查询用户在所有组织内对objtable有aclitem权限的所有对象
function _M.getUserAllRoles2(objtable, iid)
    local ok, orgids = _getUserOrgs(objtable, iid)
    lu.ensureEquals(ok, true, orgids)

    c.log(1, "\t", "getUserAllRoles2:", c.tojson(orgids, true))
    local roles = {}

    for k in pairs(orgids) do
        --c.log(1, "\t", "getUserAllRoles2:", c.tojson(roles, true))
        local ok, roles = _M.getUserOrgRoles2(iid, k, roles)
        --c.log(1, "\t", "getUserAllRoles2:", c.tojson(roles, true))
    end
    return ok, roles
end

-----------------------------------------------------------------------------------------------------
function _M.doTestRole(useriid, orgid)

    local ok, err = _M.addRole(orgid, 0, 0, 'testrole', 'testroledesc')

    local ok, err = _M.delUserRole(useriid, orgid, '*')
    lu.assertEquals(ok, true, err)

    local roles = _M.getUserRoleIdVec(useriid, orgid)
    lu.assertEquals(#roles, 0)

    local ok = _M.addUserRole(useriid, orgid, 0)
    lu.assertEquals(ok, true)
    local ok = _M.addUserRole(useriid, orgid, 0x1)
    lu.assertEquals(ok, true)

    local roles = _M.getUserRoleIdVec(useriid, orgid)
    lu.assertEquals(#roles, 2)
end

function _M.doTestMe()
    -- _M.doTestMe2()

    local orgid = 1
    local useriid = 3
    local objitem_array = {}
    _M.doTestRole(useriid, orgid)
    local objarray = _M.getUserRoleRightAllitem("dian_roles_acl_device", useriid, orgid, "indoor", objitem_array)
    c.log(1, "\t", "getUserRoleRightAllitem:", c.tojson(objarray, true))
    return objarray
end

function _M.doTestMe2()

  -- http://127.0.0.1:8080/role/createOrg?session_key=q7YTs9%2BrrMo%2FhDGGBg3%2BAA%3D%3D&appid=wxa601a1185a9afbc9&orgname=diandian
  -- http://127.0.0.1:8080/role/addRole?session_key=q7YTs9%2BrrMo%2FhDGGBg3%2BAA%3D%3D&appid=wxa601a1185a9afbc9&orgid=1&father_roleid=0&role_name=testdepartment&role_desc=desc
  -- http://127.0.0.1:8080/role/createOrg?session_key=q7YTs9%2BrrMo%2FhDGGBg3%2BAA%3D%3D&appid=wxa601a1185a9afbc9&orgname=diandian
--[[
    local dep_rd =  _M.addRole(1, 0, 0, "R&D","研发部")
    local dep_fn =_M.addRole(1, 0, 0, "Finacial","财务部")
    _M.addRole(1, dep_rd.roleid, 0, "TestDepartment","测试组")
    _M.addRole(1, dep_rd.roleid, 0, "DesignDepartment","设计组")
    _M.addRole(1, dep_fn.roleid, 0, "In","收钱组")
    _M.addRole(1, dep_fn.roleid, 0, "Out","付钱组")
--]]

    local father_roleid = 0x12
    local level = _getRoleIdLevel(father_roleid)
    lu.assertEquals(level, 1)

    local father_roleid = 0x1234
    local level = _getRoleIdLevel(father_roleid)
    lu.assertEquals(level, 2)

    local father_roleid = _getRoleIdUpperLevel(0x011234)
    lu.assertEquals(father_roleid, 0x1234)

    local father_roleid = _getRoleIdUpperLevel(0x11)
    lu.assertEquals(father_roleid, 0)

    local adobj1 = _M.setRoleRight("dian_roles_acl_device", 1, 0, 4, "indoor", true)
    lu.assertEquals(adobj1["indoor"], true)

    local adobj1 = _M.setRoleRight("dian_roles_acl_device", 1, 0x1, 1, "indoor", true)
    lu.assertEquals(adobj1["indoor"], true)

    local adobj1 = _M.setRoleRight("dian_roles_acl_device", 1, 0x202, 2, "indoor", true)
    lu.assertEquals(adobj1["indoor"], true)

    local adobj1 = _M.setRoleRight("dian_roles_acl_device", 1, 0x302, 3, "indoor", true)
    lu.assertEquals(adobj1["indoor"], true)

    local adobj = _M.getRoleRight("dian_roles_acl_device", 1, 0x1, 1, "indoor")
    lu.assertEquals(adobj["indoor"], true)

    local adobj = _M.getRoleRight("dian_roles_acl_device", 1, 0x1, 2, "indoor")
    lu.assertEquals(adobj["indoor"], true)

    local adobj = _M.getRoleRight("dian_roles_acl_device", 1, 0x1, 3, "indoor")
    lu.assertEquals(adobj["indoor"], true)

    local adobj = _M.getRoleRight("dian_roles_acl_device", 1, 0x302, 4, "indoor")
    lu.assertEquals(adobj["indoor"], true)

    local adobj = _M.getRoleRight("dian_roles_acl_device", 1, 0x302, 3, "indoor")
    lu.assertEquals(adobj["indoor"], true)

    local adobj = _M.getRoleRight("dian_roles_acl_device", 1, 0x302, 2, "indoor")
    lu.assertEquals(adobj["indoor"], false)

    lu.assertEquals(_isRoleIdAdmin(0), false)

    lu.assertEquals(_isRoleIdAdmin(0x1), true)

    lu.assertEquals(_isRoleIdAdmin(0x2), false)

    lu.assertEquals(_isRoleIdAdmin(0x102), true)

    lu.assertEquals(_isRoleIdAdmin(0x202), false)

    local obj_all = {}
    local objarray = _M.getRoleRightAllItemDict("dian_roles_acl_device", 1, 0x202, "indoor", obj_all)
    c.log(1, "\t", "getRoleRightAllItemDict:", c.tojson(objarray))

    return adobj
end

function _M.procHttpReq(data)
    local bodyobj = {}
    if string.len(data.body) > 0 then
        if ( data.header['Content-Type'] ~= nil and string.match(data.header['Content-Type'], "application/json") ) then
            bodyobj = cjson.decode(data.body)
        end
    end

    local login_session  =session.getSession(data.parameters.session_key)
    if login_session == nil then 
        return nil, 401
    end

    local adobj

    if (string.match(data.path, "/role/addOrg")) then
        adobj = _M.addOrg(login_session.iid, data.parameters.orgname)
    elseif (string.match(data.path, "/role/addRole")) then
        adobj = _M.addRole(data.parameters.orgid, data.parameters.father_roleid, data.parameters.owneriid, data.parameters.role_name, data.parameters.role_desc)
    elseif (string.match(data.path, "/role/getRoleRight")) then
        adobj = _M.getRoleRight(data.parameters.orgid, data.parameters.roleid, data.parameters.objid, data.parameters.aclitem)
    elseif (string.match(data.path, "/role/setRoleRight")) then
        adobj = _M.setRoleRight(data.parameters.orgid, data.parameters.roleid, data.parameters.objid, data.parameters.aclitem, toboolean( data.parameters.allow))
    elseif (string.match(data.path, "/role/doTestMe")) then
        adobj = _M.doTestMe();
    else
        return nil, 404
    end

    if (adobj == nil) then
        return ""
    else
        return cjson.encode(adobj), 200, { ['Content-Type'] = "application/json"}
    end
end

