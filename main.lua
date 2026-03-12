--- STEAMODDED HEADER
--- MOD_NAME: Twitch Chat Integration
--- MOD_ID: TwitchIntergration
--- MOD_AUTHOR: chowder

assert(SMODS.load_file("atlas.lua"))()

---@class Mod
local mod_obj = SMODS.current_mod
mod_obj.flashlight_on = false
mod_obj.viewer_count = 0

G.alien_jumpscare_active = nil

local TWITCH_CLIENT_ID = "iu1n0iv7lqs1g9bhoxa6z58bl91swl"
local TWITCH_CLIENT_SCOPE = "channel:moderate user:read:chat user:write:chat chat:edit chat:read moderator:manage:banned_users"

local twitch = require("twitch.lib")
local twitch_auth = twitch.auth:new(TWITCH_CLIENT_ID)
local twitch_api = twitch.api:new(TWITCH_CLIENT_ID, mod_obj.config.token)
local twitch_chat = twitch.chat:new()

local chat_commands = assert(SMODS.load_file("commands.lua"))()

---@alias ConnectionState "disconnected" | "authenticating" | "authenticated" | "connecting" | "connected"
---@type ConnectionState
local connection_state = mod_obj.config.token and "authenticated" or "disconnected"

---@type GetUsersResponse?
local connected_user = nil

local log = function(message, level)
    local LOGGER = "TwitchIntegration"
    level = level or "info"
    if level == "debug" then
        sendDebugMessage(message, LOGGER)
    else
        sendInfoMessage(message, LOGGER)
    end
end

local function get_config_tab_parameters()
    local params = ({
        disconnected = {"Disconnected", G.C.RED, "CONNECT", G.C.PURPLE},
        authenticating = {"Authenticating...", G.C.BLUE, "CANCEL", G.C.RED},
        authenticated = {"Authenticated", G.C.BLUE, "CANCEL", G.C.RED},
        connecting = {"Connecting...", G.C.BLUE, "CANCEL", G.C.RED},
        connected = {"Connected", G.C.GREEN, "DISCONNECT", G.C.BLUE}
    })[connection_state]

    return {
        status_text = params[1],
        status_color = params[2],
        button_text = params[3],
        button_color = params[4],
        user_text = connected_user and connected_user.login or "none",
        user_color = connected_user and G.C.PURPLE or G.C.GREY
    }
end

mod_obj.config_tab = function()
    local p = get_config_tab_parameters()

    return {
        n = G.UIT.ROOT,
        config = {align = "cm", minw = 6, padding = 0.4, r = 0.1, emboss = 0.05, colour = G.C.BLACK},
        nodes = {{
            n = G.UIT.R,
            config = {align = "cm"},
            nodes = {
                {n = G.UIT.T, config = {text = "Status: ", scale = 0.4, colour = G.C.WHITE}},
                {n = G.UIT.T, config = {text = p.status_text, scale = 0.4, colour = p.status_color, id = "ttv_connect_status"}}
            }
        }, {
            n = G.UIT.R,
            config = {align = "cm"},
            nodes = {
                {n = G.UIT.T, config = {text = "Login: ", scale = 0.4, colour = G.C.WHITE}},
                {n = G.UIT.T, config = {text = p.user_text, scale = 0.4, colour = p.user_color, id = "ttv_user"}}
            }
        }, {
            n = G.UIT.R,
            config = {align = "cm"},
            nodes = {
                {n = G.UIT.T, config = {text = "Cooldown (s): ", scale = 0.4, colour = G.C.WHITE}},
                create_text_input({max_length = 3, w = 1, text = tostring(mod_obj.config.cooldown_sec), ref_table = mod_obj.config, ref_value = "cooldown_sec"})
            }
        }, {
            n = G.UIT.R,
            config = {align = "cm"},
            nodes = {{
                n = G.UIT.C,
                config = {align = "cm", button = "twitch_connect_trigger", colour = p.button_color, r = 0.1, minw = 2.5, minh = 0.6, hover = true, shadow = true, id = "ttv_connect_button"},
                nodes = {{n = G.UIT.T, config = {text = p.button_text, scale = 0.4, colour = G.C.WHITE, id = "ttv_connect_button_text"}}}
            }}
        }, {
            n = G.UIT.R,
            config = {align = "cm"},
            nodes = {{n = G.UIT.T, config = {text = "Pressing CONNECT button will open a browser window", scale = 0.3, colour = G.C.GREY}}}
        }}
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
    twitch_api:set_token(token)
    mod_obj.config.token = token
    SMODS.save_mod_config(mod_obj)
end

---@param state ConnectionState
local function update_connection_state(state)
    connection_state = state
    update_config_tab()
end

---@param e UIElement
G.FUNCS.twitch_connect_trigger = function(e)
    if mod_obj.config.token then
        log("Disconnected from Twitch")
        twitch_chat:disconnect()
        connected_user = nil
        update_twitch_token()
        update_connection_state("disconnected")
        mod_obj.viewer_count = 0
    elseif twitch_auth:is_running() then
        log("Aborted Twitch authentication")
        twitch_auth:abort_auth()
    else
        log("Waiting for token from browser...")
        twitch_auth:start_auth(TWITCH_CLIENT_SCOPE)
        update_connection_state("authenticating")
    end
end

local active_votes = {}
---@param card Card
---@param state CopycatVotingState
---@param ui table|UIBox
function mod_obj:add_vote(card, state, ui)
    active_votes[card] = {
        card = card,
        state = state,
        ui = ui,
        start = os.time()
    }
end

local function update_votes()
    for k, v in pairs(active_votes) do
        local elapsed = os.difftime(os.time(), v.start)
        v.state.time_left = ("%01d:%02d"):format(math.floor((30 - elapsed) / 60), (30 - elapsed) % 60)
        if elapsed >= 30 then
            local max = 1
            for i = 2, #v.state.votes do if v.state.votes[i] > v.state.votes[max] then max = i end end
            SMODS.destroy_cards({v.card})
            if v.state.options[max] then SMODS.add_card(v.state.options[max]) end
            active_votes[k] = nil
        end
    end
end

local function update_twitch_auth()
    if connection_state == "authenticating" then
        local token = twitch_auth:get_token()
        if token then
            update_twitch_token(token.value)
            if token.value then
                log("Token acquired")
                play_sound("polychrome1")
                update_connection_state("authenticated")
            else
                log("Failed to acquire token")
                play_sound("cancel", 0.8)
                update_connection_state("disconnected")
            end
        end
    end

    if connection_state == "authenticated" then
        update_connection_state("connecting")
        twitch_api:get_users({}, function(response)
            if response and response[1] then
                log("Fetched connected user info")
                connected_user = response[1]
                update_connection_state("connected")
            else
                log("Failed to fetch connected user info")
                update_twitch_token()
                update_connection_state("disconnected")
            end
        end)
    end
end

---@param user_id string
---@param key string
local function update_ban_jokers(user_id, key)
    for _, joker in ipairs(SMODS.find_card(key)) do
        joker.config.center:apply_ban(joker, user_id)
    end
end

---@param message IRCPrivmsg
local function run_chat_command(message)
    local command, arg = string.match(message.text, "^!(%w+)%s*(%S*)")
    if command then
        command = command:lower()
        if chat_commands[command] then
            for _, joker in ipairs(SMODS.find_card("j_ttv_mods")) do
                log("Prevented command [" .. command .. "] by user [" .. message.user .. "] argument [" .. arg .. "]", "debug")
                joker.config.center:decrease_protections(joker)
                if connected_user and not message.is_broadcaster and not message.is_moderator then
                    twitch_api:ban_user({
                        broadcaster_id = connected_user.id,
                        moderator_id = connected_user.id,
                        user_id = message.user_id,
                        duration = 60,
                        reason = "Balatro Twitch Integration"
                    })
                end
                return
            end

            local text = string.gsub(message.text, "^!" .. command .. "%s+", "")
            log("Running command [" .. command .. "] by user [" .. message.user .. "] argument [" .. arg .. "]", "debug")
            chat_commands[command](arg, message.user, text)
        end
    end
end

local function update_twitch_chat()
    if twitch_chat.state == "disconnected" and connected_user then
        log("Connecting to the Twitch chat...")
        twitch_chat:connect(mod_obj.config.token, connected_user.login)
    end

    twitch_chat:process(function(event)
        local type = event.type

        if type == "disconnected" then
            log("Disconnected from the Twitch chat")
        end

        if type == "connected" then
            log("Connected to the Twitch chat")
            if connected_user then
                twitch_chat:join(connected_user.login)
            end
        end

        if type == "joined" then
            log("Joined the [#" .. event.channel .. "] room")
            -- twitch_chat:send_message(event.channel, "[Balatro Twitch Integration] Successfully connected")
        end

        if type == "clear" then
            if event.user_name then
                if event.duration then
                    log("Timed out user [" .. event.user_name .. "] for " .. event.duration .. " seconds", "debug")
                else
                    log("Permanently banned user [" .. event.user_name .. "]", "debug")
                    update_ban_jokers(event.user_id, "j_ttv_thebanhammer")
                end
            else
                log("Chat was cleared")
            end
        end

        if type == "message" then
            local message = event.message

            log("[#" .. message.channel .. "] " .. message.display_name .. ": " .. message.text, "debug")

            if string.lower(message.text) == "f" then
                update_ban_jokers(message.user, "j_ttv_f")
            end

            local digit = tonumber(string.match(message.text, "[12345]"))
            if digit then
                for _, v in pairs(active_votes) do
                    v.state.votes[digit] = (v.state.votes[digit] or 0) + 1
                end
            end

            run_chat_command(message)
        end
    end)
end

local function update_viewers_jokers(viewer_count)
    G.E_MANAGER:add_event(Event({
        func = function()
            local cards = SMODS.find_card("j_ttv_chatters")
            for _, joker in ipairs(cards) do
                joker.config.center:set_chips(joker, viewer_count)
            end
            return true
        end
    }))
end

local update_stream_info_counter = nil
local function update_stream_info()
    if connection_state ~= "connected" or not connected_user then
        update_stream_info_counter = nil
        return
    end

    if update_stream_info_counter == nil or os.difftime(os.time(), update_stream_info_counter) >= 20 then
        update_stream_info_counter = os.time()
    else
        return
    end

    twitch_api:get_streams({
        user_id = connected_user.id
    }, function(data)
        local viewer_count = 0

        if data and #data >= 1 then
            viewer_count = data[1].viewer_count
        end

        mod_obj.viewer_count = viewer_count

        update_viewers_jokers(viewer_count)
    end)
end

local game_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
    game_update_ref(self, dt)

    update_twitch_auth()

    update_twitch_chat()

    update_stream_info()

    update_votes()

    if mod_obj.glitch then
        mod_obj.glitch = mod_obj.glitch - dt
        if mod_obj.glitch <= 0 then mod_obj.glitch = nil end
    end
end

local game_draw_ref = Game.draw
---@diagnostic disable-next-line: duplicate-set-field
function Game:draw()
    game_draw_ref(self)

    if G.alien_jumpscare_active then
        local data = G.alien_jumpscare_active
        if data.image then
            love.graphics.push("all")
            love.graphics.draw(
                data.image,
                data.x,
                data.y,
                0,
                data.scale,
                data.scale,
                0, 0
            )
            love.graphics.pop()
        end
    end
end

SMODS.current_mod.menu_cards = function()
    return {
        key = "j_ttv_chatters",
        remove_original = true
    }
end
