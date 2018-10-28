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

    -- ����һ����������
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
    -- ���ӻ����޸�һ��������������
    
    local ok, res = hp.updatePackageItem(3, "Pet", 'dog001', {eye = 3})
    lu.ensureEquals(ok, true)
    local ok, res = hp.updatePackageItem(3, "Pet", 'dog001', {ear = 4})
    lu.ensureEquals(ok, true)

    -- ɾ��һ��������������
    local ok, res = hp.deletePackageItem(3, "Pet", 'dog001', 'ear')
    lu.ensureEquals(ok, true)

    -- ɾ��һ������
    local ok, res = hp.delPackage(3, "Pet", "cat001")
    lu.ensureEquals(ok, true)

    -- ��ѯ������ÿҳ�������ڼ�ҳ��ֻ��Ҫ��������0ҳ����
    -- filter�ǹ��������������ǲ�����
    for i = 0,1 do
        local ok, res = hp.queryPackageItem(3, "Pet", 10, i, { pkgtype = 'dog'})
        lu.ensureEquals(ok, true)
        zce.log(1, "|", ok, zce.tojson(res, true))
    end
end

lu.run()
