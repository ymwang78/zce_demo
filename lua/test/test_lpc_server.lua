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

local c = require "zce.core"

local ok, rpcid = c.rpc_ident("lpc", "test_lpcsvr")

function say_hello(sid, from, v0, v1)
    print ("============say_hello", sid, from, v0, v1)
    c.usleep(2000);
    c.rpc_suspend(sid, 5000) -- 告诉RPC调用最迟5000毫秒返回结果
    local ok, usleepack = c.rpc_call(rpcid, "usleep", 2000) -- 可以再次向自己发起一个RPC调用
    print ("------------", sleepack)
    c.rpc_response(sid, "hi", "response", 56789) --返回结果
end

function usleep(sid, from, v0, v1)
    print ("============usleep", sid, from, v0)
    c.usleep(v0)
    c.rpc_response(sid, "usleep ack")
    print ("============usleepend\n", sid)
end

function test_locallpc()
    print ("============test_locallpc")
    local ok, localack = c.rpc_call(rpcid, "usleep", 2000, "abcd") -- 可以再次向自己发起一个RPC调用
    print ("------------return", ok, localack)
end

-- co = coroutine.create(test_locallpc)
-- coroutine.resume(co)

test_locallpc()
