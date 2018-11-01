local zce = require "zce.core"
local cjson = require "cjson"
local lu = require('util.luaunit')

TestHttpClient = {}

function TestHttpClient:test_http_dnsresolve()
    for i = 1, 1 do
        for i = 1, 10 do
            local ok, ip = zce.dns_resolve("www.baidu.com")
            lu.assertEquals(true, ok)
        end
        zce.usleep(500)
    end
end

function TestHttpClient:test_http_request()

    -- local ok0, code0, param0, body0 = zce.http_request("GET", "https://api.weixin.qq.com/sns/jscode2session?appid=wxfbb7eac1a8aba846&secret=7ff7ac017e1c76cc5210271268156101&js_code=023Du4L51GJuSL1McbK51IrOK51Du4LL&grant_type=authorization_code", "")

    sendtable = { data = "hello, world"}

    local ok, code, param, body = zce.http_request("POST", "http://127.0.0.1:8080/pos", { ["Content-Type"] = "application/json" }, cjson.encode(sendtable))

    lu.assertEquals(true, ok)
    lu.assertEquals(code, 200)
    rettable = cjson.decode(body)
    lu.assertEquals(sendtable, rettable)
end

lu.run()
