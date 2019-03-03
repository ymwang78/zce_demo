local zce = require "zce.core"
local lu = require('util.luaunit')

local ok, reactorobj = zce.reactor_start()

function on_rawsock_tcpecho(con, event, data)
    if event == "CONN" then
        con.call_count = 1
    elseif event == "READ" then
        con.call_count = con.call_count + 1
        zce.tcp_send(con, data);
        zce.tcp_close(con)
    elseif event == "DISC" then
        zce.tcp_close(con)
    end
end

local ok1, obj1 = zce.tcp_listen(reactorobj, "raw", "0.0.0.0", 1215, on_rawsock_tcpecho)
lu.assertEquals(ok, true)

function on_rawsock_udp(con, event, data)
    -- print(con.peerip, con.peerport, con.fd, event, data, connection_count)

    if event == "READ" then
        zce.udp_send(con, data);
    elseif event == "DISC" then
        zce.tcp_close(con)
    end

end

local ok2, obj2 = zce.udp_listen(reactorobj, "raw", "0.0.0.0", 1215, on_rawsock_udp)

c.usleep(10000)

-- zce.tcp_close(obj1)
-- zce.udp_close(obj2)
