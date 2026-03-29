---@class Mod
local mod = SMODS.current_mod

mod.commands.jackpot = {
    exec = function(params)
        attention_text({
            colour = SMODS.Gradients["ttv_jackpot1"],
            text = "JACKPOT!",
            scale = 1,
            hold = 11,
            major = G.play,
            backdrop_colour = SMODS.Gradients["ttv_jackpot2"]
        })

        play_sound("ttv_jackpot", 1, 1)

        G.E_MANAGER:add_event(Event({
            func = function()
                for i = 1, 30 do
                    ease_dollars(i > 20 and 50 or 25)
                    delay(0.25)
                end
                return true
            end
        }))
    end
}
