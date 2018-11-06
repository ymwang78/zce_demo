--functions

--系统random
-- math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))

-- lrandom = require("lrandom").new()
--lrandom()         返回[0,1)的小数
--lrandom(a, b)     返回[a,b]
--lrandom:sead()    重置种子
local zce = require "zce.core"
function LOG_DEBUG(...)
    zce.log(LOG_LV_DEBUG, " ", ...)
end
function LOG_TRACE(...)
    zce.log(LOG_LV_TRACE, " ", ...)
end
function tableToJson(table)
    return zce.tojson(table, true)
end

local function getTraceback()
    local traceback = string.split(debug.traceback("", 3), "\n")
    local str = ""
    for k, v in pairs(traceback) do
        str = str .. v .. "\n"
    end
    return str
end

local function packArg( ... )
    local str = ""
    for _, v in pairs({...}) do
        v = v or "nil"
        str = str .. " " .. tostring(v)
    end
    return str
end
--带traceback信息的print
function trace(...)
    -- body
    local str = packArg(...) .. "\n" .. getTraceback()
    print(str)
end

local function dump_value_(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

function luadump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end
    
    local lookupTable = {}
    local result = {}
    
    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))
    
    local function dump_(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_(desciption)))
        end
        if type(value) ~= "table" then
            result[#result + 1 ] = string.format("%s%s%s = %s", indent, dump_value_(desciption), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result + 1 ] = string.format("%s%s%s = *REF*", indent, dump_value_(desciption), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result + 1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_value_(desciption))
            else
                result[#result + 1 ] = string.format("%s%s = {", indent, dump_value_(desciption))
                local indent2 = indent .. "    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                        if type(a) == "number" and type(b) == "number" then
                            return a < b
                        else
                            return tostring(a) < tostring(b)
                        end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result + 1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, desciption, "- ", 1)
    
    for i, line in ipairs(result) do
        LOG_DEBUG(line)
    end
end

function printf(fmt, ...)
    print(string.format(tostring(fmt), ...))
end

function checknumber(value, base)
    return tonumber(value, base) or 0
end

function checkint(value)
    return math.round(checknumber(value))
end

function checkbool(value)
    return (value ~= nil and value ~= false)
end

function checktable(value)
    if type(value) ~= "table" then value = {} end
    return value
end

function check2powers(num)
    if((num > 0)and ((num &(num - 1)) == 0)) then
        return true
    end
    return false
end

function isset(hashtable, key)
    local t = type(hashtable)
    return (t == "table" or t == "userdata") and hashtable[key] ~= nil
end


function math.round(value)
    value = checknumber(value)
    return math.floor(value + 0.5)
end


function table.len(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function table.keys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end

function table.values(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

function table.mergeByAppend(dest, src)
    for k, v in pairs(src) do
        table.insert(dest, v)
    end
end

function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then return i end
    end
    return false
end

function table.keyof(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then return k end
    end
    return nil
end

function table.removebyvalue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end
--数组浅层拷贝,从index开始，拷贝len个长度，返回一个新的table，如果长度不够，则填充nil
function table.arraycopy(array, index, len)
    local newtable = {}
    len = len or 0
    index = index or 1
    if len == 0 then
        len = #array - index + 1
    end
    for i = index, index + len - 1 do
        newtable[i - index + 1] = array[i]
    end
    return newtable;
end

function table.deepcopy(st)  
    local tab = {}
    for k, v in pairs(st or {}) do  
        if type(v) ~= "table" then  
            tab[k] = v  
        else  
            tab[k] = table.deepcopy(v)  
        end  
    end  
    return tab
end

--将tarray的元素添加到array的末尾
function table.join(array, tarray)
    -- body
    for _, v in pairs(tarray) do
        table.insert(array, v)
    end
end

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == '') then return false end
    local pos, arr = 0, {}
    -- for each divider found
        for st, sp in function() return string.find(input, delimiter, pos, true) end 
        do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function string.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

function string.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end
function string.urlencode(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%- ])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end

function string.urldecode(input)
    input = string.gsub (input, "+", " ")
    input = string.gsub (input, "%%(%x%x)", function(h) return string.char(checknumber(h, 16)) end)
    input = string.gsub (input, "\r\n", "\n")
    return input
end

function string.utf8len(input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, - left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function table.pack_msg( obj )
    if obj == nil then
        return ""
    end
    
    local result = ""
    local t = type(obj)
    
    if t == "number" then
        result = result .. obj
    elseif t == "boolean" then
        result = result .. tostring(obj)
    elseif t == "string" then
        result = result .. string.format("%q", obj)
    elseif t == "table" then
        result = result .. "{"
        local tbLen = 0
        for k, v in pairs(obj) do
            result = result .. '["'..k..'"]=' .. table.pack_msg(v) .. ","
            tbLen = tbLen + 1
        end
        local metatable = getmetatable(obj)  
        if metatable ~= nil and type(metatable.__index) == "table" then  
            for k, v in pairs(metatable.__index) do  
                result = result .. "[" .. table.pack_msg(k) .. "]=" .. table.pack_msg(v) .. ","  
            end  
        end
        if tbLen > 0 then
            if "," == string.sub(result, - 1, - 1) then
                --返回删除最后一个字符(也就是逗号)后的字符串
                result = string.sub(result, 1, - 2)
            end
        end
        result = result .. "}"
    else
        --print("can not pack_msg a " ..t.. " type.")
    end
    return result
end

function table.unpack_msg( _str )
    local t = type(_str)  
    if t == "nil" or _str == "" then  
        return nil  
    elseif t == "number" or t == "string" or t == "boolean" then  
        _str = tostring(_str)  
    else  
        --print("can not unpack a " .. t .. " type.")  
    end  
    _str = "return " .. _str  
    local func = load(_str)  
    if func == nil then  
        return nil  
    end  
    return func() 
end


local _class = {}
function class(super)
    local class_type = {}
    class_type.ctor     = false
    class_type.super    = super
    class_type.new      =  
    function(...)
        local obj = {}
        do
        local create
        create = 
        function(c, ...)
            if zce.super then
                create(c.super, ...)
            end
            if zce.ctor then
                zce.ctor(obj, ...)
            end
        end
        
        create(class_type, ...)
    end
    setmetatable(obj, { __index = _class[class_type] })
    return obj
end
local vtbl = {}
_class[class_type] = vtbl

setmetatable(class_type, {__newindex = 
    function(t, k, v)
        vtbl[k] = v
    end
})

if super then
    setmetatable(vtbl, {__index = 
        function(t, k)
            local ret = _class[super][k]
            vtbl[k] = ret
            return ret
        end
    })
end

return class_type
end

function gen_store_sql(tbl_name, mainkeys, data)
local sql = 'INSERT INTO ' .. tbl_name .. ' ( '

--key
local i = 1
for k, v in pairs(data) do
    if i == 1 then
        sql = sql .. k
    else
        sql = sql .. ', ' .. k
    end
    i = i + 1
end
sql = sql .. ' ) VALUES ( '

--values
i = 1
for k, v in pairs(data) do
    local rel_val
    if type(v) == 'string' then
        rel_val = "\'" .. v .. "\'"
    else
        rel_val = v
    end
    
    if i == 1 then
        sql = sql .. rel_val
    else
        sql = sql .. ', ' .. rel_val
    end
    i = i + 1
end
sql = sql .. ' ) ON CONFLICT ('
--main key
i = 1
for k, v in pairs(mainkeys) do
    local rel_val
    rel_val = k
    -- if type(v) == 'string' then
    --     rel_val = "\'" .. v .. "\'"
    -- else
    --     rel_val = v
    -- end
    
    if i == 1 then
        sql = sql .. rel_val
    else
        sql = sql .. ', ' .. rel_val
    end
    i = i + 1
end
sql = sql .. ') DO UPDATE SET '
-- INSERT INTO tb_player_friend(player_id,friend_id,type) VALUES(?,?,?) ON CONFLICT (player_id,friend_id) DO UPDATE SET type = ?;
--dumplicate
i = 1
for k, v in pairs(data) do
    if(not mainkeys[key]) then
        local rel_val
        if type(v) == 'string' then
            rel_val = "\'" .. v .. "\'"
        else
            rel_val = v
        end
        
        if i == 1 then
            sql = sql .. k .. '=' .. rel_val
        else
            sql = sql .. ', ' .. k .. '=' .. rel_val
        end
        i = i + 1
    end
    
end

sql = sql .. ';'

return sql
end