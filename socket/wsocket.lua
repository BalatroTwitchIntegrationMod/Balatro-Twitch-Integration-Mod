---@diagnostic disable: assign-type-mismatch, cast-type-mismatch

local ffi = require("ffi")
local bit = require("bit")
local lib = require("socket.ffi")
local dns = require("socket.dns")

---@class WinSecureSocket: SecureSocket
local SecureSocket = {}

SecureSocket.__index = SecureSocket

local WSA = nil

---@param major integer
---@param minor integer
---@return integer
local function wsa_version(major, minor)
    return bit.bor(major, bit.lshift(minor, 8))
end

---@return boolean
local function wsa_init()
    if WSA == nil then
        WSA = ffi.gc(lib.C.malloc(408), lib.C.free)

        if lib.S.WSAStartup(wsa_version(2, 2), WSA) ~= 0 then
            WSA = nil
            return true
        end
    end

    return false
end

function SecureSocket:open(host, port)
    local s = setmetatable({}, self)

    if wsa_init() then
        return nil, "wsastartup"
    end

    local ip, ip_err = dns.resolve(host, false)
    if ip_err then
        return nil, "dns_resolve"
    end

    local address = ffi.new("struct sockaddr_in") ---@type sockaddr_in
    address.sin_family = lib.D.AF_INET
    address.sin_port = lib.S.htons(port)
    if lib.S.inet_pton(lib.D.AF_INET, ip, address.sin_addr) <= 0 then
        return nil, "inet_pton"
    end

    local socket = lib.S.socket(lib.D.AF_INET, lib.D.SOCK_STREAM, 0)
    if socket == lib.D.INVALID_SOCKET then
        return nil, "socket"
    end

    s.socket = socket

    if lib.S.ioctlsocket(s.socket, lib.D.FIONBIO, ffi.new("unsigned int[1]", { true })) ~= 0 then
        s:close()
        return nil, "ioctlsocket"
    end

    return nil, "not_implemented"
end

function SecureSocket:connect()
    return false, "not_implemented"
end

function SecureSocket:close()
    return "not_implemented"
end

function SecureSocket:send(data)
    return nil, "not_implemented"
end

function SecureSocket:receive()
    return nil, "not_implemented"
end

return SecureSocket
