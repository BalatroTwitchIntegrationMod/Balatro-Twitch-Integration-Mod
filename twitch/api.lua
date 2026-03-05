---@type Mod
local mod = SMODS.Mods.twitchintegration

---@class TwitchApi
---@field private client_id string
---@field private token string
local TwitchApi = {
    client_id = "__INVALID_CLIENT_ID__",
    token = "__INVALID_TOKEN__"
}

---@private
TwitchApi.__index = TwitchApi

---@class Payload
---@field endpoint string
---@field method? string
---@field params? table<string, number|string|(number|string)[]>
---@field data? table

---@module "https.smods-https"
local https = require("SMODS.https")

---@module "lib.json"
local json = SMODS.load_file("lib/json.lua")()

---@param payload Payload
---@return string, table
---@private
function TwitchApi:prepare_request_data(payload)
    local url = "https://api.twitch.tv/helix/" .. payload.endpoint

    if payload.params then
        url = url .. "?" .. mod.utils.format_url_params(payload.params)
    end

    local options = {
        method = payload.method,
        headers = {
            ["Authorization"] = "Bearer " .. self.token,
            ["Client-Id"] = self.client_id
        }
    }

    if payload.data then
        options.headers["Content-Type"] = "application/json"
        options.data = json.encode(payload.data)
    end

    return url, options
end

---@param payload Payload
---@param callback? fun(response?: table)
---@async
---@private
function TwitchApi:request(payload, callback)
    local url, options = self:prepare_request_data(payload)

    return https.asyncRequest(url, options, function(code, body, headers)
        if callback then
            callback(code == 200 and json.decode(body) or nil)
        end
    end)
end

---@param token string?
function TwitchApi:set_token(token)
    self.token = token or "__INVALID_TOKEN__"
end

---@param params BanUserParams
---@param callback? fun(response?: BanUserResponse)
---@async
function TwitchApi.ban_user(self, params, callback)
    return self:request({
        endpoint = "moderation/bans",
        params = {
            broadcaster_id = params.broadcaster_id,
            moderator_id = params.moderator_id
        },
        data = {
            data = {
                user_id = params.user_id,
                duration = params.duration,
                reason = params.reason
            }
        }
    }, function (response)
        if callback then
            callback(response and response.data)
        end
    end)
end

---@param params GetStreamsParams
---@param callback? fun(response?: GetStreamsResponse[], pagination?: Pagination)
---@async
function TwitchApi:get_streams(params, callback)
    return self:request({
        endpoint = "streams",
        params = params
    }, function (response)
        if callback then
            callback(response and response.data, response and response.pagination)
        end
    end)
end

---@param params GetUsersParams
---@param callback? fun(response?: GetUsersResponse[])
---@async
function TwitchApi:get_users(params, callback)
    return self:request({
        endpoint = "users",
        params = params
    }, function (response)
        if callback then
            callback(response and response.data)
        end
    end)
end

---@param client_id string
---@param token? string
---@return TwitchApi
function TwitchApi:new(client_id, token)
    ---@type TwitchApi
    local o = {
        client_id = client_id,
        token = token or TwitchApi.token
    }
    return setmetatable(o, self)
end

return TwitchApi
