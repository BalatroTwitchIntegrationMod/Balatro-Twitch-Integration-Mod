SMODS.Joker {
    key = "clown",
    config = {
        extra = {
        }
    },
    loc_txt = {
        ['name'] = 'Clown',
        ['text'] = {
            '{C:chips}+4{} Chips'
        },
        ['unlock'] = {
            ''
        }
    },
    pos = {
        x = 8,
        y = 0
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 0,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'CustomJokers',

    set_ability = function(self, card, initial)
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main then
            return {
                chips = 10
            }
        end
    end
}
