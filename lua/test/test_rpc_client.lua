--[[
Ϊ�˳���ھ��˻������ƣ�ÿ��new_service���û����һ��������LUA������������ļ����Ĭ��Ϊ"main"��
new_service(������, lua�ļ���)
lpc�����ʵ�ֿ����������

rpc_call : ����һ��Զ�̷���
-- ��һ������������RPC���ͣ�Ŀǰֻ֧��lpc
    --"lpc" : ��������һ���������������������ṩ�ĺ����������������OS�̣߳�
-- �ڶ����������������������new_service����ע���˷�����
-- ������������RPC������
-- ����������RPC�������ò���

--]]

local c = require "zce.core"

call_count = 0

ok, rpcid = c.rpc_ident("rpc", "127.0.0.1", 1218)

function test_rpc()
    for i = 1, 1 do
        ok, v0, v1, v2 = c.rpc_call(rpcid, "say_hello", "abcd", 12345) 
        print ("-----------return", ok, v0, v1, v2, "\n")
    end
end

test_rpc()
