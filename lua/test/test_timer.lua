local c = require "zce.core"
local lu = require('luaunit')

TestTimer = {}

local ok, reatorobj = c.reactor_start()
lu.assertEquals( ok, true )

function timer_print(timerobj, now, tick, ctx)
	ctx.counter = ctx.counter + 1
end

function TestTimer:test_timer()
	--上下文参数不加就是nil
	ctx = {}
	ctx.counter = 0

	local ok, timerid = c.timer_start(500, true, timer_print, ctx)
	lu.assertEquals( ok, true )

	c.usleep(5 * 1000 + 100)
	
	lu.assertEquals( 10, ctx.counter )

	local ok = c.timer_stop(timerid)
	lu.assertEquals( ok, true )

	c.usleep(5 * 1000)

	lu.assertEquals( 10, ctx.counter )
end

lu.run()
