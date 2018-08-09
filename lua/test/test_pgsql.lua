--[[ 关系数据库操作API
rdb_initpool: 初始化连接池线程数量

rdb_conn：返回是否成功和连接句柄（如果成功）
--rdb类型，目前只支持"pgsql"
--第二个参数是连接字符串


rdb_query: 返回是否成功和关系表（如果成功），关系表第一行是字段名，后续是行数据
--连接句柄
--可选，返回数组还是TABLE，默认（或者不填）TABLE
--sql
--sql参数
--]]

local c = require "zce.core"
local lu = require('luaunit')

c.rdb_initpool(16)

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

end

lu.run()
