--[[

RPC服务端的代码跟LPC是一样的，唯一区别是需要调用一次rpc_serve来注册监听端口
rpc_serve
-- 参数1：RPC类型
-- 后续参数，RPC服务需要的参数

与lpc一样，rpc服务函数是普通的LUA函数，传入的参数前两个是固定的，后续的是RPC参数
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

-- 启动RPC服务
local ok = c.rpc_serve("rpc", "0.0.0.0", 1218)

function say_hello(sid, from, v0, v1)
    print ("============recv", sid, from, v0, v1, "\n")
    c.rpc_suspend(sid, 5000) -- 告诉RPC调用最迟5000毫秒返回结果
    c.rpc_response(sid, "hi", "response", 56789) --返回结果
end

