--[[

lpc����������ͨ��LUA����������Ĳ���ǰ�����ǹ̶��ģ���������RPC����
-- sid  ���������RPC���õ�SESSION ID����ͨ�����sidͨ��rpc_response�������ؽ���������ߣ�ֻ����һ�Σ������ĵ��ûᱻ����
-- from ���������õ���Դ����������new_serviceע��ķ����������ļ����Ĭ��Ϊ"main"��

rpc_response ֱ�ӷ��ؽ������һ�������̶���SID, �����Ƿ��ز���
-- sid ��ͬ��

rpc_suspend Ϊ�˷�ֹRPC�������ǵ���rpc_response������rpc_call�����Ƶȴ���
�ص�����rpc_suspend,����RPC�����������������ؽ����SID��ס����һ���ٷ��أ�������������������
�����LPC��������Ȳ�����rpc_response��Ҳ������rpc_suspend�������߽�ֱ���յ�һ������Ϊ�յĽ��
������һ��Ϊsid, �ڶ����ǳ�ʱʱ�䣬������˳�ʱʱ�䣬RPC�����߻��յ�һ���յĽ���������ٵ���rpc_response��������

--]]

local c = require "zce.core"

local ok, rpcid = c.rpc_ident("lpc", "test_lpcsvr")

function say_hello(sid, from, v0, v1)
    print ("============say_hello", sid, from, v0, v1)
    c.usleep(2000);
    c.rpc_suspend(sid, 5000) -- ����RPC�������5000���뷵�ؽ��
    local ok, usleepack = c.rpc_call(rpcid, "usleep", 2000) -- �����ٴ����Լ�����һ��RPC����
    print ("------------", sleepack)
    c.rpc_response(sid, "hi", "response", 56789) --���ؽ��
end

function usleep(sid, from, v0, v1)
    print ("============usleep", sid, from, v0)
    c.usleep(v0)
    c.rpc_response(sid, "usleep ack")
    print ("============usleepend\n", sid)
end

function test_locallpc()
    print ("============test_locallpc")
    local ok, localack = c.rpc_call(rpcid, "usleep", 2000, "abcd") -- �����ٴ����Լ�����һ��RPC����
    print ("------------return", ok, localack)
end

-- co = coroutine.create(test_locallpc)
-- coroutine.resume(co)

test_locallpc()
