--[[ 关系数据库操作API https://github.com/ymwang78/zua/wiki/API-Reference
--]]

local zce = require "zce.core"
local lu = require('util.luaunit')

TestMySql = {}

function TestMySql:test_mysql()
    --user:passwd@host:port/dbname
    local ok, pgdb = zce.rdb_conn("mysql", "zhidu:9cjhd-6bncf@10.162.93.85:3306/piupiu")
    lu.assertEquals( ok, true )

    local ok, res = zce.rdb_query(pgdb, "select * from member limit ?", 100)
    lu.assertEquals( ok, true )
    zce.log(1, "\t", zce.tojson(res, true))

    local ok, res = zce.rdb_query(pgdb, "select * from member where idx = ?", 10000000)
    lu.assertEquals( ok, true )
    zce.log(1, "\t", zce.tojson(res, true))
    lu.assertEquals( res[1].pid, 10000000 )

    -- print ("pgsql", #res, zce.tojson(res[0]), zce.tojson(res[1]), zce.tojson(res[2]))

    -- 第二个参数如果是true，结果以数组形式返回
    local ok, res = zce.rdb_query(pgdb, true, "select * from member limit ?", 100)
    lu.assertEquals( ok, true )

    -- print ("pgsql", #res, zce.tojson(res[0]), zce.tojson(res[1]), zce.tojson(res[2]))

    local ok, res = zce.rdb_query(pgdb, "update member set myname = ? where iid = 10000000", "mynick")
    lu.assertEquals( ok, true )

    -- print ("pgsql", ok, res, #res,  zce.tojson(res[0]), zce.tojson(res[1]), zce.tojson(res[2]))
    zce.rdb_close(pgdb);
end

function TestMySql:test_mysql_withthreadpool()

    local ok, tpool = zce.new_threadpool(8)
    lu.assertEquals( ok, true )

    local ok, pgdb = zce.rdb_conn("mysql", "zhidu:9cjhd-6bncf@10.162.93.85:3306/piupiu", tpool)
    lu.assertEquals( ok, true )
    
    local ok, res = zce.rdb_query(pgdb, "select * from member limit ?", 100)
    lu.assertEquals( ok, true )
    zce.log(1, "\t", zce.tojson(res, true))

    local ok, res = zce.rdb_query(pgdb, "select * from member where idx = ?", 10000000)
    lu.assertEquals( ok, true )
    zce.log(1, "\t", zce.tojson(res, true))
    lu.assertEquals( res[1].pid, 10000000 )

    -- print ("pgsql", #res, zce.tojson(res[0]), zce.tojson(res[1]), zce.tojson(res[2]))

    -- 第二个参数如果是true，结果以数组形式返回
    local ok, res = zce.rdb_query(pgdb, true, "select * from member limit ?", 100)
    lu.assertEquals( ok, true )

    -- print ("pgsql", #res, zce.tojson(res[0]), zce.tojson(res[1]), zce.tojson(res[2]))

    local ok, res = zce.rdb_query(pgdb, "update member set myname = ? where iid = 10000000", "mynick")
    lu.assertEquals( ok, true )

    -- print ("pgsql", ok, res, #res,  zce.tojson(res[0]), zce.tojson(res[1]), zce.tojson(res[2]))
    zce.rdb_close(pgdb);
end

lu.run()
