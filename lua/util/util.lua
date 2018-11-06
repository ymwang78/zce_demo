local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require("zce.core")

_M.ERRCODE_UTIL_BASE = -1000
_M.ERRCODE_UTIL_INVALIDARG = -1001

function _M.checkTableItem(formular, t)
    if formular == nil then
        return true, nil
    end
    for i, v in ipairs(formular) do
        if t[v[1]] == nil then
            return false, { errcode = _M.ERRCODE_UTIL_INVALIDARG, errdesc = "缺少参数:" .. v[1] .. ', ' .. v[2]}
        end
    end
    return true, nil
end

function _M.filterTableItemInPlace(formular, t)
    if formular == nil then
        return true, nil
    end
    for k, v in pairs(formular) do
        for k1, v1 in pairs(t) do
            zce.log(1, "|", k, v, k1, v1)
            if v1[k] ~= v then
                t[k1] = nil
            end
        end
    end
    return true, nil
end

function _M.shallowMerge(dst, orig)
    local orig_type = type(orig)
    if orig_type == 'table' then
        for orig_key, orig_value in pairs(orig) do
            dst[orig_key] = orig_value
        end
    end
    return dst
end

function _M.shallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function _M.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--[[
Ordered table iterator, allow to iterate on the natural order of the keys of a
table.

Example:
]]

local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

local function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1, #t.__orderedIndex do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function _M.orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

function _M.checkPhone(var)
    local b = tonumber(var)
    if (b == nil) then
        return false
    end
    if(#tostring(b) ~= 11) then
        return false
    end
    return true
end


-- 根据table产生字符
function _M.getParameterString(parameters, skipsign)
    local paramstr = ''
    local count = 0
    for k, v in _M.orderedPairs(parameters) do
        if k ~= skipsign then
            if count == 0 then
                paramstr = paramstr .. k .. '=' .. v 
            else
                paramstr = paramstr .. '&' .. k .. '=' .. v
            end
            count = count + 1
        end
    end
    return paramstr
end

-- 根据table 计算签名
function _M.signTable(parameters, suffix, prefix)
    local paramstr = _M.getParameterString(parameters, nil)
    if prefix == nil then
        prefix = ''
    end
    local mysign = zce.encode_md5(prefix .. paramstr .. suffix)
    zce.log(1, "|", prefix .. paramstr .. suffix, mysign)
    return mysign
end

function _M.getTimeId(idt, t)
    if idt == 0 then
        return 'ever'
    elseif idt == 1 then
        return 'day.' .. zce.time_strftime(t, '%Y%m%d')
    elseif idt == 2 then
        return 'week.' .. zce.time_strftime(zce.time_weekstart(t), '%Y%m%d')
    elseif idt == 3 then
        return 'month.' .. zce.time_strftime(t, '%Y%m')
    elseif idt == 4 then
        return 'year.' .. zce.time_strftime(t, '%Y')
    end
end

function _M.getPKCSKey(str)
    local vec = zce.split(str, '\r\n')
    local ispubkey = false
    if vec[1] == '-----BEGIN PUBLIC KEY-----' then
        ispubkey = true
    elseif vec[1] == '-----BEGIN RSA PRIVATE KEY-----' then
        ispubkey = false
    else
        return nil
    end
    return ispubkey, table.concat(vec, 1, 2, #vec - 1 )
end