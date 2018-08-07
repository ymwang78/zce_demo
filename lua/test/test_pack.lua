--[[
本模块测试pack和unpack函数
pack:   ok, str = v.pack(v0, v1...)  把多个变量序列化为一个字节流, ok表示是否成功，目前不支持含有userdata的table，userdata会被忽略
unpack: v0, v1... = v.unpack(str)    把字节流反序列化为多个变量
--]]

local c = require "zce.core"
local lu = require('luaunit')

TestListCompare = {}

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

    ok, v = c.pack(t1)
	c.dump_stack(ok, v)
    lu.assertEquals(true, ok)

    t3 = c.unpack(v)
	c.dump_stack(t3)
    lu.assertEquals( t1, t3 )

    ok, v = c.pack(nil, true, "hello", -123, 123, -12345, 12345, t1, 1234567890123, -1234567890123)
    v0, v1, v2, v3, v4, v5, v6, v7, v8, v9 = c.unpack(v)
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
end

function TestListCompare:test_md5()
	v0 = c.encode_md5("TestListCompare:test_md5") -- default lower case
	v1 = c.encode_md5("TestListCompare:test_md5", false) -- output lower case
	v2 = c.encode_md5("TestListCompare:test_md5", true) -- output upper case
	c.dump_stack(v0, v1, v2)
end

function TestListCompare:test_base64()
	v = "TestListCompare:test_base64"
	v0 = c.encode_base64(v)
	v1 = c.decode_base64(v0)
	lu.assertEquals( v, v1 )
	c.dump_stack(v0, v1, v2)
end

function TestListCompare:test_httpurl()
	v = "TestListCompare:test_httpurl +=&dfd"
	v0 = c.encode_httpurl(v)
	v1 = c.decode_httpurl(v0)
	lu.assertEquals( v, v1 )
	c.dump_stack(v0, v1, v2)
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
	v = c.tojson(t1, true)
	c.dump_stack(v)
end

function TestListCompare:test_split()
	v0 = c.split("Anna, Bob, Charlie, Dolores", ", ") -- default lower case

	-- 第一个参数LOGLEVEL
	-- 第二个参数打印参数间分隔符
	c.log(1, "\n", v0, c.tojson(v0))
end

function TestListCompare:test_time()
	now = c.time_now()
	today = c.time_today()
	tomorrow = c.time_tomorrow();
	
	c.log(1, "\t", now, today, tomorrow)

	str0 = c.time_strftime() -- default is now
	str1 = c.time_strftime(0) -- 0 is now
	str2 = c.time_strftime(tomorrow) -- that time
	str3 = c.time_strftime(tomorrow, "%Y/%m/%d %H:%M:%S") -- other fmt - read http://www.cplusplus.com/reference/ctime/strftime/ 
	str4 = c.time_strftime(now, "%Y/%m/%d %H:%M:%S") 
	c.log(1, "\t", str0, str1, str2, str3, str4)

	t2 = c.time_strptime(str2)
	t3 = c.time_strptime(str3, "%Y/%m/%d %H:%M:%S")
	t4 = c.time_strptime(str4, "%Y/%m/%d %H:%M:%S")
	lu.assertEquals( tomorrow, t2 )
	lu.assertEquals( tomorrow, t3 )
	lu.assertEquals( now, t4 )

	daystart = c.time_daystart(now)
	lu.assertEquals( daystart, today )
end

 lu.run()