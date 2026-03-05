---@type Mod
local mod = SMODS.Mods.twitchintegration

---@class TwitchAuth
---@field private client_id string
---@field private thread? love.Thread
local TwitchAuth = {
    client_id = "__INVALID_CLIENT_ID__"
}

---@private
TwitchAuth.__index = TwitchAuth

---@param scope string
function TwitchAuth:start_auth(scope)
    if self:is_running() then
        return
    end

    love.thread.getChannel("twitchintegration.auth.token"):clear()

    self.thread = love.thread.newThread([[
        local RESPONSE_REDIRECT = "<html><head><script>location.href = '/token?' + location.hash.substr(1)</script></head></html>"
        local RESPONSE_DONE = "<html><head><title>Balatro Twitch Integration</title><script>history.replaceState(null, '', 'http://localhost:3480/done');</script></head><body>You can close this window.</body></html>"

        local timer = require("love.timer")
        local socket = require("socket")
        local server = socket.tcp()
        local connection = nil

        server:settimeout(0)
        server:bind('localhost', 3480)
        server:listen()

        local get_message = function()
            return love.thread.getChannel("twitchintegration.auth.server"):pop()
        end

        local send_token = function(token)
            love.thread.getChannel("twitchintegration.auth.token"):push({value = token})
        end

        local format_response = function(body)
            headers = "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/html\r\n"
            return headers .. "Content-Length: " .. tostring(#body) .. "\r\n\r\n" .. body
        end

        while true do
            local message = get_message()
            if message == "kill" then
                send_token()
                break
            end

            if not connection then
                timer.sleep(1/240)
                connection = server:accept()
            else
                local response, err = connection:receive("*l")
                if err and err ~= "timeout" then
                    connection:close()
                    connection = nil
                end
                if response then
                    local request = response:match("^GET (.+) HTTP.+")
                    if request then
                        local error = request:match("error=([^&]+)")
                        local token = request:match("access_token=([^&]+)")
                        if error or token then
                            connection:send(format_response(RESPONSE_DONE))
                            send_token(token)
                            break
                        else
                            connection:send(format_response(RESPONSE_REDIRECT))
                        end
                        connection:close()
                        connection = nil
                    end
                end
            end
        end

        if connection then
            connection:close()
        end

        if server then
            server:close()
        end
    ]])

    self.thread:start()

    love.system.openURL("https://id.twitch.tv/oauth2/authorize?" .. mod.utils.format_url_params({
        client_id = self.client_id,
        force_verify = "true",
        redirect_uri = "http://localhost:3480",
        response_type = "token",
        scope = scope
    }))
end

function TwitchAuth:abort_auth()
    if self:is_running() then
        love.thread.getChannel("twitchintegration.auth.server"):push("kill")
        self.thread:wait()
    end
end

---@return boolean
function TwitchAuth:is_running()
    return self.thread and self.thread:isRunning() or false
end

---@return {value?: string}
function TwitchAuth:get_token()
    return love.thread.getChannel("twitchintegration.auth.token"):pop()
end

---@param client_id string
---@return TwitchAuth
function TwitchAuth:new(client_id)
    ---@type TwitchAuth
    local o = {
        client_id = client_id
    }
    return setmetatable(o, self)
end

return TwitchAuth
