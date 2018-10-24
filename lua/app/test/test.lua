local c = require "zce.core"
local lu = require('luaunit')
local cfg = require('test.config')
_M = {}

function _M.test_me()

    c.log(1, "\t", "...........start...........", s)

    cfg.setConfig()
    
    

    c.new_service("test_lpcsvr", "lua/app/test/test_rpc_server.lua", 1217)

    c.new_service("test_lpccli", "lua/app/test/test_rpc_client.lua", tpool, "test_lpcsvr", 1217)

    -- c.new_service("test", "lua/app/test/test_cache.lua")

    -- c.new_service("test_vmerr", "lua/app/test/test_vmerr.lua", tpool)
    -- c.new_service("", "lua/app/test/test_rawsocket_server.lua")

    -- c.new_service("", "lua/app/test/test_rawsocket_client.lua")
end

function _M.debug()

    c.new_service("test_sqlite", "lua/app/test/test_sqlite.lua")

    c.new_service("test_vmerr", "lua/app/test/test_vmerr.lua", tpool)

    c.new_service("", "lua/app/test/test_vmerr.lua", tpool)

    c.new_service("test_timer", "lua/app/test/test_timer.lua", tpool)

    c.new_service("", "lua/app/test/test_timer.lua", tpool)

    c.new_service("test_pgsql", "lua/app/test/test_pgsql.lua")
    
    c.new_service("", "lua/app/test/test_pgsql.lua")

    c.new_service("test_cache", "lua/app/test/test_cache.lua")

    c.new_service("", "lua/app/test/test_cache.lua")

    c.new_service("", "lua/app/test/test_package.lua")

    c.new_service("test_rawsvr", "lua/app/test/test_rawsocket_server.lua")
    
    c.new_service("test_rawcli", "lua/app/test/test_rawsocket_client.lua")

    c.new_service("", "lua/app/test/test_rawsocket_server.lua")

    c.new_service("", "lua/app/test/test_rawsocket_client.lua")

    -- c.new_service("test_storm", "lua/test/test_storm.lua", tpool)
    
    c.new_service("", "lua/app/test/test_storm.lua", tpool)

    c.new_service("test_lpcsvr", "lua/app/test/test_rpc_server.lua")

    c.new_service("test_lpccli", "lua/app/test/test_rpc_client.lua", tpool)

    c.new_service("", "lua/app/test/test_rpc_client.lua", tpool)

    c.new_service("test_pack", "lua/app/test/test_pack.lua")

    c.new_service("", "lua/app/test/test_pack.lua")

    -- c.new_service("test_httpsvr", "lua/app/test/test_http_server.lua")

    -- c.new_service("test_httpcli", "lua/app/test/test_http_client.lua")

    c.new_service("", "lua/app/test/test_http_server.lua")

    c.new_service("", "lua/app/test/test_http_client.lua")
    
    -- c.new_service("websvr", "lua/app/test/test_websocket_server.lua")

    -- c.new_service("test_cjson", "lua/app/test/test_cjson.lua", tpool)

    -- c.new_service("test_protobuf", "lua/app/test/test_protobuf.lua")
        
end

return _M;
