local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require("zce.core")
local util = require("util.util")
local lu = require('util.luaunit')

local function initConfig()
    local ok, hk_cache = zce.cache_init("local", "lib.hawk")
    lu.ensureEquals(ok, true)
    local ok, cfg = zce.cache_get(hk_cache, "config")
    if not ok or cfg == nil then
        return
    end
    -- zce.log(1, "|", zce.tojson(cfg, true))
    util.shallowMerge(_M, cfg)
end

function _M.setConfig(cfg)
    local ok, hawkcfg = zce.cache_init("local", "lib.hawk")
    lu.ensureEquals(ok, true, hawkcfg)

    if cfg.threadpool ~= nil then
        local ok, tpool = zce.new_threadpool(cfg.threadpool.num)
        lu.ensureEquals(ok, true)
        cfg.threadpool.tpoolobj = tpool
    end

    if cfg.mempool ~= nil then
        for i, item in ipairs(cfg.mempool) do
            local ok = zce.new_mempool(item[1], item[2])
            lu.ensureEquals(ok, true, item[1])
        end
    end

    if cfg.coinrpc ~= nil then
        local ok, coinrpcid = zce.rpc_ident("rpc", cfg.coinrpc.host .. ":" .. cfg.coinrpc.port, cfg.coinrpc.svrn)
        lu.ensureEquals(ok, true, coinrpcid)
        cfg.coinrpc.coinrpcid = coinrpcid
    end

    if cfg.pgsqldb ~= nil then
        local connstr = cfg.pgsqldb.user .. ":" .. cfg.pgsqldb.pass .. 
            "@" .. cfg.pgsqldb.host .. ":" .. cfg.pgsqldb.port .. "/" .. cfg.pgsqldb.name
        local tpoolobj = nil
        if cfg.pgsqldb.tpool then
            tpoolobj = cfg.threadpool.tpoolobj
        end
        local ok, pgdb = zce.rdb_conn("pgsql", connstr, tpoolobj)
        lu.ensureEquals(ok, true)
        cfg.pgsqldb.dbobj = pgdb
    end

    if cfg.mysqldb ~= nil then
        local connstr = cfg.mysqldb.user .. ":" .. cfg.mysqldb.pass .. 
            "@" .. cfg.mysqldb.host .. ":" .. cfg.mysqldb.port .. "/" .. cfg.mysqldb.name
        local tpoolobj = nil
        if cfg.mysqldb.tpool then
            tpoolobj = cfg.threadpool.tpoolobj
        end
        local ok, mydb = zce.rdb_conn("mysql", connstr, tpoolobj)
        lu.ensureEquals(ok, true)
        cfg.mysqldb.dbobj = mydb
    end

    if cfg.redisdb ~= nil then
        local ok, redisip = zce.dns_resolve(cfg.redisdb.host)
        lu.ensureEquals(ok, true)
        local ok, redisobj = zce.cache_init("redis",  redisip, cfg.redisdb.port, cfg.redisdb.pass)
        lu.ensureEquals(ok, true)
        cfg.redisdb.dbobj = redisobj
    end

    if cfg.package ~= nil then
        if cfg.package.cache == "redis" then
            cfg.package.cacheobj = cfg.redisdb.dbobj
        elseif cfg.package.cache == "local" then
            cfg.package.cacheobj = hawkcfg
        else
            cfg.package.cacheobj = nil
        end
    end

    zce.cache_set(hawkcfg, 0, "config", cfg)

    initConfig()
end

initConfig()
