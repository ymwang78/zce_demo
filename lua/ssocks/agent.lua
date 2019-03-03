local zce = require("zce.core")
local socks5 = require("ssocks.socks5")
local _blackip_list = {}

--local _UP_ADDR = "127.0.0.1"
local _UP_ADDR = "47.90.37.163"
local _UP_PORT = 21443

function onSocksDownTcpEvent(con, event, data)
    if event == "CONN" then
        if _blackip_list[con.peerip] then
            zce.log(1, "|", con.peerip, "black")
            con.droped = true
            zce.tcp_close(con)
            return
        end
        con.upconn = { downcon = con, stat = 0, tosend = {} }
        local ok = zce.tcp_connect({
                { proto = "tcp", host = _UP_ADDR,  port = _UP_PORT},
                -- { proto = "ssl" }, -- 不验证
                -- { proto = "ssl", verifyca = "ca.pem" }, -- 单项验证
                { proto = "ssl", verifyca = "ca.pem", cert="client.pem", key="client.key" }, -- 双向验证提供证书
            }, 
            con.upconn,
            onUpTcpEvent) 

    elseif event == "READ" then
        if (con.droped) then
            return
        end
        -- zce.log(1, "|", "read", #data)
        if con.upconn.stat == 0 then
            con.upconn.tosend[#con.upconn.tosend + 1] = data
            return
        end
        zce.tcp_send(con.upconn, data)
    elseif event == "DISC" then
        zce.tcp_close(con)
        if con.upconn ~= nil then
            zce.tcp_close(con.upconn)
            con.upconn = nil
        end
    end
end

function onUpTcpEvent(con, event, data)
    if event == "CONN" then
        con.stat = 1
        zce.log(1, "|", "upcon", "OPENED")
        if con.tosend ~= nil then 
            for i, v in ipairs(con.tosend) do
                zce.log(1, "|", 'sendcache', #v)
                zce.tcp_send(con, v)
            end
            con.tosend = nil
        end
    elseif event == "READ" then
        if con.downcon == nil then
            zce.tcp_close(con)
            return
        end
        if con.downcon ~= nil then
            local ok = zce.tcp_send(con.downcon, data)
            --zce.log(1, "|", "tcp_recv<-remote", con.fd, ok, #data)
        end
    elseif event == "DISC" then
        zce.tcp_close(con)
        if con.downcon ~= nil then
            zce.tcp_close(con.downcon)
            con.downcon = nil
        end
    end
end


local function main()
    zce.log(1, "\t", "...........start...........")

    zce.tcp_listen({
        { proto = "tcp", host = "127.0.0.1",  port = 2080},
    }, onSocksDownTcpEvent)

end

main()