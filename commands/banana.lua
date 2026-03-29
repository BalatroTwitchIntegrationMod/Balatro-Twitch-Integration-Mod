---@class Mod
local mod = SMODS.current_mod

mod.commands.banana = {
    can_exec = function(params)
        return G.jokers and #G.jokers.cards >= 1 or false
    end,
    exec = function(params)
        local set = { "j_gros_michel", "j_cavendish" }
        local select = math.random(#set)
        local banana = set[select]

        local random = pseudorandom("ttv_389201", 1, #G.jokers.cards)

        local joker = G.jokers.cards[random]

        joker:set_ability(G.P_CENTERS[banana], nil, true)

        joker:juice_up()

        card_eval_status_text(joker, "jokers", nil, nil, nil, {
            color = G.C.YELLOW,
            message = "Banana!",
            sound = "ttv_fart_sound1"
        })
    end
}
