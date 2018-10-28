local c = require "zce.core"

call_count = 0
connection_count = 0

function on_websock_event(con, event, data)
    c.log(1, "|", "WebSocketServer", con.peerip, con.peerport, con.fd, event, data)
    -- c.usleep(1000)
    ---[[
    if event == "CONN" then
        c.tcp_send(con, "hello\n", 0);
    elseif event == "READ" then
        c.tcp_send(con, "world\n", 0);
        if (data == "f") then
            c.tcp_close(con);
        end
    elseif event == "DISC" then
        c.tcp_send(con, "end\n", 6); -- 应该收不到
    end
    --]]
    print(con.fd, event, data)
    return true
end

ok2 = c.tcp_listen("websocket", "0.0.0.0", 1217, on_websock_event)

