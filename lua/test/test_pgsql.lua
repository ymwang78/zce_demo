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

c.rdb_initpool(16)

ok, pgdb = c.rdb_conn("pgsql", "hawk:zhiduhawk@pgsql.svr:3300/hawk")
print ("pgsql", ok)

ok, res = c.rdb_query(pgdb, "select * from users limit ?", 100)

print ("pgsql", #res, c.tojson(res[0]), c.tojson(res[1]), c.tojson(res[2]))

-- �ڶ������������true�������������ʽ����
ok, res = c.rdb_query(pgdb, true, "select * from users limit ?", 100)

print ("pgsql", #res, c.tojson(res[0]), c.tojson(res[1]), c.tojson(res[2]))

ok, res = c.rdb_query(pgdb, "update users set nick = ? where iid = 10000000", "mynick")

print ("pgsql", ok, res, #res,  c.tojson(res[0]), c.tojson(res[1]), c.tojson(res[2]))
