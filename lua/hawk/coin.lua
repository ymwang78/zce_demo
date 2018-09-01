local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M
local c = require "zce.core"
local cjson = require "cjson"
local bson = require "bson"
local lu = require('luaunit')
local session = require("auth.session")

local ok, hawkcacheobj = c.cache_init("local", "hawk.cache")
lu.assertEquals(ok, true)

local ok, coinrpcid = c.cache_get(hawkcacheobj, "hawk.coin.rpcid")
lu.ensureEquals(ok, true, coinrpcid)

--[[
	tradectx : {
	    string  serialid[~];  //流水号
        int64   logtime;      //交易时间
        int64   coinnum;      //变化数量
        int64   original;     //变化前数量
        int64   remain;       //变化后数量
        string  tradetype[~]; //支付类型
        string  tradename[~]; //交易名
        string  tradeid[~];   //交易ID
        string  memo[~];      //备注
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
	local rpcok, ok, res = c.rpc_call(coinrpcid, "rpc_TradeCoin", serialid, tradeid, tradetype, tradename, memo, tradeoffers, coinlockid, critisteps, endlock, allowneg)
	c.log(1, "\t", "tradeCoin:", rpcok, ok, res)
	return ok, res
end

function _M.queryCoin(serialid, queryoffers, coinlockid)
	local rpcok, ok, res = c.rpc_call(coinrpcid, "rpc_QueryCoin", serialid, queryoffers, coinlockid)
	c.log(1, "\t", "queryCoin:", rpcok, ok, res)
	return ok, res
end

function _M.queryCoinOne(serialid, coinname, useridx, coinlockid)
	local ok, res = _M.queryCoin("", { {coinname = coinname, useridx = useridx} }, "")
	if ok and res ~=nil and res.data ~= nil then
		c.log(1, "\t", "queryCoinOne:", ok, res.data[1])
		return ok, res.data[1]
	end
	return false, nil
end

function _M.queryHistory(coinname, useridx, begint, endt, startidx, querynum)
	local rpcok, ok, res = c.rpc_call(coinrpcid, "rpc_QueryHistory", coinname, useridx, begint, endt, startidx, querynum)
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

function _M.procHttpReq(data)
	local bodyobj = {}
	if string.len(data.body) > 0 then
		if ( data.header['Content-Type'] ~= nil and string.match(data.header['Content-Type'], "application/json") ) then
			bodyobj = cjson.decode(data.body)
		end
	end

	local login_session  =session.getSession(data.parameters.session_key)
	if login_session == nil then 
		return nil, 401
	end

	local adobj

	if (string.match(data.path, "/coin/doTestMe")) then
		local ok, res = _M.doTestMe()
		adobj = res
	else
		return nil, 404
	end

	if (adobj == nil) then
		return ""
	else
		return cjson.encode(adobj), 200, { ['Content-Type'] = "application/json"}
	end
end

