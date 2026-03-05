SMODS.Edition {
    key = 'bootleg',
    shader = 'holo',
    prefix_config = {
        shader = false
    },
    config = {
        extra = {
            odds = 8  --set to 1 for testing
        }
    },
    in_shop = true,
    extra_cost = -10,
    apply_to_float = false,
    sound = {sound = "ttv_fart_sound1", per = 1.2, vol = 0.4},
    disable_shadow = false,
    disable_base_shader = false,
    loc_txt = {
        name = 'Bootleg',
        label = 'Bootleg',
        text = {
            [1] = '{C:green}1 in 8{} chance to fail'
        }
    },
    unlocked = true,
    discovered = true,
    no_collection = false,
    get_weight = function(self)
        return G.GAME.edition_rate * self.weight
    end,

    calculate = function(self, card, context) --change from debuff to failed proc if possible
        if context.pre_joker or (context.main_scoring and context.cardarea == G.play) then
            if SMODS.pseudorandom_probability(card, 'e_ttv_bootleg', 1, card.edition.extra.odds) then
                card:set_debuff(true)
                card_eval_status_text(card, 'extra', nil, nil, nil, {message = "Broken!", colour = G.C.RED})
                play_sound('tarot2', 0.76, 0.4)
            else
                if G.STATE == G.STATES.NEW_ROUND and card.disabled and card.area ~= G.jokers then
                    card:set_debuff(false)
                end
            end
        end
    end
}
