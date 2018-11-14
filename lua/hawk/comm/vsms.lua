--[[
    发送验证码
--]]

local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require("zce.core")
local lu = require("util.luaunit")
local cjson = require("cjson")
local cfg = require("hawk.config")

function _M.sendVsms(cellid, code)
    local url = cfg.vsmsurl .. "/" .. cellid .. "/" .. code
    local ok, code, param, body = zce.http_request("GET", url)
    zce.log(1, "|", ok, code, param, body)
    if not ok then
        return false
    end
    if code ~= 200 then
        return false
    end
    return true
end