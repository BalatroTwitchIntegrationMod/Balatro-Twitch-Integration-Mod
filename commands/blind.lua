---@class Mod
local mod = SMODS.current_mod

local flashlight_on = false

mod.commands.blind = {
    can_exec = function(params)
        return not flashlight_on
    end,
    exec = function(params)
        flashlight_on = true

        attention_text({
            colour = G.C.GREY,
            text = "BLINDED FOR 30 SECONDS!",
            scale = 1,
            hold = 11,
            major = G.play,
            backdrop_colour = G.C.BLACK
        })

        play_sound("ttv_flashlight")

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            blocking = false,
            delay = G.SPEEDFACTOR * (24.5),
            func = function()
                flashlight_on = false
                play_sound("ttv_flashlight")
                return true
            end
        }))
    end
}

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
        return flashlight_on
    end
}
