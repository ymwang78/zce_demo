local c = require "zce.core"

local ok0, code0, param0, body0 = c.http_request("GET", "http://www.baidu.com/", { ["Content-Type"] = "application/json"}, "")

print (ok0, code0, param0, body0)

-- local ok1, data1 = c.http_request("POST", "http://127.0.0.1:8080/pos", { "[Content-Type]" : "application/json"}, "")
