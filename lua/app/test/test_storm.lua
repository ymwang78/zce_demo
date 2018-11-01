local zce = require "zce.core"
local lu = require('util.luaunit')

TestStorm = {}

local ok, serveobj = zce.storm_serve(1000, "0.0.0.0", 3500) --reactorobj, 
lu.assertEquals( ok, true )
c.usleep(200)

local function on_storm_data(oid, topic, from, data, ctx)
    zce.log(1, "\t", oid, topic, from, data, ctx)
    ctx.counter = ctx.counter + 1
end

function TestStorm:test_storm()

    ctx = {}
    ctx.counter = 0
    
    local ok, clientobj1 = zce.storm_connect(1001, "127.0.0.1", 3500, on_storm_data, ctx)
    lu.assertEquals( ok, true )

    local ok, clientobj2 = zce.storm_connect(1002, "127.0.0.1", 3500, on_storm_data, ctx)
    lu.assertEquals( ok, true )

    zce.usleep(200)
    
    local test_topic = 12345

    local ok = zce.storm_subscribe(clientobj1, test_topic)
    lu.assertEquals( ok, true )

    local ok = zce.storm_subscribe(clientobj2, test_topic)
    lu.assertEquals( ok, true )

    zce.usleep(200)

    local ok = zce.storm_publish(clientobj1, test_topic, "hello, storm")
    lu.assertEquals( ok, true )

    zce.usleep(200)

    lu.assertEquals( 2, ctx.counter )

    local ok = zce.storm_publish(clientobj1, test_topic, "hello, storm")
    lu.assertEquals( ok, true )

    zce.usleep(200)

    lu.assertEquals( 4, ctx.counter )

    local ok = zce.storm_unsubscribe(clientobj1, test_topic)
    lu.assertEquals( ok, true )

    local ok = zce.storm_publish(clientobj1, test_topic, "hello, storm")
    lu.assertEquals( ok, true )

    zce.usleep(200)

    lu.assertEquals( 5, ctx.counter )

    zce.storm_close(clientobj1)
    zce.storm_close(clientobj2)
    zce.storm_close(serveobj)
end

lu.run()
