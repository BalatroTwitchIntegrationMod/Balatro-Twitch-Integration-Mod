---@class Mod
local mod = SMODS.current_mod

---@class IRCMessage
---@field tags? table<string, string>
---@field source? string
---@field command string
---@field params? table<number, string>

---@class IRCPrivmsg
---@field user string
---@field channel string
---@field text string
---@field display_name string
---@field user_id string
---@field is_broadcaster boolean
---@field is_moderator boolean
---@field is_vip boolean
---@field is_subscriber boolean

---@class TwitchChat
---@field client? SecureTCPSocketClient
---@field buffer string
---@field token string
---@field user_name string
---@field state "disconnected" | "connecting" | "handshake" | "connected"
---@field handshake "not started" | "cap req" | "cap ack" | "login" | "wait" | "done"
---@field event_queued? TwitchChatEvent
local TwitchChat = {}

---@private
TwitchChat.__index = TwitchChat

---@class EventConnected
---@field type "connected"

---@class EventDisconnected
---@field type "disconnected"

---@class EventJoined
---@field type "joined"
---@field channel string

---@class EventMessage
---@field type "message"
---@field message IRCPrivmsg

---@class EventClear
---@field type "clear"
---@field channel string
---@field user_name? string
---@field user_id? string
---@field duration? string

---@alias TwitchChatEvent EventConnected | EventDisconnected | EventJoined | EventMessage | EventClear

local socket = require("socket")

---@param value string
---@return string
local function unescape_tag_value(value)
    value = string.gsub(value, "\\\\", "\\")
    value = string.gsub(value, "\\r", "\r")
    value = string.gsub(value, "\\n", "\n")
    value = string.gsub(value, "\\s", " ")
    value = string.gsub(value, "\\:", ";")
    return value
end

---@param value string
---@return string
local function escape_tag_value(value)
    value = string.gsub(value, "\\", "\\\\")
    value = string.gsub(value, "\r", "\\r")
    value = string.gsub(value, "\n", "\\n")
    value = string.gsub(value, " ", "\\s")
    value = string.gsub(value, ";", "\\:")
    return value
end

---@param tags_string string
---@return table<string, string>
local function parse_irc_tags(tags_string)
    local tags = {}

    for t in string.gmatch(tags_string, "[^;]+") do
        local key, value = string.match(t, "(.-)=(.*)")
        if key and value then
            tags[key] = unescape_tag_value(value)
        else
            tags[t] = ""
        end
    end

    return tags
end

---@param tags table<string, string>
---@return string
local function format_irc_tags(tags)
    local tags_string = ""

    for key, value in pairs(tags) do
        if #tags_string > 0 then
            tags_string = tags_string .. ";"
        end
        tags_string = tags_string .. key .. "=" .. escape_tag_value(value)
    end

    return tags_string
end

---@param params_string string
---@return table<number, string>?
local function parse_irc_params(params_string)
    if not params_string then
        return nil
    end

    local params = {}
    local param = ""
    local prev_c = " "
    local final_param = false

    for c in string.gmatch(params_string, ".") do
        if final_param then
            param = param .. c
        elseif c == " " then
            if #param > 0 then
                table.insert(params, param)
                param = ""
            end
        elseif prev_c == " " and c == ":" then
            final_param = true
        else
            param = param .. c
        end
        prev_c = c
    end

    table.insert(params, param)

    return params
end

---@param params table<number, string>
---@return string?
local function format_irc_params(params)
    local params_string = ""

    for index, value in ipairs(params) do
        local add_escape = false

        if #value == 0 or string.find(value, "^:") or string.find(value, "%s") then
            add_escape = true
        end

        if add_escape and index < #params then
            return nil
        end

        params_string = params_string .. (add_escape and ":" or "") .. value

        if index < #params then
            params_string = params_string .. " "
        end
    end

    return params_string
end

---@param message_string string
---@return IRCMessage
local function parse_irc_message(message_string)
    local message = {
        command = "__INVALID__"
    }

    local tags, tags_end = string.match(message_string, "^@(.-)%s+()")

    if tags then
        message.tags = parse_irc_tags(tags)
        message_string = string.sub(message_string, tags_end)
    end

    local source, source_end = string.match(message_string, "^:(.-)%s+()")

    if source then
        message.source = source
        message_string = string.sub(message_string, source_end)
    end

    local command, command_end = string.match(message_string, "^([%w]+)()")

    if command then
        message_string = string.sub(message_string, command_end)
        local params = string.match(message_string, "^%s+(.+)")
        if #message_string == 0 or params then
            message.command = command
            message.params = parse_irc_params(params)
        end
    end

    return message
end

---@param message IRCMessage
---@return IRCPrivmsg?
local function parse_privmsg(message)
    local user = string.match(message.source, "^[%w_]-!([%w_]-)@[%w_.]-")

    if not user or #message.params < 2 then
        return nil
    end

    local channel = string.match(message.params[1], "#(.+)")
    local text = message.params[2]

    if not channel or not text then
        return nil
    end

    local display_name = message.tags and message.tags["display-name"] or user
    local user_id = message.tags and message.tags["user-id"] or user
    local is_broadcaster = (message.tags and string.find(message.tags.badges or "", "broadcaster/", 1, true)) ~= nil
    local is_moderator = (message.tags and message.tags.mod) == "1"
    local is_vip = (message.tags and message.tags.vip) == "1"
    local is_subscriber = (message.tags and message.tags.subscriber) == "1"

    return {
        user = user,
        channel = channel,
        text = text,
        display_name = display_name,
        user_id = user_id,
        is_broadcaster = is_broadcaster,
        is_moderator = is_moderator,
        is_vip = is_vip,
        is_subscriber = is_subscriber
    }
end

---@param message IRCMessage
---@return string?
local function format_irc_message(message)
    local message_string = ""

    if message.tags then
        message_string = "@" .. format_irc_tags(message.tags) .. " "
    end

    if message.source then
        message_string = message_string .. ":" .. message.source .. " "
    end

    message_string = message_string .. message.command

    if message.params then
        local params = format_irc_params(message.params)
        if not params then
            return nil
        end
        message_string = message_string .. " " .. params
    end

    message_string = message_string .. "\r\n"

    return message_string
end

---@param user_name string
function TwitchChat:connect(token, user_name)
    if self.state == "disconnected" then
        local client = socket.tcp()

        if not client then
            return
        end

        client:settimeout(0)

        local _, err = client:connect("irc.chat.twitch.tv", 6697)
        if err and err ~= "timeout" then
            client:close()
            return
        end

        ---@cast client TCPSocketClient

        self.client = mod.utils.secure_socket:wrap(client)
        self.buffer = ""
        self.token = token
        self.user_name = user_name
        self.state = "connecting"
        self.handshake = "not started"
    end
end

function TwitchChat:disconnect()
    if self.state ~= "disconnected" then
        self.state = "disconnected"
        self.handshake = "not started"
        self.client:close()
        self.client = nil
        self.event_queued = {type = "disconnected"}
    end
end

function TwitchChat:join(channel)
    local err = self:send({
        command = "JOIN",
        params = {
            "#" .. channel
        }
    })

    if err then
        self:disconnect()
    end
end

---@param message IRCMessage|IRCMessage[]
---@return string?
---@private
function TwitchChat:send(message)
    local data = ""

    for _, v in ipairs(message[1] and message or {message}) do
        local formatted = format_irc_message(v)

        if not formatted then
            return "invalid"
        end

        data = data .. formatted
    end

    local bytes, err = self.client:send(data)

    if bytes ~= #data then
        return "partial"
    end

    return err
end

---@return IRCMessage?, string?
---@private
function TwitchChat:receive()
    local line, err = self.client:receive()

    if line then
        if #self.buffer > 0 then
            line = self.buffer .. line
            self.buffer = ""
        end

        return parse_irc_message(line)
    end

    return nil, err
end

---@param channel string
---@param text string
---@return string?
function TwitchChat:send_message(channel, text)
    local err = self:send({
        command = "PRIVMSG",
        params = {
            "#" .. channel,
            text
        }
    })

    if err then
        self:disconnect()
    end

    return err
end

---@param event fun(event: TwitchChatEvent)
function TwitchChat:process(event)
    if self.state == "connecting" then
        local ready, err = self.client:connect()
        if err and err ~= "timeout" then
            self:disconnect()
        elseif ready then
            self.state = "handshake"
            self.handshake = "cap req"
        end
    end

    if self.state == "handshake" then
        if self.handshake == "cap req" then
            local err = self:send({
                command = "CAP",
                params = {
                    "REQ",
                    "twitch.tv/commands twitch.tv/tags"
                }
            })
            if err then
                self:disconnect()
            else
                self.handshake = "cap ack"
            end
        end

        if self.handshake == "cap ack" then
            local response, err = self:receive()
            if err and err ~= "timeout" then
                self:disconnect()
            elseif response and response.command == "CAP" then
                if response.params[1] == "*" and response.params[2] == "ACK" then
                    self.handshake = "login"
                else
                    self:disconnect()
                end
            end
        end

        if self.handshake == "login" then
            local err = self:send({{
                command = "PASS",
                params = {
                    "oauth:" .. self.token
                }
            }, {
                command = "NICK",
                params = {
                    self.user_name
                }
            }})
            if err then
                self:disconnect()
            else
                self.handshake = "wait"
            end
        end

        if self.handshake == "wait" then
            local response, err = self:receive()
            if err and err ~= "timeout" then
                self:disconnect()
            elseif response then
                if response.command == "NOTICE" then
                    self:disconnect()
                else
                    self.state = "connected"
                    self.handshake = "done"
                    event({type = "connected"})
                end
            end
        end
    end

    if self.state == "connected" then
        while true do
            local message, err = self:receive()

            if err and err ~= "timeout" then
                self:disconnect()
                break
            end

            if not message then
                break
            end

            if message.command == "PING" then
                local err = self:send({
                    command = "PONG",
                    params = message.params
                })
                if err then
                    self:disconnect()
                    break
                end
            elseif message.command == "RECONNECT" then
                self:disconnect()
                break
            elseif message.command == "JOIN" then
                event({
                    type = "joined",
                    channel = string.match(message.params[1], "#(.+)")
                })
            elseif message.command == "PRIVMSG" then
                local parsed = parse_privmsg(message)
                if parsed then
                    event({
                        type = "message",
                        message = parsed
                    })
                end
            elseif message.command == "CLEARCHAT" then
                event({
                    type = "clear",
                    channel = string.match(message.params[1], "#(.+)"),
                    user_name = message.params[2],
                    user_id = message.tags and message.tags["target-user-id"],
                    duration = message.tags and message.tags["ban-duration"]
                })
            end
        end
    end

    if self.event_queued then
        event(self.event_queued)
        self.event_queued = nil
    end
end

---@return TwitchChat
function TwitchChat:new()
    ---@type TwitchChat
    local o = {
        client = nil,
        buffer = "",
        token = "",
        user_name = "",
        state = "disconnected",
        handshake = "not started",
        event_queued = nil
    }
    return setmetatable(o, self)
end

return TwitchChat
