local deque = require "deque"
-- defines a factorial function

test_deque = deque.new()

function fact (n)
    deque.push_back(test_deque, n)
    if n == 0 then    
        return 1
    else
        local v = n * fact(n-1)
        return v
    end
end

fact(3)

deque.iter(test_deque, print)

deque.clear(test_deque)
