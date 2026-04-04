--- STEAMODDED HEADER
--- MOD_NAME: Twitch Chat Integration
--- MOD_ID: TwitchIntegration
--- MOD_AUTHOR: chowder

---@class Mod
local mod = SMODS.current_mod

---@param message string
---@param level? "debug" | "info"
function mod.log(message, level)
    local LOGGER = "TwitchIntegration"
    level = level or "info"
    if level == "debug" then
        sendDebugMessage(message, LOGGER)
    else
        sendInfoMessage(message, LOGGER)
    end
end

---@class ModHook
---@field draw fun()[]
---@field update fun(dt: number)[]
mod.hook = {
    draw = {},
    update = {},
}

---@param ref fun() | fun(dt?: number)
---@param type? "draw" | "update"
function mod.hook:add(ref, type)
    if type == "draw" then
        self.draw[ref] = ref
    else
        self.update[ref] = ref
    end
end

local game_draw_ref = Game.draw
---@diagnostic disable-next-line: duplicate-set-field
function Game:draw()
    game_draw_ref(self)

    for _, ref in pairs(mod.hook.draw) do
        ref()
    end
end

local game_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
    for _, ref in pairs(mod.hook.update) do
        ref(dt)
    end

    game_update_ref(self, dt)
end

assert(SMODS.load_file("twitch.lua"))()

assert(SMODS.load_file("atlas.lua"))()

function mod.menu_cards()
    return {
        key = "j_ttv_chatters",
        remove_original = true
    }
end

local config_tab_vars = {
    connect_status = nil,
    user_login = nil,
    connect_button = nil,
}

local function prepare_config_tab_vars()
    local params = ({
        disconnected = { "Disconnected", G.C.RED, "CONNECT", G.C.PURPLE },
        authenticating = { "Authenticating...", G.C.BLUE, "CANCEL", G.C.RED },
        authenticated = { "Authenticated", G.C.BLUE, "CANCEL", G.C.RED },
        connecting = { "Connecting...", G.C.BLUE, "CANCEL", G.C.RED },
        connected = { "Connected", G.C.GREEN, "DISCONNECT", G.C.BLUE }
    })[mod.twitch.state]

    config_tab_vars.connect_status = params[1]
    config_tab_vars.user_login = mod.twitch.user and mod.twitch.user.login or "none"
    config_tab_vars.connect_button = params[3]

    return {
        status_color = params[2],
        user_color = mod.twitch.user and G.C.PURPLE or G.C.GREY,
        button_color = params[4]
    }
end

function mod.config_tab()
    local p = prepare_config_tab_vars()

    return {
        n = G.UIT.ROOT,
        config = { align = "cm", minw = 6, padding = 0.4, r = 0.1, emboss = 0.05, colour = G.C.BLACK, id = mod.id .. "config_tab" },
        nodes = { {
            n = G.UIT.R,
            config = { align = "cm" },
            nodes = {
                { n = G.UIT.T, config = { text = "Twitch API: ", scale = 0.4, colour = G.C.WHITE } },
                { n = G.UIT.T, config = { ref_table = config_tab_vars, ref_value = "connect_status", scale = 0.4, colour = p.status_color, id = mod.id .. "status" } }
            }
        }, {
            n = G.UIT.R,
            config = { align = "cm" },
            nodes = {
                { n = G.UIT.T, config = { text = "Channel: ", scale = 0.4, colour = G.C.WHITE } },
                { n = G.UIT.T, config = { ref_table = config_tab_vars, ref_value = "user_login", scale = 0.4, colour = p.user_color, id = mod.id .. "user" } }
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
                config = { align = "cm", button = mod.id .. "connect_trigger", colour = p.button_color, r = 0.1, minw = 2.6, minh = 0.6, hover = true, shadow = true, id = mod.id .. "connect" },
                nodes = { { n = G.UIT.T, config = { ref_table = config_tab_vars, ref_value = "connect_button", scale = 0.4, colour = G.C.WHITE } } }
            } }
        }, {
            n = G.UIT.R,
            config = { align = "cm" },
            nodes = { { n = G.UIT.T, config = { text = "Pressing CONNECT button will open a browser window", scale = 0.3, colour = G.C.GREY } } }
        } }
    }
end

mod.hook:add(function(dt)
    local config_tab = G.OVERLAY_MENU and G.OVERLAY_MENU:get_UIE_by_ID(mod.id .. "config_tab")

    if config_tab then
        local p = prepare_config_tab_vars()

        local uibox = config_tab.UIBox

        uibox:get_UIE_by_ID(mod.id .. "status").config.colour = p.status_color
        uibox:get_UIE_by_ID(mod.id .. "user").config.colour = p.user_color
        uibox:get_UIE_by_ID(mod.id .. "connect").config.colour = p.button_color
    end
end)
