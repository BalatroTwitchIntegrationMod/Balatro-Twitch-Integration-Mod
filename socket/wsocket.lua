local ffi = require("ffi")
local bit = require("bit")
local lib = require("socket.ffi")
local dns = require("socket.dns")

---@class WinSecureSocket: SecureSocket
---@field private handle ffi.cdata*
---@field private host string
---@field private rx {length: integer, available: integer, buffer: ffi.cdata*}
---@field private tx {length: integer, buffer: ffi.cdata*}
---@field private sizes {header: integer, trailer: integer, message: integer, buffers: integer}
local SecureSocket = {}

SecureSocket.__index = SecureSocket

local isc_flags = bit.bor(
    lib.D.ISC_REQ_ALLOCATE_MEMORY,
    lib.D.ISC_REQ_CONFIDENTIALITY,
    lib.D.ISC_REQ_REPLAY_DETECT,
    lib.D.ISC_REQ_SEQUENCE_DETECT,
    lib.D.ISC_REQ_STREAM,
    lib.D.ISC_REQ_USE_SUPPLIED_CREDS
)

---@param major integer
---@param minor integer
---@return integer
local function wsa_version(major, minor)
    return bit.bor(major, bit.lshift(minor, 8))
end

---@return boolean
local function wsa_init()
    local sizeof_wsa = 408
    local wsa = ffi.gc(lib.C.malloc(sizeof_wsa), lib.C.free)

    if lib.S.WSAStartup(wsa_version(2, 2), wsa) ~= 0 then
        return true
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

    local address = ffi.new("struct sockaddr_in", {
        sin_family = lib.D.AF_INET,
        sin_port = lib.S.htons(port)
    })
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

    local connect_err = lib.S.connect(s.socket, ffi.cast("struct sockaddr *", address), ffi.sizeof(address))
    if connect_err < 0 and lib.S.WSAGetLastError() ~= lib.D.WSAEWOULDBLOCK then
        s:close()
        return nil, "connect"
    end

    local cred = ffi.new("SCHANNEL_CRED", {
        dwVersion = lib.D.SCHANNEL_CRED_VERSION,
        dwFlags = bit.bor(
            lib.D.SCH_CRED_AUTO_CRED_VALIDATION,
            lib.D.SCH_CRED_NO_DEFAULT_CREDS,
            lib.D.SCH_USE_STRONG_CRYPTO
        ),
    })
    s.handle = ffi.gc(lib.C.malloc(ffi.sizeof("CredHandle")), lib.C.free)
    if ffi.cast("uint32_t", lib.SSL.AcquireCredentialsHandleA(
            nil,
            ffi.cast("char *", lib.D.UNISP_NAME_A),
            lib.D.SECPKG_CRED_OUTBOUND,
            nil,
            cred,
            nil,
            nil,
            s.handle,
            nil
        )) ~= lib.D.SEC_E_OK then
        s:close()
        return nil, "acquirecredentialshandlea"
    end

    s.host = host

    local buffer_length = 32 * 1024

    s.rx = {}
    s.rx.length = buffer_length
    s.rx.available = 0
    s.rx.buffer = ffi.gc(ffi.cast("uint8_t *", lib.C.malloc(buffer_length)), lib.C.free)

    s.tx = {}
    s.tx.length = buffer_length
    s.tx.buffer = ffi.gc(ffi.cast("uint8_t *", lib.C.malloc(buffer_length)), lib.C.free)

    if s.rx.buffer == nil or s.tx.buffer == nil then
        s:close()
        return nil, "malloc"
    end

    s.sizes = {
        header = 0,
        trailer = 0,
        message = 0,
        buffers = 0,
    }

    return s, nil
end

function SecureSocket:connect()
    local rx_bytes, rx_err = self:read_raw(self.rx.buffer + self.rx.available, self.rx.length - self.rx.available)

    if rx_err then
        if rx_err == "not_connected" then
            return false, nil
        elseif rx_err ~= "timeout" then
            return false, "read_raw"
        end
    end

    if rx_bytes then
        self.rx.available = self.rx.available + rx_bytes
    end

    local ctx = self.ctx

    if not ctx then
        self.ctx = ffi.gc(ffi.cast("PCtxtHandle", lib.C.malloc(ffi.sizeof("CtxtHandle"))), lib.C.free)
    end

    local flags = ffi.new("unsigned int[1]", { isc_flags })

    local in_buffers = ffi.new("SecBuffer[2]", {
        { BufferType = lib.D.SECBUFFER_TOKEN, pvBuffer = self.rx.buffer, cbBuffer = self.rx.available },
        { BufferType = lib.D.SECBUFFER_EMPTY },
    })
    local in_desc = ffi.new("SecBufferDesc", { lib.D.SECBUFFER_VERSION, 2, in_buffers })

    local out_buffers = ffi.new("SecBuffer[1]", {
        { BufferType = lib.D.SECBUFFER_TOKEN },
    })
    local out_desc = ffi.new("SecBufferDesc", { lib.D.SECBUFFER_VERSION, 1, out_buffers })

    local err = ffi.cast("uint32_t", lib.SSL.InitializeSecurityContextA(
        self.handle,
        ctx,
        not ctx and ffi.cast("char *", self.host) or nil,
        flags[0],
        0,
        0,
        ctx and in_desc or nil,
        0,
        not ctx and self.ctx or nil,
        out_desc,
        flags,
        nil
    ))

    if in_buffers[1].BufferType == lib.D.SECBUFFER_EMPTY then
        self.rx.available = 0
    elseif in_buffers[1].BufferType == lib.D.SECBUFFER_MISSING then
        -- Do nothing
    elseif in_buffers[1].BufferType == lib.D.SECBUFFER_EXTRA then
        local length = in_buffers[1].cbBuffer
        lib.C.memmove(self.rx.buffer, self.rx.buffer + (self.rx.available - length), length)
        self.rx.available = length
    else
        return false, "secbuffer_unknown"
    end

    if err == lib.D.SEC_E_OK then
        local sizes = ffi.new("SecPkgContext_StreamSizes[1]")
        if ffi.cast("uint32_t", lib.SSL.QueryContextAttributesA(self.ctx, lib.D.SECPKG_ATTR_STREAM_SIZES, sizes)) ~= lib.D.SEC_E_OK then
            return false, "querycontextattributes"
        end

        self.sizes.header = sizes[0].cbHeader
        self.sizes.trailer = sizes[0].cbTrailer
        self.sizes.message = sizes[0].cbMaximumMessage
        self.sizes.buffers = sizes[0].cBuffers

        return true, nil
    elseif err == lib.D.SEC_I_CONTINUE_NEEDED then
        local tx = {
            length = out_buffers[0].cbBuffer,
            buffer = ffi.cast("uint8_t *", out_buffers[0].pvBuffer),
        }

        while tx.length > 0 do
            local tx_bytes, tx_err = self:write_raw(tx.buffer, tx.length)

            if tx_err and tx_err ~= "timeout" then
                break
            end

            if tx_bytes and tx_bytes > 0 then
                tx.length = tx.length - tx_bytes
                tx.buffer = tx.buffer + tx_bytes
            end
        end

        lib.SSL.FreeContextBuffer(out_buffers[0].pvBuffer)

        if tx.length ~= 0 then
            return false, "write_raw"
        end
    elseif err ~= lib.D.SEC_E_INCOMPLETE_MESSAGE then
        return false, "initializesecuritycontexta"
    end

    return false, nil
end

function SecureSocket:close()
    if self.socket == nil then
        return "closed"
    end

    local err = nil

    if self.ctx then
        local flags = ffi.new("unsigned int[1]", { isc_flags })

        local type = ffi.new("DWORD[1]", lib.D.SCHANNEL_SHUTDOWN)

        local in_buffers = ffi.new("SecBuffer[1]", {
            { BufferType = lib.D.SECBUFFER_TOKEN, pvBuffer = type, cbBuffer = ffi.sizeof(type) },
        })
        local in_desc = ffi.new("SecBufferDesc", { lib.D.SECBUFFER_VERSION, 1, in_buffers })

        lib.SSL.ApplyControlToken(self.ctx, in_desc)

        local out_buffers = ffi.new("SecBuffer[1]", {
            { BufferType = lib.D.SECBUFFER_TOKEN },
        })
        local out_desc = ffi.new("SecBufferDesc", { lib.D.SECBUFFER_VERSION, 1, out_buffers })

        if ffi.cast("uint32_t", lib.SSL.InitializeSecurityContextA(
                self.handle,
                self.ctx,
                nil,
                flags[0],
                0,
                0,
                in_desc,
                0,
                nil,
                out_desc,
                flags,
                nil
            )) == lib.D.SEC_E_OK then
            local tx = {
                length = out_buffers[0].cbBuffer,
                buffer = ffi.cast("uint8_t *", out_buffers[0].pvBuffer)
            }

            while tx.length > 0 do
                local tx_bytes, tx_err = self:write_raw(tx.buffer, tx.length)

                if tx_err and tx_err ~= "timeout" then
                    break
                end

                if tx_bytes and tx_bytes > 0 then
                    tx.length = tx.length - tx_bytes
                    tx.buffer = tx.buffer + tx_bytes
                end
            end

            lib.SSL.FreeContextBuffer(out_buffers[0].pvBuffer)

            if tx.length ~= 0 then
                err = "write_raw"
            end
        end

        if ffi.cast("uint32_t", lib.SSL.DeleteSecurityContext(self.ctx)) ~= lib.D.SEC_E_OK then
            err = "deletesecuritycontext"
        end
    end

    if self.handle then
        if ffi.cast("uint32_t", lib.SSL.FreeCredentialsHandle(self.handle)) ~= lib.D.SEC_E_OK then
            err = "freecredentialhandle"
        end
    end

    if lib.S.closesocket(self.socket) ~= 0 then
        err = "closesocket"
    end

    self.ctx = nil
    self.handle = nil
    self.socket = nil
    self.rx.buffer = nil
    self.tx.buffer = nil

    return err
end

---@param raw_buffer ffi.cdata*
---@param length integer
---@return integer?, string?
function SecureSocket:write_raw(raw_buffer, length)
    local bytes = ffi.cast("int", lib.S.send(self.socket, raw_buffer, length, 0))

    if bytes <= 0 then
        local socket_err = lib.S.WSAGetLastError()
        if socket_err == lib.D.WSAEWOULDBLOCK then
            return nil, "timeout"
        elseif socket_err == lib.D.WSAENOTCONN then
            return nil, "not_connected"
        else
            return nil, "send"
        end
    end

    return tonumber(bytes), nil
end

function SecureSocket:send(data)
    if self.socket == nil then
        return nil, "closed"
    end

    local length = #data > self.sizes.message and self.sizes.message or #data

    local out_buffers = ffi.new("SecBuffer[3]", {
        { BufferType = lib.D.SECBUFFER_STREAM_HEADER,  pvBuffer = self.tx.buffer,                              cbBuffer = self.sizes.header },
        { BufferType = lib.D.SECBUFFER_DATA,           pvBuffer = self.tx.buffer + self.sizes.header,          cbBuffer = length },
        { BufferType = lib.D.SECBUFFER_STREAM_TRAILER, pvBuffer = self.tx.buffer + self.sizes.header + length, cbBuffer = self.sizes.trailer },
    })
    local out_desc = ffi.new("SecBufferDesc", { lib.D.SECBUFFER_VERSION, 3, out_buffers })

    ffi.copy(self.tx.buffer + self.sizes.header, data, length)

    if ffi.cast("uint32_t", lib.SSL.EncryptMessage(self.ctx, 0, out_desc, 0)) ~= lib.D.SEC_E_OK then
        return nil, "encryptmessage"
    end

    local tx = {
        length = out_buffers[0].cbBuffer + out_buffers[1].cbBuffer + out_buffers[2].cbBuffer,
        buffer = self.tx.buffer
    }

    while tx.length > 0 do
        local tx_bytes, tx_err = self:write_raw(tx.buffer, tx.length)

        if tx_err and tx_err ~= "timeout" then
            break
        end

        if tx_bytes and tx_bytes > 0 then
            tx.length = tx.length - tx_bytes
            tx.buffer = tx.buffer + tx_bytes
        end
    end

    if tx.length ~= 0 then
        return nil, "write_raw"
    end

    return length, nil
end

---@param raw_buffer ffi.cdata*
---@param length integer
---@return integer?, string?
function SecureSocket:read_raw(raw_buffer, length)
    local bytes = ffi.cast("int", lib.S.recv(self.socket, raw_buffer, length, 0))

    if bytes <= 0 then
        local socket_err = lib.S.WSAGetLastError()
        if socket_err == lib.D.WSAEWOULDBLOCK then
            return nil, "timeout"
        elseif socket_err == lib.D.WSAENOTCONN then
            return nil, "not_connected"
        else
            return nil, "recv"
        end
    end

    return tonumber(bytes), nil
end

function SecureSocket:receive()
    if self.socket == nil then
        return nil, "closed"
    end

    local rx_bytes, rx_err = self:read_raw(self.rx.buffer + self.rx.available, self.rx.length - self.rx.available)

    if rx_err and rx_err ~= "timeout" then
        return false, "read_raw"
    end

    if rx_bytes and rx_bytes > 0 then
        self.rx.available = self.rx.available + rx_bytes
    end

    if self.rx.available == 0 then
        return nil, "timeout"
    end

    local in_buffers = ffi.new("SecBuffer[?]", self.sizes.buffers)
    in_buffers[0] = { BufferType = lib.D.SECBUFFER_DATA, pvBuffer = self.rx.buffer, cbBuffer = self.rx.available }
    for i = 1, self.sizes.buffers - 1 do
        in_buffers[i] = { BufferType = lib.D.SECBUFFER_EMPTY }
    end

    local in_desc = ffi.new("SecBufferDesc", { lib.D.SECBUFFER_VERSION, self.sizes.buffers, in_buffers })

    local err = ffi.cast("uint32_t", lib.SSL.DecryptMessage(self.ctx, in_desc, 0, nil))

    if err == lib.D.SEC_E_OK then
        local data = ""

        for i = 0, self.sizes.buffers - 1 do
            local type = in_buffers[i].BufferType
            if type == lib.D.SECBUFFER_DATA then
                data = data .. ffi.string(in_buffers[i].pvBuffer, in_buffers[i].cbBuffer)
            elseif type == lib.D.SECBUFFER_EXTRA then
                local length = in_buffers[i].cbBuffer
                lib.C.memmove(self.rx.buffer, self.rx.buffer + (self.rx.available - length), length)
                self.rx.available = length
            elseif type == lib.D.SECBUFFER_EMPTY then
                self.rx.available = 0
            end
        end

        return data, nil
    elseif err == lib.D.SEC_E_INCOMPLETE_MESSAGE then
        return nil, "timeout"
    end

    return nil, "decryptmessage"
end

return SecureSocket
