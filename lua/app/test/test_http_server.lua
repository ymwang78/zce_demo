local c = require "zce.core"
local lu = require('luaunit')

function on_http_event(con, event, data)
    if event == "CONN" then
    elseif event == "READ" then
        c.log(1, "\t", data.method, data.uri, data.body)
        c.http_response(con, 200, { ["Content-Type"] =  "Application/Json;charset=UTF-8"}, data.body)
        c.tcp_close(con);
    elseif event == "DISC" then
    end
end

local ok, listenobj = c.tcp_listen("http", "0.0.0.0", 8080, on_http_event)
lu.assertEquals(ok, true)

c.usleep(5000)

local ok = c.tcp_close(listenobj)
lu.assertEquals(ok, true)
