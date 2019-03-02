local zce = require("zce.core")

-- https://github.com/zwh8800/lua-libuv/blob/master/test/socksProxy.lua

SocksVersion = 0x05

Errors = {
    VersionError = 'version error',
    CommandTypeNotSupported = 'command type not supported',
    AddressTypeNotSupported = 'address type not supported',
}

MethodType = {
    NoAuth = 0x00,
    GSSAPI = 0x01,
    UsernamePassword = 0x02,
    IANAssigned = 0x03,
    Private = 0x80,
    NoAcceptable = 0xff,
}

function parseMethodPayload(payload)
    if payload:byte(1) ~= SocksVersion then
        return nil, Errors.VersionError
    end

    local method = {
        version = SocksVersion,
        methods = {},
    }

    local methodCount = payload:byte(2)
    method.methods = {payload:byte(3, 3 + methodCount - 1)}
    return method
end

function selectMethodToString(selectMethodPayload)
    return string.char(selectMethodPayload.version, selectMethodPayload.selectedMethod)
end

function newSelectMethodPayload()
    return {
        version = SocksVersion,
        selectedMethod = MethodType.NoAuth,
        toString = selectMethodToString,
    }
end

CommandType = {
    Connect = 0x01,
    Bind = 0x02,
    Udp = 0x03,
}

AddressType = {
    IPv4 = 0x01,
    DomainName = 0x03,
    IPv6 = 0x04,
}

function parseRequestPayload(payload)
    if payload:byte(1) ~= SocksVersion then
        return nil, Errors.VersionError
    end

    local request = {
        version = SocksVersion,
        command = CommandType.Connect,
        addressType = AddressType.IPv4,
        distAddress = '',
        distPort = 0,
    }

    if payload:byte(2) > CommandType.Udp then
        return nil, Errors.CommandTypeNotSupported
    else
        request.command = payload:byte(2)
    end

    local requestAddressType = payload:byte(4)
    if  requestAddressType ~= AddressType.IPv4 and
        requestAddressType ~= AddressType.DomainName and
        requestAddressType ~= AddressType.IPv6
    then
        return nil, Errors.AddressTypeNotSupported
    else
        request.addressType = requestAddressType
    end

    local portIndex
    if request.addressType == AddressType.IPv4 then
        local ipBytes = {payload:byte(5, 8)}
        request.distAddress = table.concat(ipBytes, '.')
        portIndex = 9
    elseif request.addressType == AddressType.DomainName then
        local len = payload:byte(5)
        request.distAddress = payload:sub(6, 6 + len - 1)
        portIndex = 5 + len + 1
    elseif request.addressType == AddressType.IPv6 then
        return nil, Errors.AddressTypeNotSupported
    end

    local portBytes = {payload:byte(portIndex, portIndex + 1) }
    request.distPort = portBytes[1] * 256 + portBytes[2]

    return request, nil
end

ReplyType = {
    Success = 0x00,
    GeneralSocksServerFailure = 0x01,
    ConnectionNotAllowed = 0x02,
    NetworkUnreachable = 0x03,
    HostUnreachable = 0x04,
    ConnectionRefused = 0x05,
    TTLExpire = 0x06,
    CommandNotSupported = 0x07,
    AddressTypeNotSupported = 0x08,
}

function replyToString(replyPayload)
    return string.char(
        replyPayload.version,
        replyPayload.reply,
        replyPayload.reserved,
        replyPayload.addressType
    ) ..
        string.char(0) ..
        string.char(0) ..
        string.char(0) ..
        string.char(0) ..
        string.char(0) ..
        string.char(0)
--        replyPayload.bindAddress ..
--        string.char(math.floor(replyPayload.bindPort / 256)) ..
--        string.char(math.floor(replyPayload.bindPort % 256))
end

function newReplyPayload()
    return {
        version = SocksVersion,
        reply = ReplyType.Success,
        reserved = 0x00,
        addressType = AddressType.DomainName,
        bindAddress = '',
        bindPort = 0,

        toString = replyToString,
    }
end


ClientState = {
    Start = 0,
    MethodSelected = 1,
    RequestHandled = 2,
}

