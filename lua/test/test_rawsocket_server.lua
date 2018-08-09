local c = require "zce.core"

local ok, reactorobj = c.reactor_start()

call_count = 0
connection_count = 0

function on_rawsock_event(con, event, data)
    call_count = call_count + 1
    -- c.usleep(1000)
    ---[[
    if event == "CONN" then
        c.tcp_send(con, "hello\n");
        connection_count = connection_count + 1
    elseif event == "READ" then
        c.tcp_send(con, "server\n");
        if call_count > 10 then
            c.tcp_close(con);
        end
    elseif event == "DISC" then
        -- c.tcp_send(con, "end\n"); -- 应该收不到
    end
    c.log(1, " ", con.peerip, con.peerport, con.fd, event, data, connection_count)
    --]]
    --print(con.fd, event, data)
    return true
end

local ok1 = c.tcp_listen(reactorobj, "raw", "0.0.0.0", 1215, on_rawsock_event)

-- local ok2 = c.tcp_listen("raw", "0.0.0.0", 1216, on_rawsock_event)

function on_rawsock_udp(con, event, data)
    call_count = call_count + 1
    -- c.usleep(1000)
    ---[[
    if event == "READ" then
        c.udp_send(con, "server\n");
        if call_count > 10 then
            c.udp_close(con);
        end
    elseif event == "DISC" then
        -- c.udp_send(con, "end\n"); -- 应该收不到
    end
    print(con.peerip, con.peerport, con.fd, event, data, connection_count)
    --]]
    --print(con.fd, event, data)
    return true
end
local ok2 = c.udp_listen(reactorobj, "raw", "0.0.0.0", 1215, on_rawsock_udp)

c.log(1, "\t", "start listen raw socket ", ok1, ok2);

