---@class Mod
local mod = SMODS.current_mod

local agga_countdown = 0

mod.commands.agga = {
    can_exec = function(params)
        print(agga_countdown == 0)
        return agga_countdown == 0
    end,
    exec = function(params)
        agga_countdown = 30
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
        return agga_countdown > 0
    end
}

local game_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
    game_update_ref(self, dt)

    agga_countdown = math.max(agga_countdown - dt, 0)
end
