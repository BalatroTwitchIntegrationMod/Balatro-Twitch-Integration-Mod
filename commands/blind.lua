---@class Mod
local mod = SMODS.current_mod

local blind_countdown = 0

mod.commands.blind = {
    can_exec = function(params)
        return blind_countdown == 0
    end,
    exec = function(params)
        blind_countdown = 30

        attention_text({
            colour = G.C.GREY,
            text = "BLINDED FOR 30 SECONDS!",
            scale = 1,
            hold = 11,
            major = G.play,
            backdrop_colour = G.C.BLACK
        })

        play_sound("ttv_flashlight")
    end
}

mod.hook:add(function(dt)
    local prev_blind_countdown = blind_countdown
    blind_countdown = math.max(blind_countdown - dt, 0)

    if prev_blind_countdown > 0 and blind_countdown == 0 then
        play_sound("ttv_flashlight")
    end
end)

SMODS.ScreenShader {
    key = "flashlight_screen_shader",
    path = "flashlight.fs",
    send_vars = function()
        local mx, my = love.mouse.getPosition()
        local w, h = love.graphics.getDimensions()
        local s = (w > h) and h or w
        return {
            center_pos = {
                love.window.toPixels(mx),
                love.window.toPixels(my),
            },
            dist = love.window.toPixels(s * 0.2)
        }
    end,
    should_apply = function()
        return blind_countdown > 0
    end
}
