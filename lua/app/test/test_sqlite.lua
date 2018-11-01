--[[ 关系数据库操作API https://github.com/ymwang78/zua/wiki/API-Reference
--]]

local zce = require "zce.core"
local lu = require('util.luaunit')

TestSqlite = {}

local test_create_sql = [[CREATE TABLE tbtest (
intv0 BIGINT,
intv1 INTEGER,
tstz timestamp with time zone,
strv0 TEXT
);]];


function TestSqlite:test_sqlite()

    local ok, sqlite = zce.rdb_conn("sqlite", "test_sqlite.db?dbkey=testpasswd;PRAGMA synchronous=NORMAL;PRAGMA journal_mode=WAL")
    lu.assertEquals( ok, true )

    local ok, res = zce.rdb_query(sqlite, "select count(*) from tbtest");
    if (ok == true) then
        ok, res = zce.rdb_query(sqlite, "drop table tbtest")
        lu.assertEquals( ok, true )
    end

    local ok, res = zce.rdb_query(sqlite, test_create_sql)
    lu.assertEquals( ok, true )

    for i = 1, 100 do
        local ok, res = zce.rdb_query(sqlite, "INSERT INTO tbtest(intv0,intv1,tstz,strv0) values(?,?,?,?)", i, 456, "2018-01-01 12:23:12", "hello")
        lu.assertEquals( ok, true )
    end

    local ok, res = zce.rdb_query(sqlite, "select * from tbtest");
    lu.assertEquals( ok, true )
    -- zce.log(1, "\t", zce.tojson(res[2]))
    lu.assertEquals( res[2].tstz, "2018-01-01 12:23:12" )
    lu.assertEquals( #res, 100 )

    zce.rdb_close(sqlite);
end


function TestSqlite:test_sqlite_mem()

    local ok, sqlite = zce.rdb_conn("sqlite", ":memory:")
    lu.assertEquals( ok, true )

    local ok, res = zce.rdb_query(sqlite, "select count(*) from tbtest");
    if (ok == true) then
        ok, res = zce.rdb_query(sqlite, "drop table tbtest")
        lu.assertEquals( ok, true )
    end

    local ok, res = zce.rdb_query(sqlite, test_create_sql)
    lu.assertEquals( ok, true )

    for i = 1, 100 do
        local ok, res = zce.rdb_query(sqlite, "INSERT INTO tbtest(intv0,intv1,tstz,strv0) values(?,?,?,?)", i, 456, "2018-01-01 12:23:12", "hello")
        lu.assertEquals( ok, true )
    end

    local ok, res = zce.rdb_query(sqlite, "select * from tbtest");
    lu.assertEquals( ok, true )
    -- zce.log(1, "\t", zce.tojson(res[2]))
    lu.assertEquals( res[2].tstz, "2018-01-01 12:23:12" )
    lu.assertEquals( #res, 100 )

    local ok, res = zce.rdb_execute(sqlite, "select * from tbtest limit 1; select * from tbtest limit 100;");
    lu.assertEquals( ok, true )

    zce.rdb_close(sqlite);
end


lu.run()
