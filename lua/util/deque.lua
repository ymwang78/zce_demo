deque = {}

function deque.new ()
    return {frontpos = 0, backpos = 0}
end

function deque.is_empty (d)
    return d.frontpos == d.backpos
end

function deque.push_back (d, value)
    d[d.backpos] = value
    d.backpos = d.backpos + 1  
end

function deque.push_front (d, value)
    d.frontpos = d.frontpos - 1
    d[d.frontpos] = value
end

function deque.pop_back (d)
    if (deque.is_empty(d)) then
        error("deque is empty")
    end
    local value = d[d.backpos - 1]
    d[d.backpos - 1] = nil
    d.backpos = d.backpos - 1
    if (deque.is_empty(d)) then
        d.frontpos = 0
        d.backpos = 0
    end
    return value
end

function deque.pop_front (d)
    if (deque.is_empty(d)) then
        error("deque is empty")
    end
    local value = d[d.frontpos]
    d[d.frontpos] = nil
    d.frontpos = d.frontpos + 1
    if (deque.is_empty(d)) then
        d.frontpos = 0
        d.backpos = 0
    end
    return value
end

function deque.iter (d, func)
    if (deque.is_empty(d)) then
        return
    end
    for i = d.frontpos, d.backpos - 1 do
        -- print (i, d.frontpos, d.backpos)
        func(d[i])
    end
end

function deque.clear (d)
    deque.iter(d, function(item)
        item = nil
    end)
    d.frontpos = 0
    d.backpos = 0
end

return deque