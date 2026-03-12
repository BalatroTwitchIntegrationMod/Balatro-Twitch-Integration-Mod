---@diagnostic disable: assign-type-mismatch, cast-type-mismatch

local ffi = require("ffi")
local bit = require("bit")
local lib = require("socket.ffi")
local dns = require("socket.dns")

---@class SecureSocket
---@field private socket? integer
---@field private ctx? ffi.cdata*
---@field private ssl? ffi.cdata*
local SecureSocket = {}

SecureSocket.__index = SecureSocket

---@return SecureSocket?, string?
function SecureSocket:open(host, port)
    if not lib.SSL then
        return nil, "libssl"
    end

    local s = setmetatable({}, self)

    local ip, ip_err = dns.resolve(host, false)
    if ip_err then
        return nil, "dns_resolve"
    end

    local address = ffi.new("struct sockaddr_in") ---@type sockaddr_in
    address.sin_family = lib.D.AF_INET
    address.sin_port = lib.C.htons(port)
    if lib.C.inet_pton(lib.D.AF_INET, ip, address.sin_addr) <= 0 then
        return nil, "inet_pton"
    end

    local socket = lib.C.socket(lib.D.AF_INET, lib.D.SOCK_STREAM, 0)
    if socket < 0 then
        return nil, "socket"
    end

    s.socket = socket

    if not lib.SSL.BIO_socket_nbio(s.socket, true) then
        s:close()
        return nil, "bio_socket_nbio"
    end

    ---@cast address ffi.cdata*
    local connect_err = lib.C.connect(s.socket, ffi.cast("struct sockaddr *", address), ffi.sizeof(address))
    if connect_err < 0 and ffi.errno() ~= lib.D.EINPROGRESS then
        s:close()
        return nil, "connect"
    end

    local ctx = lib.SSL.SSL_CTX_new(lib.SSL.TLS_method())
    if ctx == nil then
        s:close()
        return nil, "ssl_ctx_new"
    end
    s.ctx = ffi.gc(ctx, lib.SSL.SSL_CTX_free)

    lib.SSL.SSL_CTX_set_verify(s.ctx, lib.D.SSL_VERIFY_PEER, nil)

    if not lib.SSL.SSL_CTX_set_default_verify_paths(s.ctx) then
        return nil, "ssl_ctx_set_default_verify_paths"
    end

    if not lib.SSL.SSL_CTX_ctrl(s.ctx, lib.D.SSL_CTRL_SET_MIN_PROTO_VERSION, lib.D.TLS1_2_VERSION, nil) then
        s:close()
        return nil, "ssl_set_min_proto_version"
    end

    local ssl = lib.SSL.SSL_new(s.ctx)
    if ssl == nil then
        s:close()
        return nil, "ssl_new"
    end
    s.ssl = ffi.gc(ssl, lib.SSL.SSL_free)

    if not lib.SSL.SSL_set_fd(s.ssl, s.socket) then
        s:close()
        return nil, "ssl_set_fd"
    end

    if not lib.SSL.SSL_ctrl(s.ssl, lib.D.SSL_CTRL_SET_TLSEXT_HOSTNAME, lib.D.TLSEXT_NAMETYPE_host_name, ffi.cast("void *", host)) then
        s:close()
        return nil, "ssl_set_tlsext_host_name"
    end

    return s, nil
end

---@return boolean, string?
function SecureSocket:connect()
    if self.socket == nil then
        return false, "closed"
    end

    local err = lib.SSL.SSL_get_error(self.ssl, lib.SSL.SSL_connect(self.ssl))

    if err == lib.D.SSL_ERROR_NONE then
        return true, nil
    elseif err == lib.D.SSL_ERROR_WANT_READ or err == lib.D.SSL_ERROR_WANT_WRITE then
        return false, nil
    end

    return false, "ssl_connect"
end

---@return string?
function SecureSocket:close()
    if self.socket == nil then
        return "closed"
    end

    local err = nil

    if self.ssl ~= nil then
        local ssl_err = lib.SSL.SSL_shutdown(self.ssl)
        if ssl_err == 0 then
            self:receive()
        elseif ssl_err < 0 then
            err = "ssl_shutdown"
        end
        self.ssl = nil
    end

    self.ctx = nil

    if self.socket ~= nil then
        if lib.C.close(self.socket) < 0 then
            err = "close"
        end
        self.socket = nil
    end

    return err
end

---@param data string
---@return integer?, string?
function SecureSocket:send(data)
    if self.socket == nil then
        return nil, "closed"
    end

    local sent = lib.SSL.SSL_write(self.ssl, data, #data)
    local err = lib.SSL.SSL_get_error(self.ssl, sent)

    if err == lib.D.SSL_ERROR_NONE then
        return sent, nil
    elseif err == lib.D.SSL_ERROR_WANT_READ or err == lib.D.SSL_ERROR_WANT_WRITE then
        return sent, "timeout"
    end

    return nil, "write"
end

---@return string?, string?
function SecureSocket:receive()
    if self.socket == nil then
        return nil, "closed"
    end

    local buffer_length = 1024
    local buffer = ffi.new("char[?]", buffer_length)

    local received = lib.SSL.SSL_read(self.ssl, buffer, buffer_length)
    local err = lib.SSL.SSL_get_error(self.ssl, received)

    if err == lib.D.SSL_ERROR_NONE then
        return ffi.string(buffer, received), nil
    elseif err == lib.D.SSL_ERROR_WANT_READ then
        return nil, "timeout"
    end

    return nil, "read"
end

return SecureSocket
