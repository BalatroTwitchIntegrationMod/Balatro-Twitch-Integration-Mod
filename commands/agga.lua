---@class Mod
local mod = SMODS.current_mod

local agga_glitch = false

mod.commands.agga = {
    can_exec = function(params)
        return not agga_glitch
    end,
    exec = function(params)
        agga_glitch = true

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            blocking = false,
            delay = G.SPEEDFACTOR * (24.5),
            func = function()
                agga_glitch = false
                return true
            end
        }))
    end
}

SMODS.ScreenShader {
    key = "glitch_screen_shader",
    path = "glitch.fs",
    send_vars = function()
        return {
            iTime = G.TIMERS.REAL
        }
    end,
    should_apply = function()
        return agga_glitch
    end
}
