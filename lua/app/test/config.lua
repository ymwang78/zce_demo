local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require("zce.core")
local lu = require("luaunit")
local util = require("util.util")
local cfg = require("hawk.config")
local setting = require("app.test.test_setting")

local function initConfig()
    local ok, hk_cache = zce.cache_init("local", "app.test")
    lu.ensureEquals(ok, true)
    local ok, cfg = zce.cache_get(hk_cache, "config")
    if not ok or cfg == nil then
        return
    end
    -- zce.log(1, "|", zce.tojson(cfg, true))
    util.shallowMerge(_M, cfg)
end

function _M.setConfig()
    cfg.setConfig(setting)

    cfg.setConfig = nil

    local ok, config = zce.cache_init("local", "app.test")
    lu.ensureEquals(ok, true)
    zce.log(1, "|", zce.tojson(cfg, true))

    zce.cache_set(config, 0, "config", cfg)

    initConfig()
end

initConfig()
