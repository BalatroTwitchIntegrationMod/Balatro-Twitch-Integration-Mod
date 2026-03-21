---@alias ServerMessage
---| {type: "kill"}
---| {type: "request", request: HttpRequest}
---| {type: "response", response: HttpResponse}
---| {type: "error"}

local channel, port = ...

local socket = require("socket")
local utils = require("socket.utils")

local timeout = 1 / 120
local server = socket.tcp4()

---@cast server TCPSocketServer?

local connection = nil
local rx_buffer = ""
local tx_buffer = nil

local request = nil

---@return ServerMessage?
local receive_message = function()
    return love.thread.getChannel(channel .. ".tx"):pop()
end

---@param data ServerMessage
local send_message = function(data)
    love.thread.getChannel(channel .. ".rx"):push(data)
end

if not server then
    send_message({ type = "kill" })
    return
end

server:setoption("reuseaddr", true)

local _, bind_err = server:bind("127.0.0.1", port)
local _, listen_err = server:listen(8)

if bind_err or listen_err then
    send_message({ type = "kill" })
    return
end

server:settimeout(timeout)

while true do
    local message = receive_message()

    if message then
        if message.type == "kill" then
            send_message({ type = "kill" })
            break
        end

        if message.type == "response" then
            tx_buffer = utils.format_http_response(message.response)
        end
    end

    if not connection then
        local c, c_err = server:accept()
        if c and c_err == nil then
            connection = c
            connection:settimeout(timeout)
            rx_buffer = ""
            tx_buffer = nil
            request = nil
        end
    end

    if connection then
        if tx_buffer then
            while #tx_buffer > 0 do
                local bytes, tx_err, partial = connection:send(tx_buffer)

                if bytes and bytes > 0 then
                    tx_buffer = string.sub(tx_buffer, bytes + 1)
                elseif partial and partial > 0 then
                    tx_buffer = string.sub(tx_buffer, partial + 1)
                elseif tx_err ~= "timeout" then
                    break
                end
            end

            tx_buffer = nil

            connection:shutdown("both")
            connection:close()
            connection = nil
        else
            local data, rx_err, partial = connection:receive("*a")

            local parse = false

            if data and #data > 0 then
                rx_buffer = rx_buffer .. data
                parse = true
            elseif partial and #partial > 0 then
                rx_buffer = rx_buffer .. partial
                parse = true
            elseif rx_err and rx_err ~= "timeout" then
                connection:shutdown("both")
                connection:close()
                connection = nil
            end

            if parse then
                local parse_err
                request, rx_buffer, parse_err = utils.parse_http_request(request, rx_buffer)

                if request and request.done then
                    send_message({ type = "request", request = request })
                    request = nil
                elseif parse_err then
                    send_message({ type = "error" })
                end
            end
        end
    end
end

if connection then
    connection:shutdown("both")
    connection:close()
    connection = nil
end

if server then
    server:close()
    server = nil
end
