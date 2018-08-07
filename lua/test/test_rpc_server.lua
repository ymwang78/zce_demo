--[[

RPC����˵Ĵ����LPC��һ���ģ�Ψһ��������Ҫ����һ��rpc_serve��ע������˿�
rpc_serve
-- ����1��RPC����
-- ����������RPC������Ҫ�Ĳ���

��lpcһ����rpc����������ͨ��LUA����������Ĳ���ǰ�����ǹ̶��ģ���������RPC����
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

-- ����RPC����
local ok = c.rpc_serve("rpc", "0.0.0.0", 1218)

function say_hello(sid, from, v0, v1)
    print ("============recv", sid, from, v0, v1, "\n")
    c.rpc_suspend(sid, 5000) -- ����RPC�������5000���뷵�ؽ��
    c.rpc_response(sid, "hi", "response", 56789) --���ؽ��
end

