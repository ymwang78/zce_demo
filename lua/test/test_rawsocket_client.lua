local c = require "zce.core"

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
    c.log(1, "\t", con.peerip, con.peerport, con.fd, event, data, call_count)
    if event == "CONN" then

		con.globstat.conn_count = con.globstat.conn_count + 1

        local ok, bytes = c.tcp_send(con, "world\n", 0);
		do_stat_send(con, ok, bytes)

    elseif event == "READ" then

	    con.globstat.recv_bytes = con.globstat.recv_bytes + string.len(data)
	    con.connstat.recvcall_count = con.connstat.recvcall_count + 1

        local ok, bytes = c.tcp_send(con, "hello,world");
		do_stat_send(con, ok, bytes)

        local ok, bytes = c.tcp_send(con, "\tbegin", 0, 6);
		do_stat_send(con, ok, bytes)

        local ok, bytes = c.tcp_send(con, "nome\tend\nnome", 4, 9);
		do_stat_send(con, ok, bytes)

		if con.connstat.recvcall_count > 20 then
			c.tcp_close(con)
		end

    elseif event == "DISC" then

		con.globstat.close_count = con.globstat.close_count + 1

    end
    return true
end

function raw_tcpcli()
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
            local ok3 = c.tcp_connect(reactorobj, "raw", con, on_rawsock_client)
			if ok3 then
				globalstat.conn_req = globalstat.conn_req + 1
			else
				globalstat.conn_failed = globalstat.conn_failed + 1
			end
        end
        c.usleep(200)
    end
	c.usleep(10 * 1000)
	c.log(1, " ", c.tojson(globalstat))
end

raw_tcpcli()

-------------------------------------------------------------------------------------


function on_rawudp_client(con, event, data)
    call_count = call_count + 1
    c.log(1, "\t", con.peerip, con.peerport, con.fd, event, data, call_count)
    --c.usleep(1000)
    ---[[
    if event == "READ" then
        c.udp_send(con, "hello,world");
        c.udp_send(con, "\tbegin", 0, 6);
        c.udp_send(con, "nome\tend\nnome", 4, 9);
    elseif event == "DISC" then
        -- c.udp_send(con, "end\n", 6); -- 应该收不到
    end
    --]]
    --print(con.fd, event, data)
    return true
end

function raw_udpcli()
	local ok2, con = c.udp_listen("raw", "0.0.0.0", 0, on_rawudp_client)
	c.log(1, "\t", ok2, con)
    for i = 1, 1 do
        for i = 1, 1 do
            -- con = { peerip = "127.0.0.1", peerport = 1215 }
			con.peerip = "127.0.0.1"
			con.peerport = 1215
            ok3 = c.udp_send(con, "hello,world")
        end
        c.usleep(200)
    end
end


-- raw_udpcli()
