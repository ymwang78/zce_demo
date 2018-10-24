

-- this is not a valid lua file

local function incall(abcd)
    local b = abcd .. notexistavar
end

local function test_callstack()
    incall("abce")
end

test_callstack()