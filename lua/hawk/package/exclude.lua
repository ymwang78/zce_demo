--[[
    本模块实现时段限制得资源使用统计，例如每周只能领一次的礼包
    itemid, 是资源的标识, 例如 libao.libaoid001
    timeid, 是时间的标识, 在util.getTimeId里提供了常见的几个timeid生成的方式
    userid, 是用户标识
]]

local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require("zce.core")
local lu = require("util.luaunit")
local cjson = require("cjson")
local util = require("util.util")
local cfg = require("hawk.config")

function _M.getExcludeCount(itemid, timeid, userid)
    local ok, cnt = zce.cache_get(cfg.redisdb.dbobj, cfg.siteid .. '.exclude.' .. itemid .. '.' .. timeid .. ':' .. userid)
    if ok and cnt ~= nil then
        return cnt
    end

    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        'select * from exclude where timeid = ? and iid = ? and itemid = ?',
        timeid, userid, itemid)
    if ok and #res > 0 then
        return res[1].count
    end
    return 0
end

function _M.incExcludeCount(itemid, timeid, userid)
    local cnt = _M.getExcludeCount(itemid, timeid, userid)
    local ok, res
    if cnt > 0 then
        ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
            'update exclude set count = count+1 where timeid = ? and iid = ? and itemid = ? returning count',
            timeid, userid, itemid)
    else
        ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
            'insert into exclude(timeid, iid, itemid, count) values(?, ?, ?, 1) returning count',
            timeid, userid, itemid)     
    end
    if ok and #res > 0 then
        local ok = zce.cache_set(cfg.redisdb.dbobj, 
            cfg.siteid .. '.exclude.' .. itemid .. '..' .. timeid .. ':' .. userid,
            res[1].count)

        return res[1].count
    end
    return 0
end

function _M.clearExcludeCount(itemid, timeid, userid)
    local ok, cnt = zce.cache_del(cfg.redisdb.dbobj, cfg.siteid .. '.exclude.' .. itemid .. '..' .. timeid .. ':' .. userid)
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
            'delete from exclude  where timeid = ? and iid = ? and itemid = ? returning count',
            timeid, userid, itemid)
end
