local zce = require("zce.core")

zce.vm_addpath('./lua/app/?.lua')
---[[
    local unitest = require("test.test")
    unitest.test_me()
-- ]]
--[[
local ok = zce.new_service('btcpay', "./lua/app/btcpay/btcmain.lua")
--]]

-- port manage
-- out service
---- 5180 ws
---- 5181 wss
---- 5182 coin.elec 
---- 5183 test ssl purpose port

-- inner service
---- 9100 electrum rpc port

