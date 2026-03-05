SMODS.Joker { --NAME PENDING
    key = "monkey2",
    config = {
        extra = {
            odds = 4
        }
    },
    loc_txt = {
        ['name'] = 'Chimpanzee',
        ['text'] = {
            '{C:green}1 in 4{} chance to add a {C:attention}Gros Michel{}'
        },
        ['unlock'] = {
            'Unlocked by default.'
        }
    },
    pos = {
        x = 1,
        y = 1
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 4,
    rarity = 1,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'CustomJokers',

    loc_vars = function(self, info_queue, card)
        local new_numerator, new_denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds,
            'j_ttv_monkey2')
        return {vars = {new_numerator, new_denominator}}
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main and not context.blueprint then
            if true then
                if SMODS.pseudorandom_probability(card, 'group_0_bb5c2b5b', 1, card.ability.extra.odds, 'j_ttv_monkey2', false) then
                    local created_joker = false
                    if #G.jokers.cards + G.GAME.joker_buffer < G.jokers.config.card_limit then
                        created_joker = true
                        G.GAME.joker_buffer = G.GAME.joker_buffer + 1
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                local joker_card = SMODS.add_card({set = 'Joker', key = 'j_gros_michel'})
                                if joker_card then

                                end
                                G.GAME.joker_buffer = 0
                                return true
                            end
                        }))
                    end
                    card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil,
                        {message = created_joker and localize('k_plus_joker') or nil, colour = G.C.BLUE})
                end
            end
        end
    end
}
