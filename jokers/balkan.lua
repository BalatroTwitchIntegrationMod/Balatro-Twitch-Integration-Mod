SMODS.Joker { --Balkan
    key = "balkan",
    config = {
        extra = {
            xchips0 = 2
        }
    },
    loc_txt = {
        ['name'] = 'Balkan',
        ['text'] = {
            'All played {C:orange}face{} cards',
            'gives {X:blue,C:white}X2{} Chips when scored'
        },
        ['unlock'] = {
            ''
        }
    },
    pos = {
        x = 1,
        y = 0
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 5,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'CustomJokers',

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card:is_face() then
                return {
                    x_chips = 2
                }
            end
        end
    end
}
