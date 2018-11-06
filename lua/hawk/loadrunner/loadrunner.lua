local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require('zce.core')
local lut = require('util.luaunit')

_M.workerRpcIdent = {}

local function _starTest(lrObj, sessionData)
    lrObj:startTest(sessionData)
end

function _M.prepareWorker(count, testfile, ...)
    for i = 1, count do
        local servicename = string.format("W%03d", i)
        zce.log(1, "|", "prepareWorker", servicename)
        zce.new_service(servicename, testfile, i, ...)
        local ok, rpcident = zce.rpc_ident("lpc", servicename)
        _M.workerRpcIdent[i] = rpcident
    end
end

-- workerIndex : 当前worker service idx
-- totalCount : worker总共多少个SESSION
-- batchCount : 每批执行多少个SESSION
-- waitMSecond : 批次之间间隔
function _M.startLoad(lrObj, workerIndex, totalCount, batchCount, waitMSecond)
    local sessionIndex = 1
    local batchIndex = 1
    lrObj.batchData = {}
    lrObj.sessionData = {}
    local workerCount = #_M.workerRpcIdent

    while sessionIndex <= totalCount do
        local curBatchEnd = sessionIndex + batchCount - 1
        if (curBatchEnd > totalCount) then curBatchEnd = totalCount; end
        local batchCount = curBatchEnd + 1 - sessionIndex
        for i=sessionIndex, curBatchEnd do 
            zce.log(1, "|", "curBatch", sessionIndex, curBatchEnd)
            local sessionData = lrObj.sessionData[sessionIndex]
            if sessionData == nil then
                sessionData = {
                    BATCH = lrObj.batchData[batchIndex],
                    SESSION = {
                        workerIndex = workerIndex,
                        sessionIndex = sessionIndex,
                        batchIndex = batchIndex,
                        batchCount = batchCount
                    }
                }
                lrObj.sessionData[sessionIndex] = sessionData
            end
            
            zce.co_call(_starTest, lrObj, sessionData)
            sessionIndex = sessionIndex + 1
        end
        batchIndex = batchIndex + 1
        zce.usleep(waitMSecond)
    end
end