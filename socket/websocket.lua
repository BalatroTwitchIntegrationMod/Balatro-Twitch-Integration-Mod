---@alias WebSocketMessageFormat "unknown" | "binary" | "text"

---@alias WebSocketEvent
---| { type: "disconnected" }
---| { type: "connected" }
---| { type: "pong", payload: string }
---| { type: "message", format: WebSocketMessageFormat, payload: string }

---@class SecureWebSocket
---@field state "disconnected" | "connecting" | "upgrading" | "connected"
---@field private client? SecureSocket
---@field private request string
---@field private key_response string
---@field private buffer string
---@field private rx { buffer: string, fin: boolean, opcode: WebSocketOpCode, format: WebSocketMessageFormat, length?: number }
---@field private response? HttpResponse
---@field private event_queued? table
local SecureWebSocket = {}

SecureWebSocket.__index = SecureWebSocket

local bit = require("bit")
local socket = require("socket.secure")
local utils = require("socket.utils")

---@enum WebSocketOpCode
SecureWebSocket.OPCODE = {
    CONT = 0,
    TEXT = 1,
    BINARY = 2,
    CLOSE = 8,
    PING = 9,
    PONG = 10,
}

---@enum WebSocketStatus
SecureWebSocket.STATUS = {
    NORMAL_CLOSURE = 1000,
    PROTOCOL_ERROR = 1002,
}

---@param length number
---@return string
local function generate_random_key(length)
    math.randomseed(os.time())
    local key = string.gsub(string.rep(" ", length), " ", function(_) return string.char(math.random(0, 255)) end)
    return key
end

---@return string, string
local function create_websocket_key()
    local request = utils.b64_encode(generate_random_key(16))
    local response = utils.b64_encode(utils.sha1(request .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
    return request, response
end

---@param data string
---@param key string
---@return string
local function mask_data(data, key)
    local masked = ""
    local key_bytes = utils.bytes_to_numbers(key, 1)
    local i = 0
    for byte in utils.bytes(data) do
        local encoded = bit.bxor(byte, key_bytes[math.fmod(i, #key_bytes) + 1])
        masked = masked .. string.char(encoded)
        i = i + 1
    end
    return masked
end

---@param url string
---@return string?
function SecureWebSocket:open(url)
    if self.state ~= "disconnected" then
        return nil
    end

    local scheme, host_and_port, path = string.match(url, "(.+)://([^/]*)(.*)")

    if not (scheme and host_and_port and path) then
        return "url"
    end

    if scheme ~= "wss" then
        return "scheme"
    end

    local host, port = string.match(host_and_port, "([^:]+):?(.*)")

    if not host or host == "" then
        return "host"
    end

    if not port or port == "" then
        port = "443"
    end

    if path == "" then
        path = "/"
    end

    local client, socket_err = socket:open(host, port)

    if not client or socket_err then
        return "open"
    end

    local key_request, key_response = create_websocket_key()

    self.state = "connecting"
    self.client = client
    self.request = utils.format_http_request({
        path = path,
        headers = {
            ["Host"] = host,
            ["Connection"] = "Upgrade",
            ["Upgrade"] = "websocket",
            ["Sec-Websocket-Key"] = key_request,
            ["Sec-Websocket-Version"] = 13,
        }
    })
    self.key_response = key_response
    self.buffer = ""
    self.rx = {
        buffer = "",
        fin = false,
        format = "unknown",
        opcode = self.OPCODE.CONT,
        length = nil
    }
    self.response = nil
    self.event_queued = nil

    return nil
end

---@param code? WebSocketStatus
---@param reason? string
function SecureWebSocket:close(code, reason)
    if self.state == "disconnected" then
        return
    end

    if code then
        self:send(self.OPCODE.CLOSE, utils.numbers_to_bytes(code, 2) .. (reason or ""))
    end

    self.client:close()

    self.state = "disconnected"
    self.client = nil
    self.request = ""
    self.key_response = ""
    self.buffer = ""
    self.rx = {
        buffer = "",
        fin = false,
        format = "unknown",
        opcode = self.OPCODE.CONT,
        length = nil
    }
    self.response = nil
    self.event_queued = { type = "disconnected" }
end

---@param event fun(event: WebSocketEvent): boolean?
function SecureWebSocket:process(event)
    if self.state == "connecting" then
        local ready, err = self.client:connect()
        if err and err ~= "timeout" then
            self:close()
        elseif ready then
            self.state = "upgrading"
        end
    end

    if self.state == "upgrading" then
        if #self.request > 0 then
            local bytes, tx_err = self.client:send(self.request)

            if tx_err and tx_err ~= "timeout" then
                self:close()
            elseif bytes and bytes > 0 then
                self.request = string.sub(self.request, bytes + 1)
            end
        end

        local rx_data, rx_err = self.client:receive()

        if rx_err and rx_err ~= "timeout" then
            self:close()
        elseif rx_data and #rx_data > 0 then
            self.buffer = self.buffer .. rx_data

            local err = nil

            self.response, self.buffer, err = utils.parse_http_response(self.response, self.buffer)
            if err then
                self:close()
            elseif self.response and self.response.done then
                local response = self.response
                self.response = nil
                if not response then
                    self:close()
                elseif response.code ~= 101 then
                    self:close()
                elseif string.lower(response.headers["connection"]) ~= "upgrade" then
                    self:close()
                elseif string.lower(response.headers["upgrade"]) ~= "websocket" then
                    self:close()
                elseif response.headers["sec-websocket-accept"] ~= self.key_response then
                    self:close()
                else
                    self.state = "connected"
                    event({ type = "connected" })
                end
            end
        end
    end

    if self.state == "connected" then
        local rx_data, rx_err = self.client:receive()

        if rx_data and #rx_data > 0 then
            self:fill_buffer(rx_data)
        elseif rx_err and rx_err ~= "timeout" then
            self:close()
        end

        while true do
            if self.rx.length == nil then
                local parse_err = self:parse()

                if parse_err then
                    if parse_err == "continue" then
                        break
                    else
                        self:close(self.STATUS.PROTOCOL_ERROR)
                    end
                end
            end

            if self.rx.length ~= nil then
                local payload = self:read_buffer("payload")

                if payload then
                    if self.rx.opcode < self.OPCODE.CLOSE then
                        self.buffer = self.buffer .. payload

                        if self.rx.fin then
                            local exit = event({
                                type = "message",
                                format = self.rx.format,
                                payload = self.buffer,
                            })
                            self.buffer = ""
                            if exit then
                                break
                            end
                        end
                    elseif self.rx.opcode == self.OPCODE.PING then
                        if self:send(self.OPCODE.PONG, payload) then
                            self:close()
                        end
                    elseif self.rx.opcode == self.OPCODE.PONG then
                        if event({ type = "pong", payload = payload }) then
                            break
                        end
                    elseif self.rx.opcode == self.OPCODE.CLOSE then
                        local code = self.STATUS.NORMAL_CLOSURE
                        local reason = "normal closure"

                        if #payload >= 2 then
                            code = utils.bytes_to_numbers(payload, 2)[1]
                            reason = string.sub(payload, 3)
                        end

                        self:close(code, reason)

                        break
                    end
                else
                    break
                end
            end
        end
    end

    if self.event_queued then
        event(self.event_queued)
        self.event_queued = nil
    end
end

---@param opcode WebSocketOpCode
---@param payload string?
---@return string?
function SecureWebSocket:send(opcode, payload)
    local data = ""

    local length = #payload

    if length > 125 then
        length = 126
    elseif length > 65535 then
        length = 127
    end

    data = data .. utils.numbers_to_bytes({
        bit.bor(0x80, opcode),
        bit.bor(0x80, length),
    }, 1)

    if length == 126 then
        data = data .. utils.numbers_to_bytes(#payload, 2)
    elseif length == 127 then
        if #payload > 0xFFFFFFFFULL then
            return "error" -- Data over (4 GiB - 1 byte) is not supported
        end
        data = data .. utils.numbers_to_bytes({ 0, #payload }, 4)
    end

    local key = generate_random_key(4)

    data = data .. key

    if payload and #payload > 0 then
        data = data .. mask_data(payload, key)
    end

    while #data > 0 do
        local sent, error = self.client:send(data)

        if error and error ~= "timeout" then
            return error
        end

        data = string.sub(data, sent + 1)
    end

    return nil
end

---@param data string
---@private
function SecureWebSocket:fill_buffer(data)
    self.rx.buffer = self.rx.buffer .. data
end

---@param mode "peek" | "payload"
---@param length? number
---@return string?
---@private
function SecureWebSocket:read_buffer(mode, length)
    if mode == "payload" then
        length = self.rx.length
    end

    length = length or 0

    local data = string.sub(self.rx.buffer, 1, length)

    if #data == length then
        if mode ~= "peek" then
            self:skip_buffer(length)
        end

        if mode == "payload" then
            self.rx.length = nil
        end

        return data
    end

    return nil
end

---@param length number
---@private
function SecureWebSocket:skip_buffer(length)
    self.rx.buffer = string.sub(self.rx.buffer, length + 1)
end

---@return "continue" | "error" | nil
---@private
function SecureWebSocket:parse()
    local to_skip = 0

    local header = self:read_buffer("peek", 2)

    if not header then
        return "continue"
    end

    local bytes = utils.bytes_to_numbers(header)

    to_skip = to_skip + 2

    local fin = bit.rshift(bytes[1], 7) == 1
    local opcode = tonumber(bit.band(bytes[1], 0x0F)) --[[@as number]]
    local masked = bit.rshift(bytes[2], 7) == 1
    local length = bit.band(bytes[2], 0x7F)

    if (not fin and opcode >= self.OPCODE.CLOSE) or masked then
        return "error"
    end

    if length == 126 then
        header = self:read_buffer("peek", to_skip + 2)

        if not header then
            return "continue"
        end

        length = utils.bytes_to_numbers(string.sub(header, to_skip + 1, to_skip + 2), 2)[1]

        to_skip = to_skip + 2
    elseif length == 127 then
        header = self:read_buffer("peek", to_skip + 8)

        if not header then
            return "continue"
        end

        local split_length = utils.bytes_to_numbers(string.sub(header, to_skip + 1, to_skip + 8), 4)

        if split_length[1] > 0 then
            return "error" -- Data over (4 GiB - 1 byte) is not supported
        end

        length = split_length[2]

        to_skip = to_skip + 8
    end

    self:skip_buffer(to_skip)

    self.rx.fin = fin
    self.rx.opcode = opcode
    self.rx.length = length

    if self.rx.opcode < self.OPCODE.CLOSE then
        if self.rx.opcode == self.OPCODE.TEXT then
            self.rx.format = "text"
        elseif self.rx.opcode == self.OPCODE.BINARY then
            self.rx.format = "binary"
        elseif self.rx.opcode ~= self.OPCODE.CONT then
            self.rx.format = "unknown"
        end
    end

    return nil
end

---@return SecureWebSocket
function SecureWebSocket:new()
    ---@type SecureWebSocket
    local o = {
        state = "disconnected",
        client = nil,
        request = "",
        key_response = "",
        buffer = "",
        rx = {
            buffer = "",
            fin = false,
            opcode = self.OPCODE.CONT,
            format = "unknown",
            length = nil,
        },
        response = nil,
        event_queued = nil
    }
    return setmetatable(o, self)
end

return SecureWebSocket
