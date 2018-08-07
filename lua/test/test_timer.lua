
local c = require "zce.core"

local ok, rpcid = c.rpc_ident("lpc", "test_lpcsvr")

local ok, reatorobj = c.reactor_start()

function timer_print_fast(timerobj, now, tick, ctx)
	c.log(1, "\t", timerobj, now, tick, ctx)
	c.timer_stop(timerobj)
	-- local ok, newt = c.timer_start(reatorobj, 100, false, timer_print_fast, { ctx = "tablectx" })
end

function timer_print(timerobj, now, tick, ctx)
	local ok, newt = c.timer_start(100, true, timer_print_fast, { ctx = "tablectx" })
	c.log(1, "\t", now, tick, ctx)
end

--上下文参数不加就是nil
local ok, timerid = c.timer_start(2000, true, timer_print)

c.usleep(20 * 1000)

c.timer_stop(timerid)
