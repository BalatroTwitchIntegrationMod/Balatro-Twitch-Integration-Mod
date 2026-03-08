local ffi = require("ffi")
local socket = require("socket")

local _, C = pcall(ffi.load, ({
    Linux = "ssl3",
    OSX = "libssl.58.dylib",
})[ffi.os] or "ssl")

ffi.cdef [[
    typedef struct ssl_method_st SSL_METHOD;

    SSL_METHOD *TLS_client_method(void);

    typedef struct ssl_ctx_st SSL_CTX;

    SSL_CTX *SSL_CTX_new(SSL_METHOD *meth);
    void SSL_CTX_free(SSL_CTX *ctx);
    typedef int (*SSL_verify_cb)(int preverify_ok, void *x509_ctx);
    void SSL_CTX_set_verify(SSL_CTX *ctx, int mode, SSL_verify_cb callback);
    int SSL_CTX_set_default_verify_paths(SSL_CTX *ctx);
    long SSL_CTX_ctrl(SSL_CTX *ctx, int cmd, long larg, void *parg);

    typedef struct ssl_st SSL;

    SSL *SSL_new(SSL_CTX *ctx);
    void SSL_free(SSL *ssl);
    int SSL_get_error(const SSL *ssl, int i);
    int SSL_set_fd(SSL *ssl, int fd);
    int SSL_connect(SSL *ssl);
    int SSL_write(SSL *ssl, const void *buf, int num);
    int SSL_read(SSL *ssl, void *buf, int num);
    int SSL_shutdown(SSL *ssl);
]]

local SSL_CTRL = {
    SET_MIN_PROTO_VERSION = 123
}

local CRYPTO_VERSION = {
    TLS1_2 = 0x0303
}

local function ssl_context_new()
    local context = ffi.gc(C.SSL_CTX_new(C.TLS_client_method()), C.SSL_CTX_free)

    if not context then
        return nil, "ssl_context_new"
    end

    C.SSL_CTX_set_verify(context, 1, nil)

    if not C.SSL_CTX_set_default_verify_paths(context) then
        return nil, "ssl_default_verify_paths"
    end

    if not C.SSL_CTX_ctrl(context, SSL_CTRL.SET_MIN_PROTO_VERSION, CRYPTO_VERSION.TLS1_2, nil) then
        return nil, "ssl_min_proto_version"
    end

    return context, nil
end

---@class SecureTCPSocketClient
---@field client TCPSocketClient
---@field handshake boolean
---@field ssl? ffi.cdata*
---@field buffer string
SecureTCPSocketClient = {}

---@private
SecureTCPSocketClient.__index = SecureTCPSocketClient

---@param client TCPSocketClient
---@returns SecureTCPSocketClient?
function SecureTCPSocketClient:wrap(client)
    local context, err = ssl_context_new()

    if err then
        return nil, err
    end

    local ssl = ffi.gc(C.SSL_new(context), C.SSL_free)

    if not ssl then
        return nil, "ssl_new"
    end

    if C.SSL_set_fd(ssl, client:getfd()) ~= 1 then
        return nil, "ssl_set_fd"
    end

    client:setfd(socket._SOCKETINVALID)

    return setmetatable({
        client = client,
        handshake = false,
        ssl = ssl,
        buffer = ""
    }, self)
end

function SecureTCPSocketClient:connect()
    if not self.ssl then
        return nil, "ssl_shutdown"
    end

    if not self.handshake then
        local err = C.SSL_get_error(self.ssl, C.SSL_connect(self.ssl))

        if err == 0 then
            self.handshake = true
        elseif err == 2 or err == 3 then
            -- do nothing
        else
            return false, "ssl_connect"
        end
    end

    return self.handshake, nil
end

---@param data string
---@return number?, string?
function SecureTCPSocketClient:send(data)
    if not self.ssl then
        return nil, "ssl_shutdown"
    end

    local sent = C.SSL_write(self.ssl, data, #data)
    local err = C.SSL_get_error(self.ssl, sent)

    if err == 0 then
        return sent, nil
    end

    return nil, "ssl_write"
end

---@return string?, string?
function SecureTCPSocketClient:receive()
    if not self.ssl then
        return nil, "ssl_shutdown"
    end

    local buffer_size = 1024
    local buffer = ffi.new("uint8_t[?]", buffer_size)
    local received = C.SSL_read(self.ssl, buffer, buffer_size)
    local err = C.SSL_get_error(self.ssl, received)

    if err == 0 then
        self.buffer = self.buffer .. ffi.string(buffer, received)
    elseif err == 2 then
        -- do nothing
    else
        return nil, "ssl_read"
    end

    if #self.buffer > 0 then
        local line, line_end = string.match(self.buffer, "(.-)\n()")
        if line then
            self.buffer = string.sub(self.buffer, line_end)
            if string.sub(line, #line) == "\r" then
                line = string.sub(line, 1, #line - 1)
            end
            return line, nil
        end
    end

    return nil, "timeout"
end

function SecureTCPSocketClient:close()
    if self.ssl then
        C.SSL_shutdown(self.ssl)
        self.ssl = nil
    end
end

return SecureTCPSocketClient
