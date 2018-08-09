local c = require "zce.core"
local lu = require('luaunit')

TestStorm = {}

local ok, serveobj = c.storm_serve(1000, "0.0.0.0", 3500) --reactorobj, 
lu.assertEquals( ok, true )


local function on_storm_data(oid, topic, from, data, ctx)
	c.log(1, "\t", oid, topic, from, data, ctx)
	ctx.counter = ctx.counter + 1
end

function TestStorm:test_storm()

    ctx = {}
	ctx.counter = 0
    
	local ok, clientobj1 = c.storm_connect(1001, "127.0.0.1", 3500, on_storm_data, ctx)
	lu.assertEquals( ok, true )

	local ok, clientobj2 = c.storm_connect(1002, "127.0.0.1", 3500, on_storm_data, ctx)
	lu.assertEquals( ok, true )

	c.usleep(200)
	
	local test_topic = 12345

	c.storm_subscribe(clientobj1, test_topic)
	c.storm_subscribe(clientobj2, test_topic)

	c.usleep(200)

	c.storm_publish(clientobj1, test_topic, "hello, storm")

	c.usleep(200)

	lu.assertEquals( 2, ctx.counter )

	c.storm_publish(clientobj1, test_topic, "hello, storm")

	c.usleep(200)

	lu.assertEquals( 4, ctx.counter )

	c.storm_unsubscribe(clientobj1, test_topic)

	c.storm_publish(clientobj1, test_topic, "hello, storm")

	c.usleep(200)

	lu.assertEquals( 5, ctx.counter )

end

lu.run()
