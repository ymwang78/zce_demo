local zce = require "zce.core"
local lu = require('hawk.util.luaunit')

function on_http_event(con, event, data)
    if event == "CONN" then
    elseif event == "READ" then
        zce.log(1, "\t", data.method, data.uri, data.body)
        zce.http_response(con, 200, { ["Content-Type"] =  "Application/Json;charset=UTF-8"}, data.body)
        zce.tcp_close(con);
    elseif event == "DISC" then
    end
end

-- local ok, listenobj = zce.tcp_listen("http://0.0.0.0:8080", on_http_event)
local ok, listenobj = zce.tcp_listen({
        { proto = "tcp", host = "0.0.0.0",  port = 8080},
        { proto = "http"}, -- zhttp is zua http processor
    }, on_http_event)

lu.assertEquals(ok, true)

zce.usleep(5000)

-- local ok = zce.tcp_close(listenobj)
-- lu.assertEquals(ok, true)
