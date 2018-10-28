--[[
目前支持redis, local两种cache
--]]
local zce = require "zce.core"
local lu = require('util.luaunit')
local cfg = require('config')

TestCache = {}

local ok, reactorobj = zce.reactor_start()

lu.assertEquals( ok, true )

--------------------------- test redis cache ---------------------------
function do_redis_test_getset(dbobj)
    local testval_int = 1234
    local testval_str = "string value"

    local ok = zce.redis_set(dbobj, 100, "test:intv0", testval_int)
    local ok, val = zce.redis_get(dbobj, "test:intv0", 0)
    lu.assertEquals( val, testval_int)

    local ok = zce.redis_set(dbobj, 100, "test:strv0", testval_str)
    local ok, val = zce.redis_get(dbobj, "test:strv0", "")
    lu.assertEquals( val, testval_str)
    local ok, val = zce.redis_get(dbobj, "test:strv0")
    lu.assertEquals( val, testval_str)

    local ok, val = zce.redis_get(dbobj, "test:strnotexists", testval_str)
    lu.assertEquals( val, testval_str)
end

function do_redis_test_hgetset(dbobj)
    local testval_int = 1234
    local testval_str = "string value"
    local testval_str2 = "string value 2"

    local ok = zce.redis_hset(dbobj, 100, "test:hintv0", "obj001", testval_int)
    local ok, val = zce.redis_hget(dbobj, "test:hintv0", "obj001", 0)
    lu.assertEquals( val, testval_int)

    local ok, val = zce.redis_hinc(dbobj, 100, "test:hintv0", "obj001", testval_int)
    lu.assertEquals( val, testval_int + testval_int)

    local ok = zce.redis_hset(dbobj, 100, "test:hstrv0", "obj001", testval_str)
    local ok, val = zce.redis_hget(dbobj, "test:hstrv0", "obj001", "")
    lu.assertEquals( val, testval_str)
    local ok, val = zce.redis_hget(dbobj, "test:hstrv0", "obj001")
    lu.assertEquals( val, testval_str)

    local ok = zce.redis_hset(dbobj, 100, "test:hstrv0", "obj002", testval_str2)

    local ok, val = zce.redis_hget(dbobj, "test:hstrv0", "objnotexists",  testval_str)
    lu.assertEquals( val, testval_str)

    local ok, val = zce.redis_hget(dbobj, "test:strnotexists", "obj001",  testval_str)
    lu.assertEquals( val, testval_str)

    local ok, val = zce.redis_hgetall(dbobj, "test:hstrv0")
    zce.log(1, "|", zce.tojson(val, true))
end

function do_test(localdb0)

    local testval_str = "string value"
    local testval_bool = true
    local testval_int = 1234
    local testval_double = 1.2345
    local testval_table = { s = "ass", b = true, i = 12345678, d = 2.3333, {s = "ass", b = true, i = 12345678, d = 2.3333} }
     
    -- 10 expire 10秒, 默认一个星期
    local ok, err = zce.cache_set(localdb0, 2, "test:v0", testval_str, testval_bool, testval_int, testval_double, testval_table)
    lu.assertEquals( ok, true )

    local ok, err = zce.cache_set(localdb0, "test:v1", testval_str, testval_bool, testval_int, testval_double, testval_table)
    lu.assertEquals( ok, true )

    local ok, s, b, i, d, t = zce.cache_get(localdb0, "test:v0")
    lu.assertEquals( ok, true )
    lu.assertEquals( s, testval_str )
    lu.assertEquals( b, testval_bool )
    lu.assertEquals( i, testval_int )
    lu.assertEquals( d, testval_double )
    lu.assertEquals( t, testval_table )

    local ok, s, b, i, d, t = zce.cache_get(localdb0, "test:v1")
    lu.assertEquals( ok, true )
    lu.assertEquals( s, testval_str )
    lu.assertEquals( b, testval_bool )
    lu.assertEquals( i, testval_int )
    lu.assertEquals( d, testval_double )
    lu.assertEquals( t, testval_table )

    -- zce.log(1, "\t", "wait 6 sec to make key expire")
    zce.usleep(10000)
    -- zce.log(1, "\t", "wait end")

    local ok, s, b, i, d, t = zce.cache_get(localdb0, "test:v0")
    lu.assertEquals( ok, false )

    local ok, s, b, i, d, t = zce.cache_get(localdb0, "test:v1")
    lu.assertEquals( ok, true )
    lu.assertEquals( s, testval_str )
    lu.assertEquals( b, testval_bool )
    lu.assertEquals( i, testval_int )
    lu.assertEquals( d, testval_double )
    lu.assertEquals( t, testval_table )
end

function TestCache:test_redis()
    local ok, redisip = zce.dns_resolve("redis.svr")
    lu.assertEquals( ok, true )

    do_redis_test_getset(cfg.redisdb.dbobj)

    do_redis_test_hgetset(cfg.redisdb.dbobj)

    do_test(cfg.redisdb.dbobj)
end

--------------------------- test local cache ---------------------------

function TestCache:_test_local_withreactorandschedule()

    -- get scheduleobj created from main service
    local ok, configdb = zce.cache_init("local", "sharedata0")
    lu.assertEquals( ok, true )

    local ok, localdb0 = zce.cache_init("local", reactorobj, cfg.threadpool.tpoolobj, "sharedata1")
    lu.assertEquals( ok, true )

    do_test(localdb0)
end

function TestCache:_test_local_withreactor()
    local ok, localdb0 = zce.cache_init("local", reactorobj, "sharedata2")
    lu.assertEquals( ok, true )

    do_test(localdb0)
end

-- local cache 
function TestCache:_test_local_withooutreactor()

    local ok, localdb0 = zce.cache_init("local", "sharedata3")
    lu.assertEquals( ok, true )

    do_test(localdb0)
end

lu.run()
