local zce = require("zce.core")
local socks5 = require("ssocks.socks5")
local _blackip_list = {}

function onSocksDownTcpEvent(con, event, data)
    if event == "CONN" then
        if _blackip_list[con.peerip] then
            zce.log(1, "|", con.peerip, "black")
            con.droped = true
            zce.tcp_close(con)
            return
        end
        con.state = ClientState.Start
        con.upconn = { downcon = con, tosend = {}}
    elseif event == "READ" then
        if (con.droped) then
            return
        end
        onProcSocksData(con, data)
    elseif event == "DISC" then
        zce.tcp_close(con)
        if con.upconn ~= nil then
            zce.tcp_close(con.upconn)
            con.upconn = nil
        end
    end
end

function onProcSocksData(con, data)
    if con.state == ClientState.Start then
        zce.log(1, "|", 'methodreq', con.fd, data:byte(1, -1))

        local clientMethods, err = parseMethodPayload(data)
        if err ~= nil then
            zce.log(1, "|", 'error', err)
            zce.tcp_close(con)
            return
        end

        local methodOk = false
        for _, v in pairs(clientMethods.methods) do
            if v == MethodType.NoAuth then
                methodOk = true
                break
            end
        end
        local selectMethod = newSelectMethodPayload()

        if methodOk then
            zce.log(1, "|", 'methodreqres', con.fd, selectMethod:toString():byte(1, -1))
            local ok = zce.tcp_send(con, selectMethod:toString())
            con.state = ClientState.MethodSelected
        else
            selectMethod.selectedMethod = MethodType.NoAcceptable
            zce.log(1, "|", 'methodreqres', con.fd, selectMethod:toString():byte(1, -1))
            local ok = zce.tcp_send(con, selectMethod:toString())
            zce.tcp_close(con)
            return
        end
    elseif con.state == ClientState.MethodSelected then
        zce.log(1, "|", 'connreq', con.fd, data:byte(1, -1))
        local reply = newReplyPayload()

        local request, err = parseRequestPayload(data)
        if err ~= nil then
            zce.log(1, "|", 'error', err)
            if err == Errors.CommandTypeNotSupported then
                reply.reply = ReplyType.CommandNotSupported

                zce.log(1, "|", 'connres ', con.fd, reply:toString():byte(1, -1))
                local ok = zce.tcp_send(con, reply:toString())
            elseif err == Errors.AddressTypeNotSupported then
                reply.reply = ReplyType.AddressTypeNotSupported

                zce.log(1, "|", 'connres', con.fd, reply:toString():byte(1, -1))
                local ok = zce.tcp_send(con, reply:toString())
            end
            zce.tcp_close(con)
            return
        end

        if request.command ~= CommandType.Connect then
            reply.reply = ReplyType.CommandTypeNotSupported
            zce.log(1, "|", 'connres', con.fd, reply:toString():byte(1, -1))
            local ok = zce.tcp_send(con, reply:toString())
            zce.tcp_close(con)
            return
        end

        if request.addressType == AddressType.IPv4 then
        elseif request.addressType == AddressType.DomainName then
            local ok, redisip = zce.dns_resolve(request.distAddress)
            request.distAddress = redisip
        end
        zce.log(1, "|", 'connremotestart', request.distAddress, request.distPort)
        local ok = zce.tcp_connect("tcp://" .. request.distAddress .. ":" .. request.distPort .. "/", con.upconn, onUpTcpEvent) 
    elseif con.state == ClientState.RequestHandled then
        local ok = zce.tcp_send(con.upconn, data)
        zce.log(1, "|", "tcp_send->remote", con.fd, ok, #data)
    end
end

function onUpTcpEvent(con, event, data)
    if event == "CONN" then
        local ok, localip, localport = zce.tcp_localaddr(con)

        local reply = newReplyPayload()
        reply.addressType = AddressType.IPv4
        reply.bindAddress = localip
        reply.bindPort = localport
        zce.log(1, "|", "connremoteend", con.fd, ok, localip, localport, reply:toString():byte(1, -1))

        zce.tcp_send(con.downcon, reply:toString())
        con.downcon.state = ClientState.RequestHandled

        for i, v in ipairs(con.tosend) do
            zce.tcp_send(con, con.tosend[i])
        end
        con.tosend = nil
    elseif event == "READ" then
        if con.downcon == nil then
            zce.tcp_close(con)
            return
        end
        if con.downcon ~= nil then
            local ok = zce.tcp_send(con.downcon, data)
            zce.log(1, "|", "tcp_recv<-remote", con.fd, ok, #data)
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
    -- local ok1, obj1 = zce.tcp_listen("wssbin", "0.0.0.0", 21978, onSocksDownTcpEvent)
    local ok1, obj1 = zce.tcp_listen("raw", "0.0.0.0", 21978, onSocksDownTcpEvent)
end

main()