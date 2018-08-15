local c = require "zce.core"
local lu = require('luaunit')

_M = {}

function _M.test_me()

	c.log(1, "\t", "...........start...........")

	-- mempool 设置内置内存池，调节APP性能
	-- 特别是sharedata 存放的数据将从mempool取
	local ok = c.new_mempool(64, 10240)
	local ok = c.new_mempool(128, 10240)
	local ok = c.new_mempool(256, 10240)
	local ok = c.new_mempool(512, 10240)
	local ok = c.new_mempool(1024, 10240)

	local ok, tpool = c.new_threadpool(2)

	local ok, configdb = c.cache_init("local", "config")
	c.cache_set(configdb, 0, "mypool", tpool)
	
	c.new_service("test_sqlite", "lua/test/test_sqlite.lua")

end

function _M.debug()


	c.new_service("test_vmerr", "lua/test/test_vmerr.lua", tpool)

	c.new_service("", "lua/test/test_vmerr.lua", tpool)

	c.new_service("test_timer", "lua/test/test_timer.lua", tpool)

	c.new_service("", "lua/test/test_timer.lua", tpool)

	c.new_service("test_pgsql", "lua/test/test_pgsql.lua")
	
	c.new_service("", "lua/test/test_pgsql.lua")

	c.new_service("test_cache", "lua/test/test_cache.lua")

	c.new_service("", "lua/test/test_cache.lua")

	c.new_service("test_rawsvr", "lua/test/test_rawsocket_server.lua")
	
	c.new_service("test_rawcli", "lua/test/test_rawsocket_client.lua")

	c.new_service("", "lua/test/test_rawsocket_server.lua")

	c.new_service("", "lua/test/test_rawsocket_client.lua")

	-- c.new_service("test_storm", "lua/test/test_storm.lua", tpool)
	
	c.new_service("", "lua/test/test_storm.lua", tpool)

	c.new_service("test_lpcsvr", "lua/test/test_rpc_server.lua")

	c.new_service("test_lpccli", "lua/test/test_rpc_client.lua", tpool)

	c.new_service("", "lua/test/test_rpc_client.lua", tpool)

	c.new_service("test_pack", "lua/test/test_pack.lua")

	c.new_service("", "lua/test/test_pack.lua")

	-- c.new_service("test_httpsvr", "lua/test/test_http_server.lua")

    -- c.new_service("test_httpcli", "lua/test/test_http_client.lua")

	c.new_service("", "lua/test/test_http_server.lua")

    c.new_service("", "lua/test/test_http_client.lua")
	
	-- c.new_service("websvr", "lua/test/test_websocket_server.lua")

	-- c.new_service("test_cjson", "lua/test/test_cjson.lua", tpool)

	-- c.new_service("test_protobuf", "lua/test/test_protobuf.lua")
		
end

return _M;
