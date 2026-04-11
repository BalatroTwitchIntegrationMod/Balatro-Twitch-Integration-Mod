---@class Mod
local mod = SMODS.current_mod

mod.commands.randomjkr = {
    exec = function(params)
        local card = SMODS.add_card({ set = "Joker" })

        attention_text({
            colour = G.C.WHITE,
            text = "FREE JOKER!",
            scale = 1,
            hold = 2,
            major = G.jokers,
            backdrop_colour = G.C.RED
        })

        if #G.jokers.cards >= G.jokers.config.card_limit + 1 then
            card:set_edition({ negative = true }, true, true)
        end

        card:juice_up(0.3, 0.5)

        play_sound("card1", 1)
    end
}

mod.commands.tarot = {
    can_exec = function(params)
        return G.consumeables and true or false
    end,
    exec = function(params)
        SMODS.add_card({ set = "Tarot", no_edition = true })

        play_sound("card1", 1)
    end
}

mod.commands.planet = {
    can_exec = function(params)
        return G.consumeables and true or false
    end,
    exec = function(params)
        SMODS.add_card({ set = "Planet", no_edition = true })

        play_sound("card1", 1)
    end
}

mod.commands.spectral = {
    can_exec = function(params)
        return G.consumeables and true or false
    end,
    exec = function(params)
        SMODS.add_card({ set = "Spectral", no_edition = true })

        play_sound("card1", 1)
    end
}

mod.commands.soul = {
    can_exec = function(params)
        return G.consumeables and true or false
    end,
    exec = function(params)
        SMODS.add_card({ key = "c_ttv_thefakesoul", no_edition = true })
    end
}
