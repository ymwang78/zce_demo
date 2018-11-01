local zce = require "zce.core"

--[[
-- Hawk需要一些配置项，写入"hawk.cache"的DB
local ok, hawkcfg_obj = zce.cache_init("local", "hawk.config")
lu.assertEquals(ok, true)

-- Hawk默认使用如下对象名称

--PG数据库对象名 "pgdb"
local ok, pgdb = zce.rdb_conn("pgsql", "hawk:zhiduhawk@pgsql.svr:5432/hawk", tpool)
lu.assertEquals(ok, true)
c.cache_set(hawkcfg_obj, 0, "pgdb", pgdb)

--虚拟币数据库对象名 "pgcoindb"
local ok, pgcoindb = zce.rdb_conn("pgsql", "hawk:zhiduhawk@pgsql.svr:5432/coindb", tpool)
lu.assertEquals(ok, true)
c.cache_set(hawkcfg_obj, 0, "pgcoindb", pgcoindb)

--redis数据库对象名 "redis"
local ok, redisip = zce.dns_resolve("redis.svr")
lu.assertEquals( ok, true )
local ok, redisobj = zce.cache_init("redis",  redisip, 6379, "redis.passwd")
lu.assertEquals(ok, true)
c.cache_set(hawkcfg_obj, 0, "redis", redisobj)

建议APP相关系统配置在入口模块里写入名为"config"的local cache
local ok, config = zce.cache_init("local", "config")
lu.assertEquals(ok, true)

-- http监听服务名 "httpd_listenaddr"
c.cache_set(config, 0, "httpd_listenaddr", "0.0.0.0", 4180)

-- 如果与hawk共享DB，可以直接重用OBJ
c.cache_set(config, 0, "pgdb", pgdb)
c.cache_set(config, 0, "redis", redisobj)

--]]

--[[
c.vm_addpath('./lua/app/?.lua')
local t = require("app.diandian.main")
t.start()
--]]

---[[
c.vm_addpath('./lua/app/?.lua')
c.vm_addpath('./lua/app/battleoflove/?.lua')
local t = require("app.battleoflove.server.dbservice")
t.start()
local t = require("app.battleoflove.server.service")
t.start()
--]]

--[[
local unitest = require("diandian.unittest")
unitest.test_me()
--]]

--[[
local unitest = require("test.test")
unitest.test_me()
--]]
