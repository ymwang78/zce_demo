--[[
new_threadpool 创建一个线程池
-- 参数1，线程池内的线程数量

new_service 启动一个独立的虚拟机，赋于一个名字，并执行相关文件
启动的lua虚拟机，也就是这个执行这个文件的虚拟机有默认的名字 "main"

每个虚拟机是状态独立的，但是默认是与主虚拟机共享执行线程池，
如果多个独立的服务跑了大量的阻塞API，会导致执行线程池被消耗光，
因此new_service允许用户指定该服务使用独立的线程池，并指定工作线程数量

一个可能的场景：
通过这种机制和LPC服务机制，可以独立于底层框架独立由LUA自身实现可能阻塞API的COROUTINE实现。
例如手里有mongodb查询的lua库，但是是阻塞的，底层框架尚未提供COROUTINE支持。
这时候就可以实现一个MONGODB的查询服务，并指定独立的线程池。
使用者使用LPC调用实现COROUTINE查询，保障主逻辑模块是非阻塞的。

但是注意，一个虚拟机只能占用一个线程，因此如果要实现多个线程跑同一个服务，需要自己包装，
多次以不同的名字，比如"svr0","svr1"，多次调用new_service，
然后自行封装API来投递lpc分配调用给不同的svr

-- 参数1， 名字
-- 参数2,  文件
-- 参数3， 线程数池句柄，可选
--]]

local c = require "zce.core"

--[[
local t = require("tooyoung.tooyoung")
t.start()

local unitest = require("tooyoung.unittest")
unitest.test_me()

--]]
--[[
local t = require("diandian.diandian")
t.start()

local unitest = require("diandian.unittest")
unitest.test_me()
--]]

local unitest = require("test.test")
unitest.test_me()
