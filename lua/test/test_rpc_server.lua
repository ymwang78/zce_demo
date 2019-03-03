--[[

lpc服务函数是普通的LUA函数，传入的参数前两个是固定的，后续的是RPC参数
-- sid  ：表明这个RPC调用的SESSION ID，可通过这个sid通过rpc_response函数返回结果给调用者，只能用一次，后续的调用会被丢弃
-- from ：表明调用的来源服务名，从new_service注册的服务名（主文件入库默认为"main"）

rpc_response 直接返回结果，第一个参数固定是SID, 后面是返回参数
-- sid ：同上

rpc_suspend 为了防止RPC调用忘记调用rpc_response，导致rpc_call无限制等待，
特地增加rpc_suspend,告诉RPC服务函数本函数不返回结果，SID记住后晚一点再返回，或者由其他函数返回
如果再LPC服务函数里既不调用rpc_response，也不调用rpc_suspend，调用者将直接收到一个返回为空的结果
参数第一个为sid, 第二个是超时时间，如果过了超时时间，RPC调用者会收到一个空的结果，后续再调用rpc_response将被丢弃

--]]
local rpcport = ...

local zce = require "zce.core"
local lu = require('util.luaunit')

TestLpcSvr = {}

if rpcport == nil then
    -- rpcport = 1218
end

local ok, rpcserv = zce.rpc_serve("rpc", "0.0.0.0", 1217, "say_")
lu.assertEquals( ok, true )
-- local ok, rpcid = zce.rpc_ident("lpc", "test_lpcsvr")
-- lu.assertEquals( ok, true )

function say_hello(sid, from, v0, v1)
    --c.log(1, " ", "request(say_hello):" , sid, from, v0, v1)
    zce.rpc_response(sid, "hi", "response", rpcport)

end

function say_hello_timeout(sid, from, v0, v1)
    zce.log(1, " ", "request(say_hello_timeout):" , sid, from, v0, v1)
    zce.usleep(6 * 1000)
    zce.rpc_response(sid, "hi", "response", 56789)
end

function say_hello_noresponse(sid, from, v0, v1)
    zce.log(1, " ", "request(say_hello_noresponse):" , sid, from, v0, v1)
end

function say_hello_delay(sid, from, v0, v1)
    zce.rpc_suspend(sid, 10000) -- 默认超时5秒，告诉系统最多要10秒，但是对RPC无效
    zce.log(1, " ", "request(say_hello_delay):" , sid, from, v0, v1)
    zce.usleep(6 * 1000)
    zce.rpc_response(sid, "hi", "response", 56789)
end

function say_hello_cascade(sid, from, v0, v1)
    zce.log(1, " ", "request(say_hello_cascade):" , sid, from, v0, v1)
    local ok, v0, v1, v2 = zce.rpc_call(rpcid, "say_hello", v0, v1) -- 可以再次向自己发起一个RPC调用
    zce.rpc_response(sid,  v0, v1, v2) 
end

function norpc_say_hello(sid, from, v0, v1)
    zce.rpc_response(sid,  v0, v1, v2) 
end

function TestLpcSvr:_call_self()
    local ok, v0, v1, v2 = zce.rpc_call(rpcid, "say_hello", 2000, "abcd")
    zce.log(1, " ", "response(say_hello):", ok, v0, v1, v2)
    lu.assertEquals( ok, true )

    -- allow lpc call any method 
    local ok, v0, v1, v2 = zce.rpc_call(rpcid, "norpc_say_hello", 2000, "abcd")
    zce.log(1, " ", "response(norpc_say_hello):", ok, v0, v1, v2)
    lu.assertEquals( ok, true )
end

-- co = coroutine.create(test_locallpc)
-- coroutine.resume(co)

lu.run()

c.usleep(500000)

-- local ok = zce.rpc_close(rpcid)
-- lu.assertEquals( ok, true )

local ok = zce.rpc_close(rpcserv)
lu.assertEquals( ok, true )