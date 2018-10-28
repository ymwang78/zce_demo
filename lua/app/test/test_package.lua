local zce = require "zce.core"
local lu = require('util.luaunit')
local cfg = require('hawk.config')
local hp = require('hawk.package.package')
local hpexc = require('hawk.package.exclude')

TestPackage = {}

function TestPackage:test_exclude()

    hpexc.clearExcludeCount('gift.hello', '20180101', 1)

    local cnt = hpexc.getExcludeCount('gift.hello', '20180101', 1)
    local ok = (cnt == 0)
    lu.assertEquals(ok, true)

    local cnt = hpexc.incExcludeCount('gift.hello', '20180101', 1)
    local ok = cnt == 1
    lu.assertEquals(ok, true)

    local cnt = hpexc.getExcludeCount('gift.hello', '20180101', 1)
    local ok = cnt == 1
    lu.assertEquals(ok, true)

    local cnt = hpexc.incExcludeCount('gift.hello', '20180101', 1)
    local ok = cnt == 2
    lu.assertEquals(ok, true)

    local cnt = hpexc.getExcludeCount('gift.hello', '20180101', 1)
    local ok = cnt == 2
    lu.assertEquals(ok, true)
end

function TestPackage:__test_package()

    -- 增加一个背包道具
    local ok, res = hp.addPackage(3, "Pet", { pkgid = 'dog001', pkgtype = 'dog', pkgnum = 1, foot = 4})
    lu.ensureEquals(ok, true)
    local ok, res = hp.addPackage(3, "Pet", { pkgid = 'cat001', pkgtype = 'cat', pkgnum = 1, foot = 4})
    lu.ensureEquals(ok, true)
    local ok, res = hp.addPackage(3, "Prop", { pkgid = 'prop001', pkgtype = 'knife', pkgnum = 1})
    lu.ensureEquals(ok, true)

    for i = 1,100 do
        -- local ok, res = hp.addPackage(3, "Pet", { pkgid = 'cat' .. i, pkgtype = 'cat', pkgnum = 1, foot = 4})
        --lu.ensureEquals(ok, true)
    end
    -- 增加或者修改一个背包道具属性
    
    local ok, res = hp.updatePackageItem(3, "Pet", 'dog001', {eye = 3})
    lu.ensureEquals(ok, true)
    local ok, res = hp.updatePackageItem(3, "Pet", 'dog001', {ear = 4})
    lu.ensureEquals(ok, true)

    -- 删除一个背包道具属性
    local ok, res = hp.deletePackageItem(3, "Pet", 'dog001', 'ear')
    lu.ensureEquals(ok, true)

    -- 删除一个道具
    local ok, res = hp.delPackage(3, "Pet", "cat001")
    lu.ensureEquals(ok, true)

    -- 查询背包，每页几个，第几页，只需要总数，第0页即可
    -- filter是过滤条件，不填是不过滤
    for i = 0,1 do
        local ok, res = hp.queryPackageItem(3, "Pet", 10, i, { pkgtype = 'dog'})
        lu.ensureEquals(ok, true)
        zce.log(1, "|", ok, zce.tojson(res, true))
    end
end

lu.run()
