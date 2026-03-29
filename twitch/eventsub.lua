---@class EventSubMetadata
---@field message_id string
---@field message_type "session_welcome" | "session_keepalive" | "session_reconnect" | "notification" | "revocation"
---@field message_timestamp string
---@field subscription_type? string
---@field subscription_version? string

---@class EventSubSession
---@field id? string
---@field status? "connected" | "reconnecting"
---@field keepalive_timeout_seconds? number
---@field reconnect_url? string
---@field connected_at? string

---@class EventSubSubscription
---@field id string
---@field status "enabled" | "authorization_revoked" | "user_removed" | "version_removed"
---@field type string
---@field version string
---@field const number
---@field condition table
---@field transport { method: "websocket", session_id: string }
---@field created_at string

---@class EventSubPayload
---@field session? EventSubSession
---@field subscription? EventSubSubscription
---@field event? table

---@alias EventSubMessage
---| { type: "disconnected" }
---| { type: "connected" }

---@class TwitchEventSub
---@field state "disconnected" | "connecting" | "connected"
---@field private ws SecureWebSocket
---@field private ws_reconnect SecureWebSocket?
---@field private api TwitchApi
---@field private id? string
---@field private callbacks fun(payload: EventSubPayload)[]
local TwitchEventSub = {}

---@private
TwitchEventSub.__index = TwitchEventSub

local json = require("json")
local websocket = require("socket.websocket")
local utils = require("socket.utils")

function TwitchEventSub:connect()
    if self.state ~= "disconnected" then
        return
    end

    if self.ws:open("wss://eventsub.wss.twitch.tv/ws?" .. utils.format_url_params({ keepalive_timeout_seconds = 60 })) then
        return
    end

    self.state = "connecting"
    self.ws_reconnect = nil
    self.id = nil
    self.callbacks = {}
end

function TwitchEventSub:disconnect()
    self.ws:close(self.ws.STATUS.NORMAL_CLOSURE)

    if self.ws_reconnect then
        self.ws_reconnect:close(self.ws.STATUS.NORMAL_CLOSURE)
        self.ws_reconnect = nil
    end

    self.state = "disconnected"
end

---@param event fun(self: TwitchEventSub, event: EventSubMessage)
function TwitchEventSub:process(event)
    self.ws:process(function(e)
        if e.type == "disconnected" then
            self:disconnect()
            event(self, { type = "disconnected" })
        end

        if e.type == "connected" then
            self.state = "connected"
        end

        if e.type == "message" and e.format == "text" then
            local data = json.decode(e.payload)

            local metadata = data.metadata --[[@as EventSubMetadata]]
            local payload = data.payload --[[@as EventSubPayload]]

            if metadata.message_type == "session_welcome" then
                self.id = payload.session.id
                event(self, { type = "connected" })
            end

            if metadata.message_type == "session_keepalive" then
                --- Do nothing
            end

            if metadata.message_type == "session_reconnect" then
                self.ws_reconnect = websocket:new()
                if self.ws_reconnect:open(payload.session.reconnect_url) then
                    self:disconnect()
                    event(self, { type = "disconnected" })
                end
            end

            if metadata.message_type == "notification" then
                local callback = self.callbacks[payload.subscription.id]
                if callback then
                    callback(payload)
                end
            end

            if metadata.message_type == "revocation" then
                self.callbacks[payload.subscription.id] = nil
            end
        end
    end)

    local wsr = self.ws_reconnect

    if wsr then
        wsr:process(function(e)
            if e.type == "disconnected" then
                self:disconnect()
                event(self, { type = "disconnected" })
            end

            if e.type == "message" and e.format == "text" then
                local data = json.decode(e.payload)
                local metadata = data.metadata --[[@as EventSubMetadata]]
                local payload = data.payload --[[@as EventSubPayload]]

                if metadata.message_type == "session_welcome" then
                    self.id = payload.session.id
                    self.ws:close(self.ws.STATUS.NORMAL_CLOSURE)
                    self.ws = self.ws_reconnect
                    self.ws_reconnect = nil
                else
                    self:disconnect()
                    event(self, { type = "disconnected" })
                end

                return true
            end
        end)
    end
end

---@param type string
---@param version number
---@param condition table<string, number|string|(number|string)[]>
---@param callback fun(payload: EventSubPayload)
function TwitchEventSub:add(type, version, condition, callback)
    if not self.id then
        return
    end

    self.api:create_eventsub({
        type = type,
        version = tostring(version),
        condition = condition,
        transport = {
            method = "websocket",
            session_id = self.id
        }
    }, function(response)
        if response and #response >= 1 then
            self.callbacks[response[1].id] = callback
        end
    end)
end

---@param api TwitchApi
function TwitchEventSub:new(api)
    ---@type TwitchEventSub
    local o = {
        state = "disconnected",
        ws = websocket:new(),
        ws_reconnect = nil,
        api = api,
        id = nil,
        callbacks = {},
    }
    return setmetatable(o, self)
end

return TwitchEventSub
