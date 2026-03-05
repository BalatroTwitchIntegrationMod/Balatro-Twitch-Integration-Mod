SMODS.ScreenShader {
    key = "flashlight_screen_shader",
    path = "flashlight.fs",
    send_vars = function(self)
        local mx, my = love.mouse.getPosition()
        return {
            center_pos = {mx, my},
            dist = 300
        }
    end,
    should_apply = function()
        return SMODS.Mods.twitchintegration.flashlight_on
    end
}

SMODS.ScreenShader {
    key = "glitch_screen_shader",
    path = "glitch.fs",
    send_vars = function(self)
        return {
            iTime = G.TIMERS.REAL
        }
    end,
    should_apply = function()
        return SMODS.Mods.twitchintegration.glitch ~= nil
    end
}
