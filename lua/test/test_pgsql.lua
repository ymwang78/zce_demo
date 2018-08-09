--[[ ��ϵ���ݿ����API
rdb_initpool: ��ʼ�����ӳ��߳�����

rdb_conn�������Ƿ�ɹ������Ӿ��������ɹ���
--rdb���ͣ�Ŀǰֻ֧��"pgsql"
--�ڶ��������������ַ���


rdb_query: �����Ƿ�ɹ��͹�ϵ������ɹ�������ϵ���һ�����ֶ�����������������
--���Ӿ��
--��ѡ���������黹��TABLE��Ĭ�ϣ����߲��TABLE
--sql
--sql����
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

	-- �ڶ������������true�������������ʽ����
	local ok, res = c.rdb_query(pgdb, true, "select * from users limit ?", 100)
	lu.assertEquals( ok, true )

	-- print ("pgsql", #res, c.tojson(res[0]), c.tojson(res[1]), c.tojson(res[2]))

	local ok, res = c.rdb_query(pgdb, "update users set nick = ? where iid = 10000000", "mynick")
	lu.assertEquals( ok, true )

	-- print ("pgsql", ok, res, #res,  c.tojson(res[0]), c.tojson(res[1]), c.tojson(res[2]))

end

lu.run()
