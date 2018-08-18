local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M
local c = require "zce.core"
local cjson = require "cjson"
local lu = require('luaunit')
local session = require("auth.session")

local ok, hawkcacheobj = c.cache_init("local", "hawk.cache")
lu.assertEquals(ok, true)

local ok, pgdb = c.cache_get(hawkcacheobj, "pgdb")
lu.assertEquals(ok, true)

local ok, redisobj = c.cache_get(hawkcacheobj, "redis")
lu.assertEquals(ok, true)

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
			0x10000000 : { --roleid
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
local _USER_ROLES = {} 

--[[
{
	iid : { org1, org2}
}
--]]
local _USER_ORG = {}

--[[
{
	orgid : {
		owneriid : xxx, orgname : xxxx
	}
}
--]]
local _ORG = {}

--获取用户所在组织列表
local function _getUserOrgs(iid)
	if (_USER_ORG[iid] ~= nil) then
		return true, _USER_ORG[iid]
	end
	local ok, res = c.rdb_query(pgdb, "select DISTINCT orgid from roles_users where iid = ?", iid)
	if not ok then
		return false, "dbquery failed"
	end

	local orgs = {}
	for i = 1, #res do
		orgs[#orgs + 1] = res[i].orgid
	end
	_USER_ORG[iid] = orgs
	return true, orgs
end

-- 获取roleid的前缀，例如 0x123400000000 得到 level 2, 0x1234
local function _getRoleIdPrefix(roleid)
	-- c.log(1, "\t", "_getRoleIdPrefix:", string.format("%x", roleid))
	if (type(roleid) ~= "number") then
		print(debug.traceback())
	end
	if (roleid == 0) then
		return 0, 0
	end
	local rev_role_level = 0
	while roleid ~= 0 do
		if (roleid & 0xff) ~= 0 then 
			return 8-rev_role_level, roleid
		end
		roleid = roleid >> 8
		rev_role_level = rev_role_level + 1
	end
	return 8-rev_role_level, roleid
end

-- 获取上一级的ROLEID，例如 0x123401000000 得到  0x123400000000
local function _getRoleIdUpperLevel(roleid)
	local level, prefix = _getRoleIdPrefix(roleid)
	prefix = prefix >> 8
	prefix = prefix << 8
	local v =  prefix << ((8 - level) * 8)
	c.log(1, "\t", "_getRoleIdUpperLevel:", level, string.format("%x", prefix), string.format("%x", v))
	return v
end

-- 查看这个是否本级管理员，例如 0x123401000000 得到  true
local function _isRoleIdAdmin(roleid)
	local level, prefix = _getRoleIdPrefix(roleid)
	return (prefix & 0xff) ==  1
end

local function _getNextRoleId(orgid, level, roleprefix)
	local public_roleid = roleprefix << ((8 - level) * 8)
	local admin_roleid = public_roleid + (1 << ((7 - level) * 8))
	local ok, res =  c.rdb_query(pgdb, "select count(*) as rownum from  roles where roleid = ? or roleid = ?", public_roleid, admin_roleid)
	if (ok and res[1].rownum < 2) then
		c.log(1, "\t", "_check_default_role:", level, string.format("%x", public_roleid), string.format("%x", admin_roleid), 1 << 8, 1 << 56)
		local ok, res = c.rdb_query(pgdb, "insert into roles(orgid, roleid, rolename, roledesc) values(?, ?, ?, ?)", orgid, public_roleid, "public", "全体成员")
		local ok, res = c.rdb_query(pgdb, "insert into roles(orgid, roleid, rolename, roledesc) values(?, ?, ?, ?)", orgid, admin_roleid, "admin", "管理员")
	end
	local ok, res = c.rdb_query(pgdb, "select roleid from roles where orgid = ? and roleid between ? and ? order by roleid desc limit 1",
		orgid, public_roleid, public_roleid + (0x7f << ((7 - level) * 8)))
	c.log(1, "\t", "_getNextRoleId", string.format("%x", res[1].roleid))
	return res[1].roleid + (1 << ((7 - level) * 8))
end

local function _getRoleChildren(orgid, roleid)
	if (not _isRoleIdAdmin(roleid)) then -- 0x1234010000000000
		return {}
	end

	roleid = _getRoleIdUpperLevel(roleid)  -- 0x1234000000000000
	if _ROLE_CHILDREN[roleid] ~= nil then 
		return _ROLE_CHILDREN[roleid]
	end

	local ok, res;

	if (roleid == 0) then
		c.log(1, "\t", "_getRoleChildren getAll:", orgid)
		ok, res = c.rdb_query(pgdb, "select roleid from roles where orgid = ? order by roleid desc", orgid)
	else
		local level, prefix = _getRoleIdPrefix(roleid)
		local next_roleid = roleid + (1 << ((7 - level) * 8)) -- 0x1235000000000000
		c.log(1, "\t", "_getRoleChildren:", string.format("%x", roleid),  string.format("%x", next_roleid))
		ok, res = c.rdb_query(pgdb, "select roleid from roles where orgid = ? and roleid >= ? and roleid < ? order by roleid desc", 
			orgid, roleid, next_roleid)
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

-- 获取ORG信息
local function _getOrg(orgid)
	if (_ORG[orgid] ~= nil) then
		return _ORG[orgid]
	end
	local ok, res = c.rdb_query(pgdb, "select * from roles_orgs where orgid = ? and enabled = true", orgid)
	if (ok and #res > 0) then
		_ORG[orgid] = res[1]
		return res[1]
	end
	return nil
end

local function _addOrg(orgname, iid)
	local ok, res = c.rdb_query(pgdb, "select * from roles_orgs where orgname = ?", orgname)
	if (ok and #res > 0) then
		local org = res[1]
		if (org.enabled) then
			return false, org
		else
			local ok, upres = c.rdb_query(pgdb, "update roles_orgs set enabled = true, owneriid= ? where orgid = ?", org.orgid, iid)
			org.enabled = true
			org.owneriid = iid
			_ORG[res[1].orgid] = org
			return true, org
		end
	end
	local ok, res = c.rdb_query(pgdb, "insert into roles_orgs(orgname, owneriid, enabled) values(?, ?, true) returning orgid", orgname, iid)
	if (ok and #res > 0) then
		local org = { ['orgid'] = res[1].orgid, ['orgname'] = orgname, ['owneriid'] = iid}
		_ORG[res[1].orgid] = org
		return true, org
	end
	return false, nil
end

local function _delOrg(orgid, iid)
	local org = _getOrg(orgid)

	if (org == nil) then
		return false, "not exists"
	end

	if (org.owneriid  ~= iid) then
		return false, "not owner"
	end

	local children = _getRoleChildren(orgid, 0) 
	if (children and #children > 0) then 
		return false, "not empty"
	end

	local ok, res = c.rdb_query(pgdb, "update roles_orgs set enabled = false where orgid = ?", orgid)
	if (ok and #res > 0) then
		_ORG[orgid] = nil
		return true
	end
	return false, "dbfailed"
end

local function _testOrg()
	local iid = 3
	local iid2 = 2

	local ok, org = _addOrg("TestOrg", iid)
	lu.assertNotEquals(org, nil)

	local ok = _delOrg(org.orgid, 0)
	lu.assertEquals(ok, false)

	local ok, err = _delOrg(org.orgid, iid)
	lu.assertEquals(ok, true)
	print (err)

	local ok, org = _addOrg("TestOrg", iid2)
	lu.assertNotEquals(org, nil)
	lu.assertEquals(org.owneriid, iid2)

	local ok = _delOrg(org.orgid, iid)
	lu.assertEquals(ok, false)

	local ok = _delOrg(org.orgid, iid2)
	lu.assertEquals(ok, true)
end

-----------------------------------------------------------------------------------------------------

function _M:createOrg(creator_iid, orgname)
	local ok, res = c.rdb_query(pgdb, "insert into roles_orgs(owneriid, orgname) values(?, ?) returning orgid", creator_iid, orgname)
	if (ok and #res > 0) then
		local role_res = res[1]
		_getNextRoleId(role_res.orgid, 0, 0)
		return role_res
	end
	return nil
end

function _M:addRole(orgid, father_roleid, name, desc)
	if (_isRoleIdAdmin(father_roleid)) then
		-- can't add role under admin
		return nil
	end
	local level, prefix = _getRoleIdPrefix(father_roleid);
	-- 
	local next_roleid = _getNextRoleId(orgid, level, prefix)
	c.log(1, "\t", "addRole:", string.format("%x", father_roleid), level, prefix,  string.format("%x", next_roleid))
	
	local ok, res = c.rdb_query(pgdb, "insert into roles(orgid, roleid, rolename, roledesc) values(?, ?, ?, ?)",
		orgid, next_roleid, name, desc)
	if not ok or #res < 1 then
		return nil
	end

	while father_roleid~=0 do
		local role_children = _ROLE_CHILDREN[father_roleid]
		if (role_children == nil) then
			role_children = {}
			_ROLE_CHILDREN[father_roleid] = role_children
		end
		role_children[#role_children + 1] = next_roleid
		father_roleid = _getRoleIdUpperLevel(father_roleid)
	end

	return { roleid = next_roleid }
end

-- 返回两个对象，第一个是具体设备的对象，第二个是角色对所有设备的集合对象
function _M:getRoleRightItem(objtable, orgid, roleid, objid, aclitem)
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

		local ok, res = c.rdb_query(pgdb, 
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
		local ok, res = c.rdb_query(pgdb, 
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

function _M:getRoleRightRecur(objtable, orgid, roleid, objid, aclitem)

	-- global admin, just allow everything
	if (_isRoleIdAdmin(roleid) and _getRoleIdUpperLevel(roleid) == 0) then
		return { [aclitem] = true }
	end

    -- check self 
	local objitem, roleitem = _M:getRoleRightItem(objtable, orgid, roleid, objid, aclitem)
	if (objitem and objitem[aclitem] == true) then
		return objitem
	end

	-- find parent share obj acl
	local father_roleid = roleid
	while father_roleid~=0 do
		father_roleid = _getRoleIdUpperLevel(father_roleid)
		c.log(1, "", "check father:", father_roleid)
		local objitem, roleitem = _M:getRoleRightItem(objtable, orgid, father_roleid, objid, aclitem)
		if (objitem and objitem[aclitem] == true) then
			return objitem
		end
	end

	-- if is admin, check children's acl
	local children = _getRoleChildren(orgid, roleid)
	c.log(1, "", "check children", c.tojson(children))
	for i = 1, #children do
		if (children[i] ~= roleid) then
			local objitem, roleitem = _M:getRoleRightItem(objtable, orgid, children[i], objid, aclitem)
			if (objitem and objitem[aclitem] == true) then
				return objitem
			end
		end
	end

	return nil
end

function _M:getRoleRightAllitem(objtable, orgid, roleid, aclitem, objitem_array)
	-- global admin, just allow everything
	if (_isRoleIdAdmin(roleid) and _getRoleIdUpperLevel(roleid) == 0) then
		local children = _getRoleChildren(orgid, roleid)
		c.log(1, "", "check children", c.tojson(children, true))
		for i = 1, #children do
			local objitem, roleitem = _M:getRoleRightItem(objtable, orgid, children[i], '*', aclitem)
			for k,v in pairs(roleitem) do objitem_array[k] = v end
		end
		return objitem_array
	end

    -- check self 
	local objitem, roleitem = _M:getRoleRightItem(objtable, orgid, roleid, '*', aclitem)
	for k,v in pairs(roleitem) do objitem_array[k] = v end

	-- find parent share obj acl
	local father_roleid = roleid
	while father_roleid~=0 do
		father_roleid = _getRoleIdUpperLevel(father_roleid)
		c.log(1, "", "check father:", father_roleid)
		local objitem, roleitem = _M:getRoleRightItem(objtable, orgid, father_roleid, '*', aclitem)
		for k,v in pairs(roleitem) do objitem_array[k] = v end
	end

	-- if is admin, check children's acl
	local children = _getRoleChildren(orgid, roleid)
	c.log(1, "", "check children", c.tojson(children))
	for i = 1, #children do
		if (children[i] ~= roleid) then
			local objitem, roleitem = _M:getRoleRightItem(objtable, orgid, children[i], '*', aclitem)
			for k,v in pairs(roleitem) do objitem_array[k] = v end
		end
	end

	return objitem_array
end

function _M:getRoleRight(objtable, orgid, roleid, objid, aclitem)
    local objitem = _M:getRoleRightRecur(objtable, orgid, roleid, objid, aclitem)
	if (objitem == nil) then
		return { [aclitem] = false }
	else
		return objitem
	end
end

function _M:setRoleRight(objtable, orgid, roleid, objid, aclitem, allow)
	local objitem, roleitem = _M:getRoleRightItem(objtable, orgid, roleid, objid, aclitem)
	if objitem == nil then
		local ok, res = c.rdb_query(pgdb, 
			"insert into " .. objtable .. "(orgid, roleid, objid, " .. aclitem .. ") values(?, ?, ?, ?)",
				orgid, roleid, objid, allow)
		lu.assertEquals(ok, true)
		objitem = { [aclitem] = allow }
		roleitem[objid] = objitem
	else
		if (objitem[aclitem] == allow) then
			return objitem
		end

		local ok, res = c.rdb_query(pgdb, 
			"update " .. objtable .. " set " .. aclitem .. " = ? where orgid = ? and roleid = ? and objid = ?",
				allow, orgid, roleid, objid)
		lu.assertEquals(ok, true)
		objitem[aclitem] = allow
	end
	return objitem
end

-----------------------------------------------------------------------------------------------------

-- 查询用户在该组织的所有角色
function _M:getUserRoles(iid, orgid)
    local iid_roleid_cache = _USER_ROLES[iid]
	if (iid_roleid_cache == nil) then
		iid_roleid_cache = {}
		_USER_ROLES[iid] = iid_roleid_cache
	end

	local role_roleid_cache = iid_roleid_cache[orgid]
	if (role_roleid_cache ~= nil) then
		return role_roleid_cache
	end

	role_roleid_cache = {}
	local ok, res = c.rdb_query(pgdb, 
		"select roleid from roles_users where iid = ? and orgid = ?", iid, orgid)
	if not ok then
		return {}
	end
	for i = 1, #res do role_roleid_cache[#role_roleid_cache + 1] = res[i].roleid end
	iid_roleid_cache[orgid] = role_roleid_cache
	return role_roleid_cache
end

local function _canAdminRole(iid, orgid, roleid)
	-- if owner ,allow
	local org = _getOrg(orgid)
	if (org ~= nil and org.owneriid == iid) then
		return true
	end

	local roles = _M:getUserRoles(iid, orgid)
	local level, prefix = _getRoleIdPrefix(roleid)
	for i = 1, #roles do
		if (_isRoleIdAdmin(roles[i])) then
			local newlevel, newprefix = _getRoleIdPrefix(roles[i])
			c.log(1, "\t", "_canAdminRole:", string.format("%x", roles[i]), level, prefix, newlevel, newprefix)
			if (newlevel <= level + 1) then
				return true
			end
		end
	end
	return false
end

-- 增加用户在该组织的所有角色
function _M:addUserRole(iid, orgid, roleid)
	local roles = _M:getUserRoles(iid, orgid)
	local allow = _canAdminRole(iid, orgid, roleid)
	if (not allow) then
		return false, "now allowed"
	end

	for i = 1, #roles do
		if (roles[i] == roleid) then
			return true
		end
	end

	local ok, res = c.rdb_query(pgdb, 
		"insert into roles_users(orgid, roleid, iid) values(?, ?, ?)", orgid, roleid, iid)
	if not ok then return false; end
	roles[#roles + 1] = roleid
	return true
end

-- 删除用户在该组织的所有角色, *表示所有
function _M:delUserRole(iid, orgid, roleid)
	if (iid == nil or orgid == nil or roleid == nil) then
		print(debug.traceback())
	end

	if (roleid == '*') then
		local allow = _canAdminRole(iid, orgid, 0)
		if (not allow) then
			return false, "now allowed"
		end

		local roles = _M:getUserRoles(iid, orgid)
		local ok, res = c.rdb_query(pgdb, 
				"delete from roles_users where iid = ? and orgid = ?", iid, orgid)
		for k in pairs (roles) do roles [k] = nil end
		return true
	end

	local allow = _canAdminRole(iid, orgid, roleid)
	if (not allow) then
		return false, "now allowed"
	end

	local roles = _M:getUserRoles(iid, orgid)
	for i = 1, #roles do
		if (roles[i] == roleid) then
			local ok, res = c.rdb_query(pgdb, 
				"delete from roles_users where orgid = ? and roleid = ? and iid = ?", orgid, roleid, iid)
			roles[i] = nil
			return true
		end
	end
	return false
end

-- 查询用户在该组织内对objtable有aclitem权限的所有对象
function _M:getUserRoleRightAllitem(objtable, iid, orgid, aclitem, objitem_array)
	local roles = _M:getUserRoles(iid, orgid)
	if (roles == nil) then
		return objitem_array
	end
	for i = 1, #roles do
		_M:getRoleRightAllitem(objtable, orgid, roles[i], aclitem, objitem_array)
	end
	return objitem_array
end

-- 查询用户在所有组织内对objtable有aclitem权限的所有对象
function _M:getUserRightAllitem(objtable, iid, aclitem)
	local ok, orgs = _getUserOrgs(iid)
	lu.ensureEquals(ok, true, orgs)

	local objitem_array = {}
	for i = 1, #orgs do
		_M:getUserRoleRightAllitem(objtable, iid, orgs[i], aclitem, objitem_array)
	end
	return ok, objitem_array
end

-----------------------------------------------------------------------------------------------------
function _M:doTestRole(useriid, orgid)
	local ok, err = _M:delUserRole(useriid, orgid, '*')
	lu.assertEquals(ok, true, err)

	local roles = _M:getUserRoles(useriid, orgid)
	lu.assertEquals(#roles, 0)

	local ok = _M:addUserRole(useriid, orgid, 0)
	lu.assertEquals(ok, true)
	local ok = _M:addUserRole(useriid, orgid, 0x100000000000000)
	lu.assertEquals(ok, true)

	local roles = _M:getUserRoles(useriid, orgid)
	lu.assertEquals(#roles, 2)

end

function _M:doTestMe()
	_testOrg()

    local orgid = 1
	local useriid = 3
	local objitem_array = {}
	_M:doTestRole(useriid, orgid)
	local objarray = _M:getUserRoleRightAllitem("dian_roles_acl_device", useriid, orgid, "indoor", objitem_array)
	c.log(1, "\t", "getUserRoleRightAllitem:", c.tojson(objarray, true))
	return objarray
end

function _M:doTestMe2()

  -- http://127.0.0.1:8080/role/createOrg?session_key=q7YTs9%2BrrMo%2FhDGGBg3%2BAA%3D%3D&appid=wxa601a1185a9afbc9&orgname=diandian
  -- http://127.0.0.1:8080/role/addRole?session_key=q7YTs9%2BrrMo%2FhDGGBg3%2BAA%3D%3D&appid=wxa601a1185a9afbc9&orgid=1&father_roleid=0&role_name=testdepartment&role_desc=desc
  -- http://127.0.0.1:8080/role/createOrg?session_key=q7YTs9%2BrrMo%2FhDGGBg3%2BAA%3D%3D&appid=wxa601a1185a9afbc9&orgname=diandian
--[[
	local dep_rd =  _M:addRole(1, 0, "R&D","研发部")
	local dep_fn =_M:addRole(1, 0, "Finacial","财务部")
	_M:addRole(1, dep_rd.roleid, "TestDepartment","测试组")
	_M:addRole(1, dep_rd.roleid, "DesignDepartment","设计组")
	_M:addRole(1, dep_fn.roleid, "In","收钱组")
	_M:addRole(1, dep_fn.roleid, "Out","付钱组")
--]]

	local father_roleid = 0x1200000000000000
	local level, prefix = _getRoleIdPrefix(father_roleid)
	lu.assertEquals(level, 1)
	lu.assertEquals(prefix, 0x12)

	local father_roleid = 0x1234000000000000
	local level, prefix = _getRoleIdPrefix(father_roleid)
	lu.assertEquals(level, 2)
	lu.assertEquals(prefix, 0x1234)

	local father_roleid = _getRoleIdUpperLevel(0x1234010000000000)
	lu.assertEquals(father_roleid, 0x1234000000000000)

	local father_roleid = _getRoleIdUpperLevel(0x1100000000000000)
	lu.assertEquals(father_roleid, 0)

	local adobj1 = _M:setRoleRight("dian_roles_acl_device", 1, 0, 4, "indoor", true)
	lu.assertEquals(adobj1["indoor"], true)

	local adobj1 = _M:setRoleRight("dian_roles_acl_device", 1, 0x100000000000000, 1, "indoor", true)
	lu.assertEquals(adobj1["indoor"], true)

	local adobj1 = _M:setRoleRight("dian_roles_acl_device", 1, 0x202000000000000, 2, "indoor", true)
	lu.assertEquals(adobj1["indoor"], true)

	local adobj1 = _M:setRoleRight("dian_roles_acl_device", 1, 0x203000000000000, 3, "indoor", true)
	lu.assertEquals(adobj1["indoor"], true)

	local adobj = _M:getRoleRight("dian_roles_acl_device", 1, 0x100000000000000, 1, "indoor")
	lu.assertEquals(adobj["indoor"], true)

	local adobj = _M:getRoleRight("dian_roles_acl_device", 1, 0x100000000000000, 2, "indoor")
	lu.assertEquals(adobj["indoor"], true)

	local adobj = _M:getRoleRight("dian_roles_acl_device", 1, 0x100000000000000, 3, "indoor")
	lu.assertEquals(adobj["indoor"], true)

	local adobj = _M:getRoleRight("dian_roles_acl_device", 1, 0x203000000000000, 4, "indoor")
	lu.assertEquals(adobj["indoor"], true)

	local adobj = _M:getRoleRight("dian_roles_acl_device", 1, 0x203000000000000, 3, "indoor")
	lu.assertEquals(adobj["indoor"], true)

	local adobj = _M:getRoleRight("dian_roles_acl_device", 1, 0x203000000000000, 2, "indoor")
	lu.assertEquals(adobj["indoor"], false)

	lu.assertEquals(_isRoleIdAdmin(0), false)

	lu.assertEquals(_isRoleIdAdmin(0x100000000000000), true)

	lu.assertEquals(_isRoleIdAdmin(0x200000000000000), false)

	lu.assertEquals(_isRoleIdAdmin(0x101000000000000), true)

	lu.assertEquals(_isRoleIdAdmin(0x202000000000000), false)

	local obj_all = {}
	local objarray = _M:getRoleRightAllitem("dian_roles_acl_device", 1, 0x202000000000000, "indoor", obj_all)
	c.log(1, "\t", "getRoleRightAllitem:", c.tojson(objarray))

	return adobj
end

function _M:procHttpReq(data)
	local bodyobj = {}
	if string.len(data.body) > 0 then
		if ( data.header['Content-Type'] ~= nil and string.match(data.header['Content-Type'], "application/json") ) then
			bodyobj = cjson.decode(data.body)
		end
	end

	local login_session  =session:getSession(data.parameters.session_key)
	if login_session == nil then 
		return nil, 401
	end

	local adobj

	if (string.match(data.path, "/role/createOrg")) then
		adobj = _M:createOrg(login_session.iid, data.parameters.orgname)
	elseif (string.match(data.path, "/role/addRole")) then
		adobj = _M:addRole(tonumber(data.parameters.orgid), tonumber( data.parameters.father_roleid), data.parameters.role_name, data.parameters.role_desc)
	elseif (string.match(data.path, "/role/getRoleRight")) then
		adobj = _M:getRoleRight(tonumber(data.parameters.orgid), tonumber( data.parameters.roleid), tonumber( data.parameters.objid), data.parameters.aclitem)
	elseif (string.match(data.path, "/role/setRoleRight")) then
		adobj = _M:setRoleRight(tonumber(data.parameters.orgid), tonumber( data.parameters.roleid), tonumber( data.parameters.objid), data.parameters.aclitem, toboolean( data.parameters.allow))
	elseif (string.match(data.path, "/role/doTestMe")) then
		adobj = _M:doTestMe();
	else
		return nil, 404
	end

	if (adobj == nil) then
		return ""
	else
		return cjson.encode(adobj), 200, { ['Content-Type'] = "application/json"}
	end
end

