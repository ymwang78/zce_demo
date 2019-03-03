local workerIndex, totalCount, batchCount, waitMSec  = ...
local zce = require "zce.core"
local lu = require('util.luaunit')
local lrun = require('hawk.loadrunner.loadrunner')

TestLoadRunner = {
    totalWorkerCount = 10,
    totalCount = 55,
    batchCount = 10,
    waitMSec = 1000,
    workerFinishedCount = 0,
    summaryData = {
        connSucceed = 0,
        connFailed = 0
    }
}

zce.log(1, "|", "test_loadrunner", workerIndex, totalCount, batchCount, waitMSec )

function summaryReport(sid, from, workIndex, summaryData)
    TestLoadRunner.workerFinishedCount = TestLoadRunner.workerFinishedCount + 1
    TestLoadRunner.summaryData.connSucceed = TestLoadRunner.summaryData.connSucceed + summaryData.connSucceed
    TestLoadRunner.summaryData.connFailed = TestLoadRunner.summaryData.connFailed + summaryData.connFailed
    if TestLoadRunner.workerFinishedCount >= TestLoadRunner.totalWorkerCount then
        zce.log(1, "|", "summaryReport", zce.tojson(TestLoadRunner, true))
    end
end

function TestLoadRunner:startTest(curUserData)
    -- 单个会话的测试逻辑

    local ok = zce.tcp_connect("tcp://www.taobao.com:80/", curUserData)
    if ok then 
        TestLoadRunner.summaryData.connSucceed = TestLoadRunner.summaryData.connSucceed + 1
    else
        TestLoadRunner.summaryData.connFailed = TestLoadRunner.summaryData.connFailed + 1
    end

    -- workerIndex, sessionIndex 可以用于生成压测用户数据
    zce.log(1, "|", "startTest", curUserData.SESSION.workerIndex, curUserData.SESSION.sessionIndex, curUserData.SESSION.batchIndex, ok)

    -- 发送登陆请求
    local ok = zce.tcp_send(curUserData, "GET \r\n")
    zce.log(1, "|", "tcp_send", ok)

    -- 接受登陆响应, 最多等待10000豪秒，如果超时 ok ==false data == nil
    local ok, data = zce.tcp_read(curUserData, 10000)
    zce.log(1, "|", "tcp_read", ok, data)

    -- 集合等待20个会话一起到下一步，集合是跨虚拟机的，可以真正并发
    -- 注意集合数量应该是总数的整除数，不然有些就干等了
    local ok = zce.rendezvous("tomeet", 20)

    zce.tcp_close(curUserData)

    -- 再次集合等待一起结束，+1是为了主逻辑也可以参与等待
    local ok = zce.rendezvous("end" .. workerIndex, totalCount + 1)
end

function TestLoadRunner:test_start()
    if workerIndex == nil then
        -- W000 主压测VM SERVICE
        lrun.prepareWorker(TestLoadRunner.totalWorkerCount, 'lua/app/test/test_loadrunner.lua', 
            TestLoadRunner.totalCount, TestLoadRunner.batchCount, TestLoadRunner.waitMSec)
    else
        -- 启动压测工作机逻辑
        lrun.startLoad(TestLoadRunner, workerIndex, totalCount, batchCount, waitMSec)

        -- 集合等待工作机压测结束
        local ok = zce.rendezvous("end" .. workerIndex, totalCount + 1)
        zce.log(1, "|", "test finished")

        --收集压测结果，报告给主压测service，生成统计结果
        local ok, lpcid = zce.rpc_ident("lpc", "W000")
        local ok, data = zce.rpc_call(lpcid, "summaryReport", workerIndex, TestLoadRunner.summaryData)
    end
end

lu.run()

zce.usleep(100000)