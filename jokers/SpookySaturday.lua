local date = os.date("%A")

SMODS.Joker{
    key = "Spooky Saturday",
    config = {
        extra = {
            xmult = 100,
        }
    },
    loc_txt = {
        ['name'] = 'Spooky Saturday',
        ['text'] = {
            'Gives {X:red,C:white}X100{} Mult on {C:blue}Saturdays{},',
            '{C:inactive}The current day of the week is: {C:blue}' .. date .. '{}{}.'
        },
        ['unlock'] = {
            'Unlocked by default.'
        }
    },
    pos = {
        x = 0,
        y = 0
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
    atlas = 'SpookySaturday',
    
    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main  then
            print(os.date("%w")) -- local date
            if os.date("%w") == "6" then
                return {
                    xmult = 100
                }
            end
        end
    end
}