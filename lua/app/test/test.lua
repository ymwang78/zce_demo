local zce = require "zce.core"
local lu = require('util.luaunit')
local cfg = require('test.config')
_M = {}

function _M.test_me()

    zce.log(1, "\t", "...........start...........", s)

    cfg.setConfig()
    
    zce.new_service("", "lua/app/test/test_pack.lua")

    -- zce.new_service("", "lua/app/test/test_package.lua")

    -- zce.new_service("test_protobuf", "lua/app/test/test_protobuf.lua")

    -- zce.new_service("test_lpcsvr", "lua/app/test/test_rpc_server.lua", 1217)

    -- zce.new_service("test_lpccli", "lua/app/test/test_rpc_client.lua", tpool, "test_lpcsvr", 1217)

    -- zce.new_service("test", "lua/app/test/test_cache.lua")

    -- zce.new_service("test_vmerr", "lua/app/test/test_vmerr.lua", tpool)
    -- zce.new_service("", "lua/app/test/test_websocket_server.lua")

    -- zce.new_service("", "lua/app/test/test_websocket_client.lua")
end

function _M.debug()

    zce.new_service("test_sqlite", "lua/app/test/test_sqlite.lua")

    zce.new_service("test_vmerr", "lua/app/test/test_vmerr.lua", tpool)

    zce.new_service("", "lua/app/test/test_vmerr.lua", tpool)

    zce.new_service("test_timer", "lua/app/test/test_timer.lua", tpool)

    zce.new_service("", "lua/app/test/test_timer.lua", tpool)

    zce.new_service("test_pgsql", "lua/app/test/test_pgsql.lua")
    
    zce.new_service("", "lua/app/test/test_pgsql.lua")

    zce.new_service("test_cache", "lua/app/test/test_cache.lua")

    zce.new_service("", "lua/app/test/test_cache.lua")

    zce.new_service("", "lua/app/test/test_package.lua")

    zce.new_service("test_rawsvr", "lua/app/test/test_rawsocket_server.lua")
    
    zce.new_service("test_rawcli", "lua/app/test/test_rawsocket_client.lua")

    zce.new_service("", "lua/app/test/test_rawsocket_server.lua")

    zce.new_service("", "lua/app/test/test_rawsocket_client.lua")

    -- zce.new_service("test_storm", "lua/test/test_storm.lua", tpool)
    
    zce.new_service("", "lua/app/test/test_storm.lua", tpool)

    zce.new_service("test_lpcsvr", "lua/app/test/test_rpc_server.lua")

    zce.new_service("test_lpccli", "lua/app/test/test_rpc_client.lua", tpool)

    zce.new_service("", "lua/app/test/test_rpc_client.lua", tpool)

    zce.new_service("test_pack", "lua/app/test/test_pack.lua")

    zce.new_service("", "lua/app/test/test_pack.lua")

    -- zce.new_service("test_httpsvr", "lua/app/test/test_http_server.lua")

    -- zce.new_service("test_httpcli", "lua/app/test/test_http_client.lua")

    zce.new_service("", "lua/app/test/test_http_server.lua")

    zce.new_service("", "lua/app/test/test_http_client.lua")
    
    -- zce.new_service("websvr", "lua/app/test/test_websocket_server.lua")

    -- zce.new_service("test_cjson", "lua/app/test/test_cjson.lua", tpool)

    -- zce.new_service("test_protobuf", "lua/app/test/test_protobuf.lua")
        
end

return _M;
