---@class TwitchAuth
---@field private client_id string
---@field private scope string[]
---@field private port number
---@field private path string
---@field private channel string
---@field private thread? love.Thread
local TwitchAuth = {}

---@private
TwitchAuth.__index = TwitchAuth

local utils = require("socket.utils")
local json = require("json")

local whitelist = {}

local function add_to_whitelist(path)
    for _, v in ipairs(type(path) == "string" and { path } or path) do
        whitelist[v] = true
    end
end

local function is_whitelisted(path)
    return whitelist[path] ~= nil
end

add_to_whitelist({
    "auth.html"
})

---@return boolean
function TwitchAuth:is_running()
    return self.thread and self.thread:isRunning() or false
end

function TwitchAuth:start_auth()
    if self:is_running() then
        return
    end

    love.thread.getChannel(self.channel .. ".tx"):clear()
    love.thread.getChannel(self.channel .. ".rx"):clear()

    self.thread = love.thread.newThread(self.path .. "server.lua")

    self.thread:start(self.channel, self.port)

    love.system.openURL("https://id.twitch.tv/oauth2/authorize?" .. utils.format_url_params({
        client_id = self.client_id,
        force_verify = "true",
        redirect_uri = "http://localhost:" .. self.port,
        response_type = "token",
        scope = table.concat(self.scope, " "),
    }))
end

function TwitchAuth:abort_auth()
    if self:is_running() then
        self:send({ type = "kill" })
        self.thread:wait()
    end
end

---@return ServerMessage?
---@private
function TwitchAuth:receive()
    return love.thread.getChannel(self.channel .. ".rx"):pop()
end

---@param message ServerMessage
---@private
function TwitchAuth:send(message)
    love.thread.getChannel(self.channel .. ".tx"):push(message)
end

---@param response HttpResponse
---@private
function TwitchAuth:send_response(response)
    self:send({
        type = "response",
        response = response
    })
end

---@return {value: string}?
function TwitchAuth:get_token()
    local message = self:receive()

    if message then
        if message.type == "kill" then
            return { value = nil }
        end

        if message.type == "request" then
            local request = message.request ---@type HttpRequest

            if request.path == "token" then
                self:send_response({
                    headers = { ["content-type"] = "application/json" },
                    body = json.encode({ ok = true }),
                })
                self:send({ type = "kill" })
                return { value = request.params["access_token"] }
            else
                if request.path == "" then
                    request.path = "auth.html"
                end

                local body = is_whitelisted(request.path) and love.filesystem.read(self.path .. request.path) or nil

                self:send_response({
                    code = body and 200 or 404,
                    status = not body and "Not found" or nil,
                    body = body or "Not found",
                })
            end
        end

        if message.type == "error" then
            self:send_response({
                code = 400,
                status = "Bad request",
                body = "Bad request",
            })
        end
    end

    return nil
end

---@param client_id string
---@param scope string[]
---@param path string?
---@return TwitchAuth
function TwitchAuth:new(client_id, scope, path)
    ---@type TwitchAuth
    local o = {
        client_id = client_id,
        scope = scope,
        port = 3480,
        channel = "twitchintegration.auth",
        path = (path or "") .. "twitch/"
    }
    return setmetatable(o, self)
end

return TwitchAuth
