---@class Mod
local mod = SMODS.Mods.twitchintegration

if not mod.utils then
    mod.utils = {}
end

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

---@param value any
---@return string
local function escape_url_param(value)
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

---@param params table<string, number|string|(number|string)[]>
---@return string
function mod.utils.format_url_params(params)
    local params_string = ""

    for key, value in pairs(params) do
        if #params_string > 0 then
            params_string = params_string .. "&"
        end
        local escaped_key = escape_url_param(key)
        if type(value) == "table" then
            for _, v in ipairs(value) do
                params_string = params_string .. escaped_key .. "=" .. escape_url_param(v)
            end
        else
            params_string = params_string .. escaped_key .. "=" .. escape_url_param(value)
        end
    end

    return params_string
end
