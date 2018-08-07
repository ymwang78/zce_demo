local c = require "zce.core"

local ok, reactorobj = c.reactor_start()
call_count = 0

function on_rawsock_client(con, event, data)
    call_count = call_count + 1
    c.log(1, "\t", con.peerip, con.peerport, con.fd, event, data, call_count)
    --c.usleep(1000)
    ---[[
    if event == "CONN" then
        c.tcp_send(con, "world\n", 6);
    elseif event == "READ" then
        c.tcp_send(con, "hello,world");
        c.tcp_send(con, "\tbegin", 0, 6);
        c.tcp_send(con, "nome\tend\nnome", 4, 9);
    elseif event == "DISC" then
        c.tcp_send(con, "end\n", 6); -- 应该收不到
    end
    --]]
    --print(con.fd, event, data)
    return true
end

function raw_tcpcli()
    for i = 1, 1 do
        for i = 1, 1 do
            con = { peerip = "127.0.0.1", peerport = 1215 }
            ok3 = c.tcp_connect(reactorobj, "raw", con, on_rawsock_client)
        end
        c.usleep(200)
    end
end

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
        c.udp_send(con, "end\n", 6); -- 应该收不到
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

-- raw_tcpcli()

raw_udpcli()
