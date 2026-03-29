--- STEAMODDED HEADER
--- MOD_NAME: Twitch Chat Integration
--- MOD_ID: TwitchIntergration
--- MOD_AUTHOR: chowder

---@class Mod
---@field path string
local mod = SMODS.current_mod

function mod.log(message, level)
    local LOGGER = "TwitchIntegration"
    level = level or "info"
    if level == "debug" then
        sendDebugMessage(message, LOGGER)
    else
        sendInfoMessage(message, LOGGER)
    end
end

---@alias TwitchConnectionState "disconnected" | "authenticating" | "authenticated" | "connecting" | "connected"

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

assert(SMODS.load_file("atlas.lua"))()

local function get_config_tab_parameters()
    local params = ({
        disconnected = { "Disconnected", G.C.RED, "CONNECT", G.C.PURPLE },
        authenticating = { "Authenticating...", G.C.BLUE, "CANCEL", G.C.RED },
        authenticated = { "Authenticated", G.C.BLUE, "CANCEL", G.C.RED },
        connecting = { "Connecting...", G.C.BLUE, "CANCEL", G.C.RED },
        connected = { "Connected", G.C.GREEN, "DISCONNECT", G.C.BLUE }
    })[mod.twitch.state]

    return {
        status_text = params[1],
        status_color = params[2],
        user_text = mod.twitch.user and mod.twitch.user.login or "none",
        user_color = mod.twitch.user and G.C.PURPLE or G.C.GREY,
        button_text = params[3],
        button_color = params[4]
    }
end

function mod.config_tab()
    local p = get_config_tab_parameters()

    return {
        n = G.UIT.ROOT,
        config = { align = "cm", minw = 6, padding = 0.4, r = 0.1, emboss = 0.05, colour = G.C.BLACK },
        nodes = { {
            n = G.UIT.R,
            config = { align = "cm" },
            nodes = {
                { n = G.UIT.T, config = { text = "Twitch API: ", scale = 0.4, colour = G.C.WHITE } },
                { n = G.UIT.T, config = { text = p.status_text, scale = 0.4, colour = p.status_color, id = "ttv_connect_status" } }
            }
        }, {
            n = G.UIT.R,
            config = { align = "cm" },
            nodes = {
                { n = G.UIT.T, config = { text = "Channel: ", scale = 0.4, colour = G.C.WHITE } },
                { n = G.UIT.T, config = { text = p.user_text, scale = 0.4, colour = p.user_color, id = "ttv_user" } }
            }
        }, {
            n = G.UIT.R,
            config = { align = "cm" },
            nodes = {
                { n = G.UIT.T, config = { text = "Cooldown (s): ", scale = 0.4, colour = G.C.WHITE } },
                create_text_input({
                    max_length = 3,
                    w = 1,
                    text = tostring(mod.config.cooldown_sec),
                    ref_table = mod.config,
                    ref_value = "cooldown_sec"
                })
            }
        }, {
            n = G.UIT.R,
            config = { align = "cm" },
            nodes = { {
                n = G.UIT.C,
                config = { align = "cm", button = "twitch_connect_trigger", colour = p.button_color, r = 0.1, minw = 2.5, minh = 0.6, hover = true, shadow = true, id = "ttv_connect_button" },
                nodes = { { n = G.UIT.T, config = { text = p.button_text, scale = 0.4, colour = G.C.WHITE, id = "ttv_connect_button_text" } } }
            } }
        }, {
            n = G.UIT.R,
            config = { align = "cm" },
            nodes = { { n = G.UIT.T, config = { text = "Pressing CONNECT button will open a browser window", scale = 0.3, colour = G.C.GREY } } }
        } }
    }
end

local function update_config_tab()
    if not (G and G.OVERLAY_MENU) then
        return
    end

    local p = get_config_tab_parameters()

    local connect_status = G.OVERLAY_MENU:get_UIE_by_ID("ttv_connect_status")
    if connect_status then
        connect_status.config.text = p.status_text
        connect_status.config.colour = p.status_color
        connect_status.UIBox:recalculate()
    end

    local user_text = G.OVERLAY_MENU:get_UIE_by_ID("ttv_user")
    if user_text then
        user_text.config.text = p.user_text
        user_text.config.colour = p.user_color
        user_text.UIBox:recalculate()
    end

    local connect_button = G.OVERLAY_MENU:get_UIE_by_ID("ttv_connect_button")
    if connect_button then
        connect_button.config.colour = p.button_color
    end

    local connect_button_text_node = G.OVERLAY_MENU:get_UIE_by_ID("ttv_connect_button_text")
    if connect_button_text_node then
        connect_button_text_node.config.text = p.button_text
        connect_button_text_node.UIBox:recalculate()
    end
end

---@param token string?
local function update_twitch_token(token)
    mod.twitch.api:set_token(token)
    mod.config.token = token
    SMODS.save_mod_config(mod)
end

---@param state TwitchConnectionState
local function update_connection_state(state)
    mod.twitch.state = state
    update_config_tab()
end

---@param e UIElement
G.FUNCS.twitch_connect_trigger = function(e)
    if mod.config.token then
        mod.log("Disconnected from Twitch")
        mod.twitch.user = nil
        mod.twitch.viewer_count = 0
        mod.twitch.eventsub:disconnect()
        update_twitch_token()
        update_connection_state("disconnected")
    elseif mod.twitch.auth:is_running() then
        mod.log("Aborted Twitch authentication")
        mod.twitch.auth:abort_auth()
    else
        mod.log("Waiting for token from browser...")
        mod.twitch.auth:start_auth()
        update_connection_state("authenticating")
    end
end

local function update_twitch_auth()
    if mod.twitch.state == "authenticating" then
        local token = mod.twitch.auth:get_token()
        if token then
            update_twitch_token(token.value)
            if token.value then
                mod.log("Token acquired")
                play_sound("polychrome1")
                update_connection_state("authenticated")
            else
                mod.log("Failed to acquire token")
                play_sound("cancel", 0.8)
                update_connection_state("disconnected")
            end
        end
    end

    if mod.twitch.state == "authenticated" then
        update_connection_state("connecting")
        mod.twitch.api:get_users({}, function(response)
            if response and response[1] then
                mod.log("Fetched connected user info")
                mod.twitch.user = response[1]
                update_connection_state("connected")
            else
                mod.log("Failed to fetch connected user info")
                update_twitch_token()
                update_connection_state("disconnected")
            end
        end)
    end
end

local function update_twitch_eventsub()
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
end

local update_stream_counter = nil
local function update_twitch_stream_info()
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
end

local game_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
    game_update_ref(self, dt)

    update_twitch_auth()
    update_twitch_eventsub()
    update_twitch_stream_info()
end

function mod.menu_cards()
    return {
        key = "j_ttv_chatters",
        remove_original = true
    }
end

