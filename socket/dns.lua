---@diagnostic disable: assign-type-mismatch

local ffi = require("ffi")
local lib = require("socket.ffi")

---@param address addrinfo
---@return string?
local function convert_to_string(address)
    local addr = nil

    if address.ai_family == lib.D.AF_INET then
        local sockaddr = ffi.cast("struct sockaddr_in *", address.ai_addr) ---@type sockaddr_in
        addr = sockaddr.sin_addr
    end

    if address.ai_family == lib.D.AF_INET6 then
        local sockaddr = ffi.cast("struct sockaddr_in6 *", address.ai_addr) ---@type sockaddr_in6
        addr = sockaddr.sin6_addr
    end

    if not addr then
        return nil
    end

    local addrstr_length = 128
    local addrstr = ffi.new("char[?]", addrstr_length)

    return ffi.string(lib.C.inet_ntop(address.ai_family, addr, addrstr, addrstr_length))
end

---@class DNS
local DNS = {}

---@param hostname string
---@param ipv6 boolean?
---@return string?, "not found"?
function DNS.resolve(hostname, ipv6)
    local hints = ffi.new("struct addrinfo") ---@type addrinfo
    hints.ai_family = ipv6 and lib.D.AF_INET6 or lib.D.AF_INET
    hints.ai_socktype = lib.D.SOCK_STREAM
    hints.ai_flags = lib.D.AI_CANONNAME

    local result = ffi.new("struct addrinfo *[1]")
    local err = lib.C.getaddrinfo(hostname, nil, hints, result)

    if err < 0 then
        return nil, "not found"
    end

    local ip = nil
    local addrinfo = ffi.new("struct addrinfo *", result[0]) ---@type addrinfo

    while addrinfo ~= nil and ip == nil do
        ip = convert_to_string(addrinfo)
        addrinfo = addrinfo[0].ai_next
    end

    lib.C.freeaddrinfo(result[0])

    if not ip then
        return nil, "not found"
    end

    return ip, nil
end

return DNS
