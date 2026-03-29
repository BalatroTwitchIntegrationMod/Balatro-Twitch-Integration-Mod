---@class Mod
local mod = SMODS.current_mod

mod.commands.levelup = {
    exec = function(params)
        SMODS.upgrade_poker_hands({ level_up = 1 })

        play_sound("ttv_fart_sound1", 1)
    end
}

mod.commands.leveldown = {
    can_exec = function(params)
        for _, hand in pairs(G.GAME.hands) do
            if hand.level > 0 then
                return true
            end
        end

        return false
    end,
    exec = function(params)
        for key, hand in pairs(G.GAME.hands) do
            if hand.level > 0 then
                level_up_hand(nil, key, false, -1)
            end
        end

        play_sound("ttv_fart_sound1", 1)
    end
}
