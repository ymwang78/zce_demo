--[[
本模块测试pack和unpack函数
pack:   ok, str = v.pack(v0, v1...)  把多个变量序列化为一个字节流, ok表示是否成功，目前不支持含有userdata的table，userdata会被忽略
unpack: v0, v1... = v.unpack(str)    把字节流反序列化为多个变量
--]]

local zce = require "zce.core"
local cjson = require "cjson"
local lu = require('util.luaunit')
local util = require('util.util')

TestListCompare = {}

function TestListCompare:test_cjson()
    zce.http_request("GET", "https://api.urlshare.cn/v3/user/send_gamebar_msg?appid=1106986880&content=%E5%A5%BD%E5%8F%8Bno.4%E9%80%81%E7%BB%99%E4%BD%A0%E4%B8%80%E4%B8%AA%E9%9D%A2%E5%8C%85&format=json&frd=C8219ADE0B832B1D5C56DE4EBEED93A2&msgtype=3&openid=56254737C68FE077E04D07880E4063C7&openkey=0738F1BC9D845EDE45D97066220C8386&pf=wanba_ts.9&qua=IPH&sig=N7IZl7Nx0FQ5SYeIpNNXKBZVp98%3D&userip=124.160.61.162")

local test_json = [[{
      "x0": 1539309621
}]]
    local obj = cjson.decode(test_json)
    lu.assertEquals(1539309621, obj.x0)
end

function TestListCompare:test_pack()
    t1 = {
        "111", "222", "333", "444",
         abc = "abc", def = "def", 
         "555", "666"
    }

    t2 = {
        "111", "222", "333", "444",
         abc = "abc", def = "def", 
         "555"
    }

    lu.assertNotEquals( t1, t2 )

    ok, v = zce.pack(t1)
    zce.dump_stack(ok, v)
    lu.assertEquals(true, ok)

    t3 = zce.unpack(v)
    zce.dump_stack(t3)
    lu.assertEquals( t1, t3 )

    ok, v = zce.pack(nil, true, "hello", -123, 123, -12345, 12345, t1, 1234567890123, -1234567890123, "")
    v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10 = zce.unpack(v)
    lu.assertEquals( v0, nil )
    lu.assertEquals( v1, true )
    lu.assertEquals( v2, "hello" )
    lu.assertEquals( v3, -123 )
    lu.assertEquals( v4, 123 )
    lu.assertEquals( v5, -12345 )
    lu.assertEquals( v6, 12345 )
    lu.assertEquals( v7, t1 )
    lu.assertEquals( v8, 1234567890123 )
    lu.assertEquals( v9, -1234567890123 )
    lu.assertEquals( v10, "" )
end

function TestListCompare:test_md5()
    v0 = zce.encode_md5("TestListCompare:test_md5") -- default lower case
    v1 = zce.encode_md5("TestListCompare:test_md5", false) -- output lower case
    v2 = zce.encode_md5("TestListCompare:test_md5", true) -- output upper case
    lu.assertEquals( v0, "0630ed1d356c66c6c9ebd19d7f182fc3")
    lu.assertEquals( v1, "0630ed1d356c66c6c9ebd19d7f182fc3")
    lu.assertEquals( v2, "0630ED1D356C66C6C9EBD19D7F182FC3")
end

function TestListCompare:test_sha1()
    v0 = zce.encode_hex(zce.encode_sha1("Hello world!"))
    lu.assertEquals( v0, "d3486ae9136e7856bc42212385ea797094475802")
    v0 = zce.encode_hex(zce.encode_hmacsha1("Hello world!", "Key"))
    lu.assertEquals( v0, "d5787006ac28f8239c3e6c51a1bd7f962db10669")
    v0 = zce.encode_hex(zce.encode_hmacsha1("Hello world!", "e320b58613155232aee46640d2afd24e320b58613155232aee46640d2afd240145fcd7bc46a506c3ab403f9ea50a2830145fcd7bc46a506c3ab403f9ea50a283e320b58613155232aee46640d2afd240145fcd7bc46a506c3ab403f9ea50a283"))
    lu.assertEquals( v0, "c0056494ec033454f532e262d44b1b7939408574")
end

function TestListCompare:test_sha256()
    v0 = zce.encode_hex(zce.encode_sha256("Hello world!"))
    lu.assertEquals( v0, "c0535e4be2b79ffd93291305436bf889314e4a3faec05ecffcbb7df31ad9e51a")
    v0 = zce.encode_hex(zce.encode_hmacsha256("Hello world!", "Key"))
    lu.assertEquals( v0, "e320b58613155232aee46640d2afd240145fcd7bc46a506c3ab403f9ea50a283")
    v0 = zce.encode_hex(zce.encode_hmacsha256("Hello world!", "e320b58613155232aee46640d2afd24e320b58613155232aee46640d2afd240145fcd7bc46a506c3ab403f9ea50a2830145fcd7bc46a506c3ab403f9ea50a283e320b58613155232aee46640d2afd240145fcd7bc46a506c3ab403f9ea50a283"))
    lu.assertEquals( v0, "f38f797340028dde9e880f2bce32b976c256642d89bf4891a75d282d0a19d404")
end

function TestListCompare:test_base64()
    v = "TestListCompare:test_base64"
    v0 = zce.encode_base64(v)
    v1 = zce.decode_base64(v0)
    lu.assertEquals( v, v1 )
    zce.dump_stack(v0, v1, v2)
end

function TestListCompare:test_httpurl()
    v = "TestListCompare:test_httpurl +=&dfd"
    v0 = zce.encode_httpurl(v)
    v1 = zce.decode_httpurl(v0)
    lu.assertEquals( v, v1 )
    zce.dump_stack(v0, v1, v2)
end

function TestListCompare:test_tojson()
    local t1 = {
        "111", 22, 1.234, "444",
         abc = "abc", def = "def", 
         "555", "666",
         {
            sub = "122", "level2",
            {
                "level3", sub = "a122"
            }
         }
    }
    v = zce.tojson(t1, true)
    zce.dump_stack(v)
end

function TestListCompare:test_split()
    v0 = zce.split("Anna, Bob, Charlie, Dolores", ", ") -- default lower case

    -- 第一个参数LOGLEVEL
    -- 第二个参数打印参数间分隔符
    zce.log(1, "\n", v0, zce.tojson(v0))
end

function TestListCompare:test_time()
    now = zce.time_now()
    today = zce.time_today()
    tomorrow = zce.time_tomorrow();
    
    zce.log(1, "\t", now, today, tomorrow)

    str0 = zce.time_strftime() -- default is now
    str1 = zce.time_strftime(0) -- 0 is now
    str2 = zce.time_strftime(tomorrow) -- that time
    str3 = zce.time_strftime(tomorrow, "%Y/%m/%d %H:%M:%S") -- other fmt - read http://www.cplusplus.com/reference/ctime/strftime/ 
    str4 = zce.time_strftime(now, "%Y/%m/%d %H:%M:%S") 
    zce.log(1, "\t", str0, str1, str2, str3, str4)

    t2 = zce.time_strptime(str2)
    t3 = zce.time_strptime(str3, "%Y/%m/%d %H:%M:%S")
    t4 = zce.time_strptime(str4, "%Y/%m/%d %H:%M:%S")
    lu.assertEquals( tomorrow, t2 )
    lu.assertEquals( tomorrow, t3 )
    lu.assertEquals( now, t4 )

    daystart = zce.time_daystart(now)
    lu.assertEquals( daystart, today)

    local test_time = 1540451255
    local weekbegin = zce.time_weekstart(test_time)
    local weekstr = zce.time_strftime(weekbegin, "%Y-%m-%d %H:%M:%S")
    lu.assertEquals(weekstr, '2018-10-22 00:00:00')

end


function TestListCompare:test_timeid()
    local test_time = 1540451255
    lu.assertEquals(util.getTimeId(1, test_time), 'day.20181025')
    lu.assertEquals(util.getTimeId(2, test_time), 'week.20181022')
    lu.assertEquals(util.getTimeId(3, test_time), 'month.201810')
    lu.assertEquals(util.getTimeId(4, test_time), 'year.2018')
end

 lu.run()