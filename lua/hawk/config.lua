local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local c = require("zce.core")
local lu = require('luaunit')

local _ITEMS = {
    {"coinrpc", "hawk.coin.rpcid"},
    {"pgsqldb", "hawk.db.pgsql"},
    {"redisdb", "hawk.db.redis"},
    {"vsmsurl", "hawk.vsms.url"},
}

local function initConfig()
    local ok, hk_cache = c.cache_init("local", "hawk.config")
    lu.ensureEquals(ok, true)
    for i, item in ipairs(_ITEMS) do
        local ok, itemval = c.cache_get(hk_cache, item[2])
        lu.ensureEquals(ok, true, itemval)
        -- c.log(1, "|", item[1], item[2], ok)
        _M[item[1]] = itemval
    end
end

function _M.setConfig(cfg)
    local ok, hawkcfg = c.cache_init("local", "hawk.config")
    lu.ensureEquals(ok, true, hawkcfg)

    local ok, tpool = c.new_threadpool(4)
    lu.ensureEquals(ok, true)

    for i, item in ipairs(cfg.mempool) do
        local ok = c.new_mempool(item[1], item[2])
        lu.ensureEquals(ok, true, item[1])
    end

    if cfg.vsmsurl ~= nil then
        c.cache_set(hawkcfg, 0, "hawk.vsms.url", cfg.vsmsurl)
    end

    local ok, coinrpcid = c.rpc_ident("rpc", cfg.coinrpc.host, cfg.coinrpc.port, cfg.coinrpc.svrname)
    lu.ensureEquals(ok, true, coinrpcid)
    c.cache_set(hawkcfg, 0, "hawk.coin.rpcid", coinrpcid)

    local connstr = cfg.pgsqldb.username .. ":" .. cfg.pgsqldb.password .. 
        "@" .. cfg.pgsqldb.host .. ":" .. cfg.pgsqldb.port .. "/" .. cfg.pgsqldb.database
    local ok, pgdb = c.rdb_conn("pgsql", connstr, tpool)
    lu.ensureEquals(ok, true)
    c.cache_set(hawkcfg, 0, "hawk.db.pgsql", pgdb)

    local ok, redisip = c.dns_resolve(cfg.redisdb.host)
    lu.ensureEquals(ok, true)
    local ok, redisobj = c.cache_init("redis",  redisip, cfg.redisdb.port, cfg.redisdb.password)
    lu.ensureEquals(ok, true)
    c.cache_set(hawkcfg, 0, "hawk.db.redis", redisobj)



    initConfig()
end

initConfig()
