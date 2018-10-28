local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M
local c = require("zce.core")
local lu = require('util.luaunit')
local cjson = require("cjson")
local bson = require("bson")
local cfg = require("hawk.config")

--[[
    tradectx : {
        string  serialid[~];  //��ˮ��
        int64   logtime;      //����ʱ��
        int64   coinnum;      //�仯����
        int64   original;     //�仯ǰ����
        int64   remain;       //�仯������
        string  tradetype[~]; //֧������
        string  tradename[~]; //������
        string  tradeid[~];   //����ID
        string  memo[~];      //��ע
    },
    tradeoffers : [ {coinname, useridx, coinnum, coinlockid}, ...
    ],
    critisteps : int value,
    endlock : boolean,
    allowneg : boolean

    tradeex3_req_t
    {
        string serverid[~];
        strvec coinnames[~];
        int64 useridxs[~];
        int64 coinnums[~];
        struct tradelog_t tradelog;
        string coinlockid[~];
        int critisteps;
        byte endlock;
        byte allowneg;
    };
]]

function _M.tradeCoin(serialid, tradeid, tradetype, tradename, memo, tradeoffers, coinlockid, critisteps, endlock, allowneg)
    local rpcok, ok, res = c.rpc_call(cfg.coinrpc.coinrpcid, "rpc_TradeCoin", serialid, tradeid, tradetype, tradename, memo, tradeoffers, coinlockid, critisteps, endlock, allowneg)
    c.log(1, "\t", "tradeCoin:", rpcok, ok, res)
    return ok, res
end

function _M.queryCoin(serialid, queryoffers, coinlockid)
    local rpcok, ok, res = c.rpc_call(cfg.coinrpc.coinrpcid, "rpc_QueryCoin", serialid, queryoffers, coinlockid)
    c.log(1, "\t", "queryCoin:", rpcok, ok, res)
    return ok, res
end

function _M.queryCoinOne(coinname, useridx, coinlockid)
    local ok, res = _M.queryCoin("", { {coinname = coinname, useridx = useridx} }, "")
    if ok and res ~=nil and res.data ~= nil then
        c.log(1, "\t", "queryCoinOne:", ok, res.data[1])
        return ok, res.data[1]
    end
    return false, nil
end

function _M.queryHistory(coinname, useridx, begint, endt, startidx, querynum)
    local rpcok, ok, res = c.rpc_call(cfg.coinrpc.coinrpcid, "rpc_QueryHistory", coinname, useridx, begint, endt, startidx, querynum)
    c.log(1, "\t", "queryHistory:", rpcok, ok, res)
    return ok, res
end

function _M.doTestMe()
    return true, {
    queryCoin = { _M.queryCoin("", { {coinname = "dian_coin", useridx = 3} }, "") },
    queryHistory = { _M.queryHistory("dian_coin", 3, c.time_now() - 7 * 24 * 3600, c.time_now(), 0, 100) },
    tradeCoin = { _M.tradeCoin("", "testradeid", "testtype", "testtradename", "testmemo", 
        { {coinname = "dian_coin", useridx = 3, coinnum = 100} }, "", 0, true, true )  }
    }
end

