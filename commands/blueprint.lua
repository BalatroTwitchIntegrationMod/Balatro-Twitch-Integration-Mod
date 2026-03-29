---@class Mod
local mod = SMODS.current_mod

mod.commands.blueprint = {
    can_exec = function(params)
        return G.jokers and true or false
    end,
    exec = function(params)
        local modifier = params.arg

        if #G.jokers.cards >= G.jokers.config.card_limit then
            modifier = "negative"
        end

        local card = create_card("Joker", G.jokers, nil, nil, nil, nil, "j_blueprint")

        attention_text({
            colour = G.C.WHITE,
            text = "BLUEPRINT!",
            scale = 1,
            hold = 2,
            major = G.jokers,
            backdrop_colour = G.C.BLUE
        })

        card:add_to_deck()

        G.jokers:emplace(card)

        if modifier == "foil" then
            card:set_edition({ foil = true }, true, true)
        elseif modifier == "holo" then
            card:set_edition({ holo = true }, true, true)
        elseif modifier == "poly" or modifier == "polychrome" then
            card:set_edition({ polychrome = true }, true, true)
        elseif modifier == "negative" then
            card:set_edition({ negative = true }, true, true)
        end

        card:juice_up(0.3, 0.5)

        play_sound("card1", 1)
    end
}
