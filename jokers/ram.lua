SMODS.Joker {
    key = "ram",
    config = {
        extra = {
            sell_value0 = 50
        }
    },
    loc_txt = {
        ['name'] = 'RAM',
        ['text'] = {
            'Gains {C:money}$50{} of {C:attention}sell value{} at end of round',
            'due to shortage of ram'
        },
        ['unlock'] = {
            ''
        }
    },
    pos = {
        x = 2,
        y = 0
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 200,
    rarity = 3,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'CustomJokers',

    calculate = function(self, card, context)
        if context.end_of_round and context.game_over == false and context.main_eval and not context.blueprint then
            return {
                func = function()
                    local my_pos = nil
                    for i = 1, #G.jokers.cards do
                        if G.jokers.cards[i] == card then
                            my_pos = i
                            break
                        end
                    end
                    local target_card = G.jokers.cards[my_pos]
                    target_card.ability.extra_value = (card.ability.extra_value or 0) + 50
                    target_card:set_cost()
                    return true
                end,
                message = "Prices Went Up"
            }
        end
    end
}
