local c = require "zce.core"

local ok, reactorobj = c.reactor_start()

function on_rawsock_tcpecho(con, event, data)
    if event == "CONN" then
		con.call_count = 1
    elseif event == "READ" then
		con.call_count = con.call_count + 1
        c.tcp_send(con, data);
    elseif event == "DISC" then
		c.tcp_close(con)
    end
end

local ok1 = c.tcp_listen(reactorobj, "raw", "0.0.0.0", 1215, on_rawsock_tcpecho)

function on_rawsock_udp(con, event, data)
    -- print(con.peerip, con.peerport, con.fd, event, data, connection_count)

    if event == "READ" then
        c.udp_send(con, data);
    elseif event == "DISC" then
		c.tcp_close(con)
    end

end

local ok2 = c.udp_listen(reactorobj, "raw", "0.0.0.0", 1215, on_rawsock_udp)


