local zce = require "zce.core"

call_count = 0
connection_count = 0

function on_websock_event(con, event, data)
    zce.log(1, "|", "WebSocketServer", con.peerip, con.peerport, con.fd, event, data)
    -- zce.usleep(1000)
    ---[[
    if event == "CONN" then
        zce.tcp_send(con, "hello\n", 0);
    elseif event == "READ" then
        zce.tcp_send(con, "world\n", 0);
        if (data == "f") then
            zce.tcp_close(con);
        end
    elseif event == "DISC" then
        zce.tcp_send(con, "end\n", 6); -- 应该收不到
    end
    --]]
    print(con.fd, event, data)
    return true
end

ok2 = zce.tcp_listen("websocket", "0.0.0.0", 1217, on_websock_event)

