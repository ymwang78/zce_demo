--[[ 关系数据库操作API https://github.com/ymwang78/zdlua/wiki/API-Reference
--]]

local c = require "zce.core"
local lu = require('luaunit')

TestPgSql = {}

function TestPgSql:test_pgsql()

	local ok, pgdb = c.rdb_conn("pgsql", "hawk:zhiduhawk@pgsql.svr:3300/hawk")
	lu.assertEquals( ok, true )

	local ok, res = c.rdb_query(pgdb, "select * from users limit ?", 100)
	lu.assertEquals( ok, true )

	local ok, res = c.rdb_query(pgdb, "select * from users where iid = ?", 1)
	lu.assertEquals( ok, true )
	-- c.log(1, "\t", c.tojson(res))
	lu.assertEquals( res[1].pid, 10000000 )

	-- print ("pgsql", #res, c.tojson(res[0]), c.tojson(res[1]), c.tojson(res[2]))

	-- 第二个参数如果是true，结果以数组形式返回
	local ok, res = c.rdb_query(pgdb, true, "select * from users limit ?", 100)
	lu.assertEquals( ok, true )

	-- print ("pgsql", #res, c.tojson(res[0]), c.tojson(res[1]), c.tojson(res[2]))

	local ok, res = c.rdb_query(pgdb, "update users set nick = ? where iid = 10000000", "mynick")
	lu.assertEquals( ok, true )

	-- print ("pgsql", ok, res, #res,  c.tojson(res[0]), c.tojson(res[1]), c.tojson(res[2]))
	c.rdb_close(pgdb);
end

function TestPgSql:test_pgsql_withthreadpool()

    local ok, tpool = c.new_threadpool(8)
	lu.assertEquals( ok, true )

	local ok, pgdb = c.rdb_conn("pgsql", "hawk:zhiduhawk@pgsql.svr:3300/hawk", tpool)
	lu.assertEquals( ok, true )

	local ok, res = c.rdb_query(pgdb, "select * from users limit ?", 100)
	lu.assertEquals( ok, true )

	local ok, res = c.rdb_query(pgdb, "select * from users where iid = ?", 1)
	lu.assertEquals( ok, true )
	-- c.log(1, "\t", c.tojson(res))
	lu.assertEquals( res[1].pid, 10000000 )

	-- print ("pgsql", #res, c.tojson(res[0]), c.tojson(res[1]), c.tojson(res[2]))

	-- 第二个参数如果是true，结果以数组形式返回
	local ok, res = c.rdb_query(pgdb, true, "select * from users limit ?", 100)
	lu.assertEquals( ok, true )

	-- print ("pgsql", #res, c.tojson(res[0]), c.tojson(res[1]), c.tojson(res[2]))

	local ok, res = c.rdb_query(pgdb, "update users set nick = ? where iid = 10000000", "mynick")
	lu.assertEquals( ok, true )

	-- print ("pgsql", ok, res, #res,  c.tojson(res[0]), c.tojson(res[1]), c.tojson(res[2]))
	c.rdb_close(pgdb);
end

lu.run()
