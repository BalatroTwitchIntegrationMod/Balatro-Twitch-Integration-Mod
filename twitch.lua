---@class Mod
---@field path string
local mod = SMODS.current_mod

---@alias TwitchConnectionState 
---| "disconnected"
---| "authenticating"
---| "authenticated"
---| "connecting"
---| "connected"

local TWITCH_CLIENT_ID = "iu1n0iv7lqs1g9bhoxa6z58bl91swl"
local TWITCH_CLIENT_SCOPE = {
    "channel:moderate",
    "moderator:manage:banned_users",
    "user:read:chat",
}

local twitch_lib = require("twitch.lib")

mod.twitch = {}

mod.twitch.auth = twitch_lib.auth:new(TWITCH_CLIENT_ID, TWITCH_CLIENT_SCOPE, mod.path)
mod.twitch.api = twitch_lib.api:new(TWITCH_CLIENT_ID, mod.config.token)
mod.twitch.eventsub = twitch_lib.eventsub:new(mod.twitch.api)

mod.twitch.state = mod.config.token and "authenticated" or "disconnected" ---@type TwitchConnectionState
mod.twitch.user = nil ---@type GetUsersResponse?
mod.twitch.viewer_count = 0

---@type ChatCommandRunner
local commands = assert(SMODS.load_file("commands.lua"))()

---@param token string?
local function update_twitch_token(token)
    mod.twitch.api:set_token(token)
    mod.config.token = token
    SMODS.save_mod_config(mod)
end

---@param e UIElement
G.FUNCS[mod.id .. "connect_trigger"] = function(e)
    if mod.config.token then
        mod.log("Disconnected from Twitch")
        mod.twitch.state = "disconnected"
        mod.twitch.user = nil
        mod.twitch.viewer_count = 0
        mod.twitch.eventsub:disconnect()
        update_twitch_token()
    elseif mod.twitch.auth:is_running() then
        mod.log("Aborted Twitch authentication")
        mod.twitch.auth:abort_auth()
    else
        mod.log("Waiting for token from browser...")
        mod.twitch.state = "authenticating"
        mod.twitch.auth:start_auth()
    end
end

mod.hook:add(function(dt) -- Update Twitch auth
    if mod.twitch.state == "authenticating" then
        local token = mod.twitch.auth:get_token()
        if token then
            if token.value then
                mod.log("Token acquired")
                mod.twitch.state = "authenticated"
                play_sound("polychrome1")
            else
                mod.log("Failed to acquire token")
                mod.twitch.state = "disconnected"
                play_sound("cancel", 0.8)
            end
            update_twitch_token(token.value)
        end
    end

    if mod.twitch.state == "authenticated" then
        mod.twitch.state = "connecting"
        mod.twitch.api:get_users({}, function(response)
            if response and response[1] then
                mod.log("Fetched connected user info")
                mod.twitch.state = "connected"
                mod.twitch.user = response[1]
            else
                mod.log("Failed to fetch connected user info")
                mod.twitch.state = "disconnected"
                update_twitch_token()
            end
        end)
    end
end)

mod.hook:add(function(dt) -- Update Twitch EventSub
    if mod.twitch.eventsub.state == "disconnected" and mod.twitch.user then
        mod.log("Connecting to the Twitch EventSub...")
        mod.twitch.eventsub:connect()
    end

    mod.twitch.eventsub:process(function(self, event)
        if event.type == "disconnected" then
            mod.log("Disconnected from the Twitch EventSub")
        end

        if event.type == "connected" and mod.twitch.user then
            mod.log("Connected to the Twitch EventSub")

            self:add("channel.chat.message", 1, {
                broadcaster_user_id = mod.twitch.user.id,
                user_id = mod.twitch.user.id
            }, function(payload)
                commands:message(payload)
            end)

            self:add("channel.ban", 1, {
                broadcaster_user_id = mod.twitch.user.id,
            }, function(payload)
                commands:ban(payload)
            end)
        end
    end)
end)

local update_stream_counter = nil
mod.hook:add(function(dt) -- Update Twitch stream info
    if mod.twitch.state ~= "connected" or not mod.twitch.user then
        update_stream_counter = nil
        return
    end

    if update_stream_counter == nil or os.difftime(os.time(), update_stream_counter) >= 20 then
        update_stream_counter = os.time()
    else
        return
    end

    mod.twitch.api:get_streams({
        user_id = mod.twitch.user.id
    }, function(data)
        local viewer_count = 0

        if data and #data >= 1 then
            viewer_count = data[1].viewer_count
        end

        mod.twitch.viewer_count = viewer_count

        G.E_MANAGER:add_event(Event({
            func = function()
                local cards = SMODS.find_card("j_ttv_chatters")
                for _, joker in ipairs(cards) do
                    joker.config.center:set_chips(joker, viewer_count)
                end
                return true
            end
        }))
    end)
end)
