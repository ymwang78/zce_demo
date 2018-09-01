local c = require "zce.core"
local lu = require('luaunit')

TestRawSocket = {}

local ok, reactorobj = c.reactor_start()

function do_stat_send(con, ok, bytes)
	if (ok) then
		con.globstat.send_bytes = con.globstat.send_bytes + bytes
		con.connstat.send_bytes = con.connstat.send_bytes + bytes
	else
		con.globalstat.send_failed = con.globalstat.send_failed + 1
		con.connstat.send_failed = con.connstat.send_failed + 1
	end
end

function on_rawsock_client(con, event, data)
    if event == "CONN" then

		con.globstat.conn_count = con.globstat.conn_count + 1
        local ok, bytes = c.tcp_send(con, "world\n", 0, 5);
		lu.assertEquals(ok, true)

		do_stat_send(con, ok, bytes)

    elseif event == "READ" then

	    con.globstat.recv_bytes = con.globstat.recv_bytes + string.len(data)
	    con.connstat.recvcall_count = con.connstat.recvcall_count + 1

        local ok, bytes = c.tcp_send(con, data);
		lu.assertEquals(ok, true)

		do_stat_send(con, ok, bytes)

		if con.connstat.recvcall_count >= 20 then
			--c.tcp_close(con)
		end

    elseif event == "DISC" then
		con.globstat.close_count = con.globstat.close_count + 1
		c.tcp_close(con)
    end
    return true
end

function TestRawSocket:test_tcp()
    local globalstat = {}
	globalstat.conn_req = 0
	globalstat.conn_failed = 0
	globalstat.conn_count = 0
	globalstat.close_count = 0
	globalstat.send_bytes = 0
	globalstat.recv_bytes = 0
	globalstat.send_failed = 0

    for i = 1, 10 do
        for i = 1, 10 do
			local curstat = {}
			curstat.sendcall_count = 0
			curstat.recvcall_count = 0
			curstat.send_bytes = 0;
			curstat.recv_bytes = 0;
			curstat.send_failed = 0;

            local con = { peerip = "127.0.0.1", peerport = 1215, globstat = globalstat, connstat = curstat }
            local ok = c.tcp_connect(reactorobj, "raw", con, on_rawsock_client)
			lu.assertEquals(ok, true)

			if ok then
				globalstat.conn_req = globalstat.conn_req + 1
			else
				globalstat.conn_failed = globalstat.conn_failed + 1
			end
        end
        c.usleep(200)
    end
	c.usleep(3 * 1000)
	lu.assertEquals( globalstat.conn_req, 100 )
	lu.assertEquals( globalstat.conn_count, 100 )
	lu.assertEquals( globalstat.conn_failed, 0 )
	lu.assertEquals( globalstat.send_bytes, 5 * 100 * 21 )
	lu.assertEquals( globalstat.recv_bytes, 5 * 100 * 20 )
end

-------------------------------------------------------------------------------------


function on_rawudp_client(con, event, data)
    c.log(1, "\t", con.peerip, con.peerport, con.fd, event, data, call_count)

    if event == "READ" then
		con.connstat.recv_bytes = con.connstat.recv_bytes + string.len(data)
		con.connstat.recvcall_count = con.connstat.recvcall_count + 1
        c.udp_send(con, "nome\tend\nnome", 4, 9);
		if con.connstat.recvcall_count >= 20 then
			c.udp_close(con)
		end
    elseif event == "DISC" then
		c.udp_close(con)
    end

end

function TestRawSocket:__test_udp()
	for i = 1, 1 do
		local con = {}
		constatus = { recvcall_count = 0, recv_bytes = 0}
		con.connstat = constatus

		local ok2, retcon = c.udp_listen("raw", "0.0.0.0", 0, on_rawudp_client, con)
		retcon.peerip = "127.0.0.1"
		retcon.peerport = 1215

		local ok = c.udp_send(retcon, "hello,world", 4, 9)
		c.usleep(1 * 1000)
		lu.assertEquals(ok, true)
		lu.assertEquals( constatus.recv_bytes, 5 * 20 )
		--c.usleep(5 * 1000)
		c.udp_close(retcon)
	end
end

lu.run()

