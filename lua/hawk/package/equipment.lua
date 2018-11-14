--[[
    ��ģ��ʵ��װ��ϵͳ��װ��ϵͳ�Ǳ���ϵͳ��һ���֣���˱��ļ�����ɾ����ʹ�ñ���ϵͳ����
    iid �û�ID
    equipment_typeid װ������ID������ Ӣ��/����/��
    equipment_id װ��ID���ڼ���
--]]

local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require("zce.core")
local cjson = require("cjson")
local lut = require("util.luaunit")
local util = require("util.util")
local cfg = require("hawk.config")

local __SQL_INITDB = [[
CREATE TABLE public.users_equipment
(
    iid integer NOT NULL,
    equipment_typeid integer NOT NULL,
    equipment_id integer NOT NULL,
    properties jsonb  NOT NULL,
    CONSTRAINT users_equipment_pkey PRIMARY KEY (iid, equipment_typeid, equipment_id)
)
WITH (
    OIDS = FALSE
);
]]

function _M.addEquipment(iid, eqtypeid, eqid, eqprops)
    local json_text = cjson.encode(eqprops)
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "insert into users_equipment(iid, equipment_typeid, equipment_id, properties) values(?, ?, ?, ?)",
        iid, eqtypeid, eqid, json_text)
    return ok, res
end

function _M.saveEquipment(iid, eqtypeid, eqid, eqprops)
    local json_text = cjson.encode(eqprops)
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "update users_equipment set properties = ? where iid=? and equipment_typeid=? and equipment_id=?",
        json_text, iid, eqtypeid, eqid)
    return ok, res
end

function _M.getEquipmentByTypeId(iid, eqtypeid)
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "select equipment_id, properties from users_equipment where iid=? and equipment_typeid=?",
        iid, eqtypeid)
    return ok, res
end

function _M.getEquipmentByEquipmentId(iid, eqtypeid, eqid)
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "select properties from users_equipment where iid=? and equipment_typeid=? and equipment_id=?",
        iid, eqtypeid, eqid)
    if not ok or res == nil or #res == 0 then
        return ok, nil
    end
    return true, cjson.decode(res[1]["properties"])
end

function _M.delEquipment(iid, eqtypeid, eqid)
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "delete from users_equipment where iid=? and equipment_typeid=? and equipment_id=?",
        iid, eqtypeid, eqid)
    return ok
end

function _M.updateEquipmentProperties(iid, eqtypeid, eqid, eqprops)
    local ok, eq = _M.getEquipmentByEquipmentId(iid, eqtypeid, eqid)
    if not ok or eq == nil then
        zce.log(4, "|", "updateEquipmentPropertie", iid, eqtypeid, eqid, "not exists")
        return false
    end
    util.deepMerge(eq, eqprops)
    return _M.saveEquipment(iid, eqtypeid, eqid, eq)
end
