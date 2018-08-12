--[[
目前支持redis, local两种cache
--]]
local c = require "zce.core"
local lu = require('luaunit')

TestCache = {}

local ok, reactorobj = c.reactor_start()

lu.assertEquals( ok, true )

--------------------------- test redis cache ---------------------------

function do_test(localdb0)

	local testval_str = "string value"
	local testval_bool = true
	local testval_int = 1234
	local testval_double = 1.2345
	local testval_table = { s = "ass", b = true, i = 12345678, d = 2.3333, {s = "ass", b = true, i = 12345678, d = 2.3333} }
	 
	-- 10 expire 10秒, 默认一个星期
	local ok, err = c.cache_set(localdb0, 2, "test:v0", testval_str, testval_bool, testval_int, testval_double, testval_table)
	lu.assertEquals( ok, true )

	local ok, err = c.cache_set(localdb0, "test:v1", testval_str, testval_bool, testval_int, testval_double, testval_table)
	lu.assertEquals( ok, true )

	local ok, s, b, i, d, t = c.cache_get(localdb0, "test:v0")
	lu.assertEquals( ok, true )
	lu.assertEquals( s, testval_str )
	lu.assertEquals( b, testval_bool )
	lu.assertEquals( i, testval_int )
	lu.assertEquals( d, testval_double )
	lu.assertEquals( t, testval_table )

	local ok, s, b, i, d, t = c.cache_get(localdb0, "test:v1")
	lu.assertEquals( ok, true )
	lu.assertEquals( s, testval_str )
	lu.assertEquals( b, testval_bool )
	lu.assertEquals( i, testval_int )
	lu.assertEquals( d, testval_double )
	lu.assertEquals( t, testval_table )

	-- c.log(1, "\t", "wait 6 sec to make key expire")
	c.usleep(10000)
	-- c.log(1, "\t", "wait end")

	local ok, s, b, i, d, t = c.cache_get(localdb0, "test:v0")
	lu.assertEquals( ok, false )

	local ok, s, b, i, d, t = c.cache_get(localdb0, "test:v1")
	lu.assertEquals( ok, true )
	lu.assertEquals( s, testval_str )
	lu.assertEquals( b, testval_bool )
	lu.assertEquals( i, testval_int )
	lu.assertEquals( d, testval_double )
	lu.assertEquals( t, testval_table )
end

function TestCache:test_redis()
	local ok, redisip = c.dns_resolve("redis.svr")
	lu.assertEquals( ok, true )

	-- 参数1: cache类型
	-- 后续初始化参数，注意好像底层API不支持域名，要用IP
	-- 返回是否成功和句柄
	local ok, cachedb0 = c.cache_init("redis",  redisip, 6379, "f7743905699f4320:PwdZhiduR0") --
	lu.assertEquals( ok, true )

	do_test(cachedb0)
end

--------------------------- test local cache ---------------------------

function TestCache:test_local_withreactorandschedule()

	-- get scheduleobj created from main service
	local ok, configdb = c.cache_init("local", "config")
	lu.assertEquals( ok, true )

	local ok, scheduleobj = c.cache_get(configdb, "mypool")
	lu.assertEquals( ok, true )

	local ok, localdb0 = c.cache_init("local", reactorobj, scheduleobj, "sharedata1")
	lu.assertEquals( ok, true )

	do_test(localdb0)
end


function TestCache:test_local_withreactor()
	local ok, localdb0 = c.cache_init("local", reactorobj, "sharedata2")
	lu.assertEquals( ok, true )

	do_test(localdb0)
end

-- local cache 
function TestCache:test_local_withooutreactor()

	local ok, localdb0 = c.cache_init("local", "sharedata3")
	lu.assertEquals( ok, true )

	do_test(localdb0)
end


lu.run()



