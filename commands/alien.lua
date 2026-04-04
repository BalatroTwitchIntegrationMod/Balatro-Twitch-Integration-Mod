---@class Mod
local mod = SMODS.current_mod

local alien_countdown = 0
local alien_data = {}

mod.commands.alien = {
    can_exec = function(params)
        return alien_countdown == 0
    end,
    exec = function(params)
        local atlas_data = G.ASSET_ATLAS["ttv_alien_overlay"]

        if not atlas_data then
            return
        end

        play_sound("ttv_alien_gibberish", 1, 1)

        G.ROOM.jiggle = G.ROOM.jiggle + 25

        local screen_w = love.graphics.getWidth()
        local screen_h = love.graphics.getHeight()
        local target_h = screen_h * 0.6
        local scale_factor = target_h / atlas_data.py

        local random_x = math.random() * (screen_w - atlas_data.px * scale_factor)
        local random_y = math.random() * (screen_h - target_h)

        alien_countdown = 5
        alien_data = {
            image = atlas_data.image,
            x = random_x,
            y = random_y,
            scale = scale_factor
        }
    end
}

mod.hook:add(function(dt)
    alien_countdown = math.max(alien_countdown - dt, 0)
end, "update")

mod.hook:add(function()
    if alien_countdown > 0 then
        if alien_data.image then
            love.graphics.push("all")
            love.graphics.draw(
                alien_data.image,
                alien_data.x,
                alien_data.y,
                0,
                alien_data.scale,
                alien_data.scale,
                0,
                0
            )
            love.graphics.pop()
        end
    end
end, "draw")
