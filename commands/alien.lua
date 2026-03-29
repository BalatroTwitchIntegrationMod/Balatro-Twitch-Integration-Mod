---@class Mod
local mod = SMODS.current_mod

local alien_data = nil

mod.commands.alien = {
    can_exec = function(params)
        if alien_data then
            return false
        end
        return true
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

        alien_data = {
            image = atlas_data.image,
            x = random_x,
            y = random_y,
            scale = scale_factor
        }

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 5,
            func = function()
                alien_data = nil
                return true
            end
        }))
    end
}

local game_draw_ref = Game.draw
---@diagnostic disable-next-line: duplicate-set-field
function Game:draw()
    game_draw_ref(self)

    if alien_data then
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
end
