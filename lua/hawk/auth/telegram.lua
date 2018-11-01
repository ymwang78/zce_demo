local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require("zce.core")
local lu = require("util.luaunit")
local cjson = require("cjson")
local util = require("util.util")
local cfg = require("hawk.config")
local user = require("hawk.user")
local session = require("hawk.auth.session")

local _OPENID_IID = {}

-- 从OPENID查找IID，如果没有，创建一个

function _M.getIidFromOpenID(openid, nick)
    zce.log(1, "|", "telegram.getIidFromOpenID", openid, nick)
    local cacheuser = _OPENID_IID[openid] 

    if cacheuser ~= nil then
        if (nick ~= nil and cacheuser.nick ~= nick) then
            local ok = zce.rdb_query(cfg.pgsqldb.dbobj, 
                "update users set nick = ? where iid = ? and nick <> ?",
                nick,
                cacheuser.iid,
                nick)
            cacheuser.nick = nick
            lu.ensureEquals(ok, true)
        end
        return true, cacheuser.iid
    end

    local ok, resiid = zce.rdb_query(cfg.pgsqldb.dbobj, "select * from users_oauth2 where openid = ?", openid)
    if not ok then
        return ok, nil
    end
    if (#resiid == 1) then
        cacheuser = { iid = resiid[1].iid , nick = nick }
        _OPENID_IID[openid] = cacheuser
        zce.rdb_query(cfg.pgsqldb.dbobj, 
            "update users set nick = ? where iid = ? and nick <> ?",
            nick, 
            cacheuser.iid, 
            nick)
        return  ok, cacheuser.iid
    end

    local ok, resiid = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "insert into users(passwd, nick) values (?, ?) returning iid", 
        "", 
        nick)
    lu.ensureEquals(ok, true)
    zce.log(1, "|", "auth:", zce.tojson(resiid[1], true))
    
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "insert into users_oauth2(openid, iid) values (?, ?)",
        openid,
        resiid[1].iid)
    lu.assertEquals(ok, true)

    _OPENID_IID[openid] = { iid = resiid[1].iid , nick = nick }

    return  ok, resiid[1].iid
end
