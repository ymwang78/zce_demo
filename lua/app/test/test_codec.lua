
local zce = require "zce.core"
local lu = require('util.luaunit')

TestListCodec = {}

function TestListCodec:test_encode()

    local res = zce.encode_hex(zce.encode_sha1("1234567890"))
    lut.ensureEquals(res, "01b307acba4f54f55aafc33bb06bbbf6ca803e9a")
    zce.log(1, "|", res)
    
    local str = "https://www.freeformatter.com/hmac-generator.htmlhttps://www.freeformatter.com/hmac-generator.htmlhttps://www.freeformatter.com/hmac-generator.html"
    local res = zce.encode_hex(zce.encode_hmacsha1(str, "1234"))
    lut.ensureEquals(res, "f2e10c26248ff1071befd9748231708908a4f5c1")
    zce.log(1, "|", res)

    local res = zce.encode_hex(zce.encode_hmacsha1(str, str))
    lut.ensureEquals(res, "4cb083d2802d2c6f284f73f35d8ff053721c84ca")
    zce.log(1, "|", res)
end

 lu.run()