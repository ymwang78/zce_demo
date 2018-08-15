local c = require "zce.core"


--[[
local t = require("tooyoung.tooyoung")
t.start()

local unitest = require("tooyoung.unittest")
unitest.test_me()

--]]
---[[
c.vm_addpath('./lua/app/?.lua')
local t = require("app.diandian.diandian")
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