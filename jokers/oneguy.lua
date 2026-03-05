
SMODS.Joker{
    key = "oneguy",
    config = {
       extra = {
            mult0 = 1,
            chips0 = 1,
            dollars0 = 1
        }
    },
    loc_txt = {
        ['name'] = 'One Guy',
        ['text'] = {
            '{C:mult}+1{} Mult',
            '{C:blue}+1{} Chip',
            '{C:money}+$1{} Dollar',
            'For each {C:attention}Ace{} scored'
        },
        ['unlock'] = {
            'Unlocked by default.'
        }
    },
    pos = {
        x = 5,
        y = 1
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 4,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'CustomJokers',
    
calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play  then
            if context.other_card:get_id() == 14 then
                return {
                    mult = 1,
                    extra = {
                        chips = 1,
                        colour = G.C.CHIPS,
                        extra = {
                            func = function()
                                local current_dollars = G.GAME.dollars
                                local target_dollars = G.GAME.dollars + 1
                                local dollar_value = target_dollars - current_dollars
                                ease_dollars(dollar_value)
                                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = "+"..tostring(1), colour = G.C.MONEY})
                                return true
                            end,
                            colour = G.C.MONEY
                        }
                    }
                }
            end
        end
    end
}