local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M
local c = require "zce.core"
local cjson = require "cjson"
local lu = require('luaunit')
local session = require("auth.session")

local ok, config = c.cache_init("local", "config")
lu.assertEquals(ok, true)

local ok, hawkcacheobj = c.cache_init("local", "hawk")
lu.assertEquals(ok, true)

local ok, pgdb = c.cache_get(config, "pgdb")
lu.assertEquals(ok, true)

local ok, redisobj = c.cache_get(config, "redis")
lu.assertEquals(ok, true)

local _ROLE_CHILDREN = {}

local _ROLE_ACL = {}

-- 获取roleid的前缀，例如 0x123400000000 得到 level 2, 0x1234
local function _getRoleIdPrefix(roleid)
	-- c.log(1, "\t", "_getRoleIdPrefix:", string.format("%x", roleid))
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
		ok, res = c.rdb_query(pgdb, "select roleid from roles where orgid = ? order by roleid desc", 
			orgid)
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
			"select objid, " .. aclitem .. " from " .. objtable .. " where orgid = ? and roleid = ?",
			orgid, roleid)
		for i = 1, #res do
			role_acl_cache[res[i].objid] = res[i]
		end
	end

	local obj_acl_cache = role_acl_cache[objid]
	if (obj_acl_cache ~= nil) then
		return obj_acl_cache, role_acl_cache
	else
		obj_acl_cache = {}
		role_acl_cache[objid] = obj_acl_cache
		local ok, res = c.rdb_query(pgdb, 
			"select " .. aclitem .. " from " .. objtable .. " where orgid = ? and roleid = ? and objid = ?",
				orgid, roleid, objid)
		if (ok and #res > 0) then
			obj_acl_cache[aclitem] = res[1][aclitem]
			return obj_acl_cache, role_acl_cache
		else
			return nil, role_acl_cache
		end
	end
end


function _M:getRoleRightRecur(objtable, orgid, roleid, objid, aclitem)

	-- global admin, just allow everything
	if (_isRoleIdAdmin(rolid) and _getRoleIdUpperLevel(roleid) == 0)
		return { [aclitem] : true }
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

function _M:doTestMe()

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

