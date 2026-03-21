---@class HttpPacket
---@field state? "empty" | "headers" | "body" | "chunked" | "trailer" | "done"
---@field done? boolean
---@field headers? table<string, string|number>
---@field body? string
---@field remaining? number

---@class HttpRequest: HttpPacket
---@field method? string
---@field path? string
---@field params? table<string, boolean|number|string|(boolean|number|string)[]>

---@class HttpResponse: HttpPacket
---@field code? number
---@field status? string

local bit = require("bit")

local b64_alphabet = {
    [0] =
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
    "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f",
    "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
    "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "/",
}

local escape_map = {
    [" "] = "20",
    ["<"] = "3C",
    [">"] = "3E",
    ["#"] = "23",
    ["%"] = "25",
    ["+"] = "2B",
    ["{"] = "7B",
    ["}"] = "7D",
    ["|"] = "7C",
    ["\\"] = "5C",
    ["^"] = "5E",
    ["~"] = "7E",
    ["["] = "5B",
    ["]"] = "5D",
    ["‘"] = "60",
    [";"] = "3B",
    ["/"] = "2F",
    ["?"] = "3F",
    [":"] = "3A",
    ["@"] = "40",
    ["="] = "3D",
    ["&"] = "26",
    ["$"] = "24"
}

local Utils = {}

---@param text string
---@return fun(): string?, string?
function Utils.split_by_newline(text)
    local position = 0

    return function()
        local nl_start, nl_end = string.find(text, "\r\n", position, true)

        if not (nl_start and nl_end) then
            return nil, nil
        else
            local line = string.sub(text, position, nl_start - 1)
            position = nl_end + 1
            local rest = string.sub(text, position)
            return line, rest
        end
    end
end

---@param text string
---@return fun(): number?
function Utils.string_bytes(text)
    local position = 1
    return function()
        if position > #text then
            return nil
        end
        local char = string.byte(text, position)
        position = position + 1
        return char
    end
end

---@param numbers table<number>|number
---@param size number
function Utils.numbers_to_bytes(numbers, size)
    local result = ""

    local t = type(numbers) == "number" and { numbers } or numbers

    ---@cast t table<number>

    for _, v in pairs(t) do
        for i = 0, (size - 1) do
            local c = bit.band(bit.rshift(v, (size - i - 1) * 8), 0xFF)
            result = result .. string.char(c)
        end
    end

    return result
end

---@param data string
---@return string
function Utils.b64_encode(data)
    local encoded = ""

    local iter = Utils.string_bytes(data)
    local push = function(s)
        encoded = encoded .. s
    end

    local exit = false
    local phase = 1
    local left = 0
    local trailing = ""

    while not exit do
        local byte = iter()

        if byte == nil then
            if phase == 1 then
                break
            elseif phase == 2 then
                trailing = "=="
            elseif phase == 3 then
                trailing = "="
            end

            byte = 0
            exit = true
        end

        if phase == 1 then
            push(b64_alphabet[bit.rshift(byte, 2)])
            left = bit.lshift(bit.band(byte, 0x03), 4)
        elseif phase == 2 then
            push(b64_alphabet[bit.bor(left, bit.rshift(byte, 4))])
            left = bit.lshift(bit.band(byte, 0x0F), 2)
        elseif phase == 3 then
            push(b64_alphabet[bit.bor(left, bit.rshift(byte, 6))])
            if not exit then
                push(b64_alphabet[bit.band(byte, 0x3F)])
            end
        end

        phase = phase + 1
        if phase > 3 then
            phase = 1
        end
    end

    push(trailing)

    return encoded
end

---@param data string
---@return string
function Utils.sha1(data)
    bits = #data * 8

    data = data .. "\x80"

    local mod = math.fmod(#data, 64)

    if mod < 56 then
        data = data .. string.rep("\x00", 56 - mod)
    elseif mod > 56 then
        data = data .. string.rep("\x00", 64 - mod + 56)
    end

    data = data .. Utils.numbers_to_bytes({ 0, bits }, 4)

    local get = function(i)
        local value = 0
        for byte in Utils.string_bytes(string.sub(data, i + 1, i + 4)) do
            value = bit.bor(bit.lshift(value, 8), byte)
        end
        return value
    end

    local h = {
        [0] = 0x67452301,
        [1] = 0xEFCDAB89,
        [2] = 0x98BADCFE,
        [3] = 0x10325476,
        [4] = 0xC3D2E1F0,
    }

    local processed = 0

    while processed < #data do
        local w = {}

        for i = 0, 79 do
            if i < 16 then
                w[i] = get(processed + (i * 4))
            else
                w[i] = bit.rol(bit.bxor(w[i - 3], w[i - 8], w[i - 14], w[i - 16]), 1)
            end
        end

        local a = h[0]
        local b = h[1]
        local c = h[2]
        local d = h[3]
        local e = h[4]

        for i = 0, 79 do
            local f = 0
            local k = 0

            if i <= 19 then
                f = bit.bor(bit.band(b, c), bit.band(bit.bnot(b), d))
                k = 0x5A827999
            elseif i <= 39 then
                f = bit.bxor(b, c, d)
                k = 0x6ED9EBA1
            elseif i <= 59 then
                f = bit.bor(bit.band(b, c), bit.band(b, d), bit.band(c, d))
                k = 0x8F1BBCDC
            else
                f = bit.bxor(b, c, d)
                k = 0xCA62C1D6
            end

            local temp = bit.rol(a, 5) + f + e + k + w[i]
            e = d
            d = c
            c = bit.rol(b, 30)
            b = a
            a = temp
        end

        h[0] = h[0] + a
        h[1] = h[1] + b
        h[2] = h[2] + c
        h[3] = h[3] + d
        h[4] = h[4] + e

        processed = processed + 64
    end

    return Utils.numbers_to_bytes(h, 4)
end

---@param value any
---@return string
function Utils.escape_url_param(value)
    local escaped_string = ""
    local in_string_literal = false

    for c in string.gmatch(tostring(value), ".") do
        if c == "\"" then
            in_string_literal = not in_string_literal
        end

        local escaped_c = escape_map[c]

        if escaped_c then
            escaped_string = escaped_string .. (in_string_literal and "$" or "%") .. escaped_c
        else
            escaped_string = escaped_string .. c
        end
    end

    return escaped_string
end

---@param params table<string, boolean|number|string|(boolean|number|string)[]>
---@return string
function Utils.format_url_params(params)
    local params_string = ""

    for key, value in pairs(params) do
        if #params_string > 0 then
            params_string = params_string .. "&"
        end
        local escaped_key = Utils.escape_url_param(key)
        if type(value) == "table" then
            for _, v in ipairs(value) do
                params_string = params_string .. escaped_key .. "=" .. Utils.escape_url_param(v)
            end
        else
            params_string = params_string .. escaped_key .. "=" .. Utils.escape_url_param(value)
        end
    end

    return params_string
end

---@param value string
---@return string
function Utils.unescape_url_param(value)
    value = string.gsub(value, "+", " ")
    local result = string.gsub(value, "%%([a-fA-F0-9][a-fA-F0-9])", function(n)
        return string.char(tonumber(n, 16))
    end)
    return result
end

---@param params_string string
---@return table<string, boolean|number|string|(boolean|number|string)[]>
function Utils.parse_url_params(params_string)
    local params = {}

    for param in string.gmatch(params_string, "([^&]+)") do
        local key, value = string.match(param, "(.-)=(.*)")
        if key and value then
            local unescaped = Utils.unescape_url_param(value)
            local parsed = tonumber(unescaped) or unescaped ---@type boolean|number|string
            if parsed == "true" then
                parsed = true
            end
            if parsed == "false" then
                parsed = false
            end
            if params[key] then
                if type(params[key]) == "table" then
                    params[key][#params[key] + 1] = parsed
                else
                    params[key] = { params[key], parsed }
                end
            else
                params[key] = parsed
            end
        else
            params[param] = ""
        end
    end

    return params
end

---@param request HttpRequest
---@return string
function Utils.format_http_request(request)
    local data = (request.method or "GET") .. " " .. (request.path or "/") .. " HTTP/1.1\r\n"

    for key, value in pairs(request.headers or {}) do
        data = data .. key .. ": " .. tostring(value) .. "\r\n"
    end

    if request.body and #request.body > 0 then
        data = data .. "Content-Length: " .. tostring(#request.body) .. "\r\n"
    end

    data = data .. "\r\n" .. (request.body or "")

    return data
end

---@param response HttpResponse
function Utils.format_http_response(response)
    local code = response.code and tostring(response.code) or "200"

    local data = "HTTP/1.1 " .. code .. " " .. (response.status or "OK") .. "\r\n"

    for key, value in pairs(response.headers or {}) do
        data = data .. key .. ": " .. tostring(value) .. "\r\n"
    end

    if response.body and #response.body > 0 then
        data = data .. "Content-Length: " .. tostring(#response.body) .. "\r\n"
    end

    data = data .. "\r\n" .. (response.body or "")

    return data
end

---@param packet HttpRequest|HttpResponse?
---@param data string
---@param mode "request" | "response"
---@return HttpRequest|HttpResponse?, string, string?
function Utils.parse_http_packet(packet, data, mode)
    local p = packet or {
        state = "empty",
        done = false,
        code = -1,
        status = "",
        headers = {},
        body = "",
        remaining = 0,
    }

    if p.state == "empty" then
        for line, rest in Utils.split_by_newline(data) do
            data = rest

            if mode == "request" then
                local method, path_and_params, version = string.match(line, "([^%s]+) ([^%s]+) HTTP/([.0-9]+)")
                local path, params = string.match(path_and_params or "", "^/?([^%?]*)%??(.*)")

                if not (method and path and params and version) then
                    return nil, data, "malformed request"
                end

                p.state = "headers"
                p.method = method
                p.path = path
                p.params = Utils.parse_url_params(params)
            end

            if mode == "response" then
                local version, code, status = string.match(line, "^HTTP/([.0-9]+) (%d+) (.*)")
                local parsed_code = tonumber(code)

                if not (version and parsed_code and status) then
                    return nil, data, "malformed response"
                end

                p.state = "headers"
                p.code = parsed_code
                p.status = status
            end

            break
        end
    end

    if p.state == "headers" then
        for line, rest in Utils.split_by_newline(data) do
            data = rest

            if line ~= "" then
                local key, value = string.match(line, "([^%s]+):%s*(.*)")

                if not (key and value) then
                    return nil, data, "malformed headers"
                end

                local parsed_value = string.match(tonumber(value) or value, "(.+)%s*$")

                p.headers[string.lower(key)] = parsed_value
            else
                local length = tonumber(p.headers["content-length"])
                local encoding = p.headers["transfer-encoding"]

                if length and encoding then
                    return nil, data, "malformed headers"
                end

                if length and length > 0 then
                    p.state = "body"
                    p.remaining = length or 0
                elseif string.find(string.lower(encoding or ""), "chunked", 1, true) then
                    p.state = "chunked"
                else
                    p.state = "done"
                end

                break
            end
        end
    end

    if p.state == "body" then
        local body = string.sub(data, 1, p.remaining)

        p.body = p.body .. body
        p.remaining = p.remaining - #body

        data = string.sub(data, #body + 1)

        if p.remaining == 0 then
            p.state = "done"
        end
    end

    if p.state == "chunked" then
        while #data > 0 do
            if p.remaining == 0 then
                local length, rest = string.match(data, "^([a-fA-F0-9]+)\r\n(.*)")

                if not (length and rest) then
                    break
                end

                local parsed_length = tonumber(length, 16)

                if parsed_length then
                    p.remaining = parsed_length
                else
                    return nil, rest, "malformed chunk"
                end

                data = rest

                if p.remaining == 0 then
                    p.state = "trailer"
                    break
                end
            end

            if p.remaining > 0 and #data >= p.remaining + 2 then
                local chunk = string.sub(data, 1, p.remaining)

                p.body = p.body .. chunk
                p.remaining = p.remaining - #chunk

                data = string.sub(data, #chunk + 1 + 2)
            else
                break
            end
        end
    end

    if p.state == "trailer" then
        for line, rest in Utils.split_by_newline(data) do
            data = rest
            if line == "" then
                p.state = "done"
            end
        end
    end

    if p.state == "done" then
        p.done = true
    end

    return p, data, nil
end

---@param request HttpRequest?
---@param data string
---@return HttpRequest?, string, string?
function Utils.parse_http_request(request, data)
    local r, d, e = Utils.parse_http_packet(request, data, "request")
    ---@cast r HttpRequest?
    return r, d, e
end

---@param response HttpResponse?
---@param data string
---@return HttpResponse?, string, string?
function Utils.parse_http_response(response, data)
    local r, d, e = Utils.parse_http_packet(response, data, "response")
    ---@cast r HttpResponse?
    return r, d, e
end

return Utils
