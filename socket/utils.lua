---@alias HttpHeaders table<string, string|number>
---@alias HttpParams table<string, boolean|number|string|(boolean|number|string)[]>

---@class HttpPacket
---@field state? "empty" | "headers" | "body" | "chunked" | "trailer" | "done"
---@field done? boolean
---@field headers? HttpHeaders
---@field body? string
---@field remaining? number

---@class HttpRequest: HttpPacket
---@field method? string
---@field path? string
---@field params? HttpParams

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
---@param separator string
---@return fun(): string?, string?
function Utils.split_by(text, separator)
    local position = 0

    return function()
        local nl_start, nl_end = string.find(text, separator, position, true)

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

---@param bytes string
---@return fun(): number?
function Utils.bytes(bytes)
    local position = 1
    return function()
        if position > #bytes then
            return nil
        end
        local char = string.byte(bytes, position)
        position = position + 1
        return char
    end
end

---@param bytes string
---@param size? number
---@param endian? "big" | "little"
---@return number[]
function Utils.bytes_to_numbers(bytes, size, endian)
    local result = {}

    size = size or 1

    for i = 1, #bytes, size do
        local slice = string.sub(bytes, i, i + size)
        slice = slice .. string.rep("\x00", size - #slice)

        if endian == "little" then
            slice = string.reverse(slice)
        end

        local v = 0

        for _, n in ipairs({ string.byte(slice, 1, size) }) do
            v = bit.bor(bit.lshift(v, 8), n)
        end

        table.insert(result, v)
    end

    return result
end

---@param numbers number|number[]
---@param size number
---@param endian? "big" | "little"
---@return string
function Utils.numbers_to_bytes(numbers, size, endian)
    local result = ""

    local t = type(numbers) == "table" and numbers or { numbers }

    for _, v in pairs(t --[[@as number[]-]]) do
        local p = ""

        for _ = 1, size do
            local c = string.char(bit.band(v, 0xFF))

            if endian == "little" then
                p = p .. c
            else
                p = c .. p
            end

            v = bit.rshift(v, 8)
        end

        result = result .. p
    end

    return result
end

---@param data string
---@return string
function Utils.b64_encode(data)
    local encoded = ""
    local phase = 0
    local carry = 0

    local encode = function(byte, continue)
        if phase == 0 then
            if continue then
                encoded = encoded .. b64_alphabet[bit.rshift(byte, 2)]
                carry = bit.lshift(bit.band(byte, 0x03), 4)
            end
        end

        if phase == 1 then
            encoded = encoded .. b64_alphabet[bit.bor(carry, bit.rshift(byte, 4))]
            carry = bit.lshift(bit.band(byte, 0x0F), 2)
            if not continue then
                encoded = encoded .. "=="
            end
        end

        if phase == 2 then
            encoded = encoded .. b64_alphabet[bit.bor(carry, bit.rshift(byte, 6))]
            if continue then
                encoded = encoded .. b64_alphabet[bit.band(byte, 0x3F)]
            else
                encoded = encoded .. "="
            end
        end
    end

    for byte in Utils.bytes(data) do
        encode(byte, true)

        phase = phase + 1
        if phase >= 3 then
            phase = 0
        end
    end

    encode(0, false)

    return encoded
end

---@param data string
---@return string
function Utils.sha1(data)
    local padding = math.fmod(#data + 1, 64)
    local filler = string.rep("\x00", (padding <= 56) and (56 - padding) or (64 - padding + 56))
    local length = Utils.numbers_to_bytes({ 0, #data * 8 }, 4)

    data = data .. "\x80" .. filler .. length

    local h = {
        [0] = 0x67452301,
        [1] = 0xEFCDAB89,
        [2] = 0x98BADCFE,
        [3] = 0x10325476,
        [4] = 0xC3D2E1F0,
    }

    local processed = 0

    while processed < #data do
        local w = Utils.bytes_to_numbers(string.sub(data, processed + 1, processed + 64), 4)

        for i = 17, 80 do
            w[i] = bit.rol(bit.bxor(w[i - 3], w[i - 8], w[i - 14], w[i - 16]), 1)
        end

        local a = h[0]
        local b = h[1]
        local c = h[2]
        local d = h[3]
        local e = h[4]

        for i = 1, 80 do
            local f = 0
            local k = 0

            if i <= 20 then
                f = bit.bor(bit.band(b, c), bit.band(bit.bnot(b), d))
                k = 0x5A827999
            elseif i <= 40 then
                f = bit.bxor(b, c, d)
                k = 0x6ED9EBA1
            elseif i <= 60 then
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

---@param params HttpParams
---@return string
function Utils.format_url_params(params)
    local list = {}

    for key, value in pairs(params) do
        local escaped_key = Utils.escape_url_param(key)

        if type(value) ~= "table" then
            value = { value }
        end

        for _, v in ipairs(value) do
            table.insert(list, table.concat({ escaped_key, Utils.escape_url_param(v) }, "="))
        end
    end

    return table.concat(list, "&")
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
---@return HttpParams
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

---@generic T: HttpPacket
---@param packet T?
---@param data string
---@param mode "request" | "response"
---@return T?, string, string?
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
        for line, rest in Utils.split_by(data, "\r\n") do
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
        for line, rest in Utils.split_by(data, "\r\n") do
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
        for line, rest in Utils.split_by(data, "\r\n") do
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
    return r, d, e
end

---@param response HttpResponse?
---@param data string
---@return HttpResponse?, string, string?
function Utils.parse_http_response(response, data)
    local r, d, e = Utils.parse_http_packet(response, data, "response")
    return r, d, e
end

return Utils
