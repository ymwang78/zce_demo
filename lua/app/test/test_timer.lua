local c = require "zce.core"
local lu = require('util.luaunit')

TestTimer = {}

-- local ok, reatorobj = c.reactor_start()
-- lu.assertEquals( ok, true )

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
    
    lu.assertEquals( ctx.counter, 10 )

    local ok = c.timer_stop(timerid)
    lu.assertEquals( ok, true )

    c.usleep(5 * 1000)

    lu.assertEquals( 10, ctx.counter )
end


--------------------------- test vmvar expire ---------------------------

function TestTimer:test_vmvar_expire()
    t = { "abcd", "1234", "7890", expire = "abcd", delay = "1234", expireclean = "7890"}
    
    local ok = c.vmvar_expire(t, 1, 2)
    lu.assertEquals( ok, true )
    local ok = c.vmvar_expire(t, "expire", 2)
    lu.assertEquals( ok, true )

    local ok = c.vmvar_expire(t, 2, 2)
    lu.assertEquals( ok, true )
    local ok = c.vmvar_expire(t, "delay", 2)
    lu.assertEquals( ok, true )

    local ok = c.vmvar_expire(t, 3, 2)
    lu.assertEquals( ok, true )
    local ok = c.vmvar_expire(t, "expireclean", 2)
    lu.assertEquals( ok, true )

    c.usleep(1000)

    local ok = c.vmvar_expire(t, 2, 5)
    lu.assertEquals( ok, true )
    local ok = c.vmvar_expire(t, "delay", 5)
    lu.assertEquals( ok, true )

    local ok = c.vmvar_expire(t, 3, 0)
    lu.assertEquals( ok, true )
    local ok = c.vmvar_expire(t, "expireclean", 0) -- set no expire
    lu.assertEquals( ok, true )

    c.usleep(3000)
    
    lu.assertEquals( t[1], nil )
    lu.assertEquals( t.expire, nil )
    lu.assertEquals( t[2], "1234" )
    lu.assertEquals( t.delay, "1234" )
    lu.assertEquals( t[3], "7890" )
    lu.assertEquals( t.expireclean, "7890" )

    c.usleep(5000)

    lu.assertEquals( t[1], nil )
    lu.assertEquals( t.expire, nil )
    lu.assertEquals( t[2], nil )
    lu.assertEquals( t.delay, nil )
    lu.assertEquals( t[3], "7890")
    lu.assertEquals( t.expireclean, "7890" )

end

lu.run()
