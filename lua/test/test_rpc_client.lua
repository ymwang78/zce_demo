--[[
为了充分挖掘多核机器优势，每个new_service调用会产生一个独立的LUA虚拟机，（主文件入库默认为"main"）
new_service(服务名, lua文件名)
lpc服务可实现跨虚拟机调用

rpc_call : 调用一个远程服务
-- 第一个参数，表明RPC类型，目前只支持lpc
    --"lpc" : 表明这是一个本机本进程其他服务提供的函数（跨虚拟机，跨OS线程）
-- 第二个参数，服务名，虚拟机new_service函数注册了服务名
-- 第三个参数，RPC函数名
-- 后续参数，RPC函数调用参数

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
