local c = require "zce.core"

function on_http_event(con, event, data)
    if event == "CONN" then
    elseif event == "READ" then
		c.log(1, "\t", data.method, data.uri, data.body)
        c.http_response(con, 200, { ["Content-Type"] =  "Application/Json"}, data.body)
        c.tcp_close(con);
    elseif event == "DISC" then
    end
end

local ok2 = c.tcp_listen("http", "0.0.0.0", 8080, on_http_event)

