local c = require "zce.core"

local ok, serveobj = c.storm_serve(1000, "0.0.0.0", 3500) --reactorobj, 

local function on_storm_data(oid, topic, from, data, ctx)
	c.log(1, "\t", oid, topic, from, data, ctx)
end

local ok, clientobj1 = c.storm_connect(1001, "127.0.0.1", 3500, on_storm_data, { ctx = "context"})

local ok, clientobj2 = c.storm_connect(1002, "127.0.0.1", 3500, on_storm_data, { ctx = "context"})

c.usleep(2000)

local test_topic = 12345

c.storm_subscribe(clientobj1, test_topic)
c.storm_subscribe(clientobj2, test_topic)

c.usleep(2000)


local counter = 0

function timer_publish(timerobj, now, tick, ctx)
	c.storm_publish(clientobj1, test_topic, "hello, storm")
	-- local ok, newt = c.timer_start(reatorobj, 100, false, timer_print_fast, { ctx = "tablectx" })
	counter = counter + 1
	if counter == 10 then
		c.storm_unsubscribe(clientobj1, test_topic)
	end
end

c.timer_start(1000, true, timer_publish, { ctx = "tablectx" })
