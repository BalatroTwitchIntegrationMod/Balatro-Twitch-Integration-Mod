---@class Mod
local mod = SMODS.current_mod

mod.commands.bankrupt = {
    can_exec = function(params)
        return G.GAME.dollars > 0
    end,
    exec = function(params)
        ease_dollars(-G.GAME.dollars)

        attention_text({
            colour = G.C.WHITE,
            text = "BANKRUPT!",
            scale = 1,
            hold = 2,
            major = G.play,
            backdrop_colour = G.C.BLACK
        })

        play_sound("ttv_BANKRUPT", 1, 1)
    end
}
