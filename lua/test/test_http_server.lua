local c = require "zce.core"

local call_count = 0
local connection_count = 0

function on_http_event(con, event, data)
    print(con.peerip, con.peerport, con.fd, event, data)
    -- c.usleep(1000)
    ---[[
    if event == "CONN" then
        print "connected";
    elseif event == "READ" then
        print (data.uri, data.method)
        -- c.tcp_send(con, "world\n", 6);
        c.http_response(con, 200, { ["Content-Type"] =  "Application/Json"}, "{ \"data\" : \"hello, workd\"}")
        -- , 
        c.tcp_close(con);
    elseif event == "DISC" then
        c.tcp_send(con, "end\n", 6); -- 应该收不到
    end
    --]]
    print(con.fd, event, data)
    return true
end

local ok2 = c.tcp_listen("http", "0.0.0.0", 8080, on_http_event)

