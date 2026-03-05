SMODS.Joker {
    key = "happycat",
    config = {
        extra = {
            xChips = 1
        }
    },
    loc_txt = {
        ['name'] = 'Happy Cat',
        ['text'] = {
            'This Joker gains {X:chips,C:white}X0.25{} Chips every',
            'time a {C:attention}Bonus{} card {C:green}successfully{} triggers',
            '{C:inactive}(Currently {X:chips,C:white}X#1#{} Chips){}'
        },
        ['unlock'] = {
            ''
        }
    },
    pos = {
        x = 9,
        y = 0
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 1,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'CustomJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.xChips}}
    end,

    set_ability = function(self, card, initial)
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and SMODS.get_enhancements(context.other_card)["m_bonus"] == true and not context.blueprint then
            card.ability.extra.xChips = (card.ability.extra.xChips) + 0.25
        end
        if context.cardarea == G.jokers and context.joker_main then
            return {
                x_chips = card.ability.extra.xChips
            }
        end
    end
}
