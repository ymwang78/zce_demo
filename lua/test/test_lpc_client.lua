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

local call_count = 0

local ok, rpcid = c.rpc_ident("lpc", "test_lpcsvr")

function lpc_call()
    for i = 1, 1 do
        -- local ok, v0, v1, v2 = c.rpc_call(rpcid, "say_hello", "abcd", 12345) 
        -- print ("-----------return", ok, v0, v1, v2, "\n")
        local ok2, v20 = c.rpc_call(rpcid, "usleep", 2000, "abcd")
        print ("-----------return", ok2, v20)
    end
end

-- lpc_call()
