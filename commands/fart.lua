---@class Mod
local mod = SMODS.current_mod

mod.commands.fart = {
    anywhere = true,
    exec = function(params)
        play_sound("ttv_fart_sound1", 1, 1)
    end
}
