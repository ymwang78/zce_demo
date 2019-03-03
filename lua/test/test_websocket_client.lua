local zce = require "zce.core"

call_count = 0
connection_count = 0

function on_websock_event(con, event, data)
    print(con.peerip, con.peerport, con.fd, event, data)
    -- zce.usleep(1000)
    ---[[
    if event == "CONN" then
        zce.tcp_send(con, "za:abce1234");
    elseif event == "READ" then
        zce.tcp_send(con, "ia:abce1234");
    elseif event == "DISC" then
        zce.tcp_send(con, "end\n", 6); -- 应该收不到
    end
    --]]
    print(con.fd, event, data)
    return true
end

con = {}

-- ok2 = zce.tcp_connect("wstext://127.0.0.1:1217/electrum/WS", con, on_websock_event)

-- ok2 = zce.tcp_connect("wsstext://www.piupiugame.com:5181/electrum/WS", con, on_websock_event)

function heartbeat(timerobj, now, tick, con)
    zce.tcp_send(con, "za:abce1234");
end

-- local ok, code, param,body = zce.http_request("GET", "http://pay.pengpeng98.com/Channel_btcpay/cb_sub?amount=220837&cbparam=btcpay_plws_201810021418410001&sign=8374fc8381f109aa9628e46328c44871&totalfee=100&transid=0163c420a4", "", "")
-- local ok, timerid = zce.timer_start(5000, true, heartbeat, con)
---[[
local ok2 = zce.tcp_connect({
        { proto = "tcp", host = "127.0.0.1",  port = 1080},
        { proto = "socks", host = "echo.websocket.org",  port = 443},
        { proto = "ssl"},
        { proto = "websocket", host = "echo.websocket.org", path = "/" , binary = false},
    },
    con, on_websock_event)
--]]
--[[
local ok2 = zce.tcp_connect("wsstext://echo.websocket.org/",
    con, on_websock_event)
--]]