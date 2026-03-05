
SMODS.Joker{
    key = "dinner",
    config = {
        extra = {
            currentmoney = 0,
            x_chips = 1
        }
    },
    loc_txt = {
        ['name'] = 'Dinner',
        ['text'] = {
            '{X:blue,C:white}X0.1{} Chips for each {C:money}$1{} you have',
            '{C:inactive}(Currently {}{X:blue,C:white}X#1#{} {C:inactive}Chips){}'
        },
    },
    pos = {
        x = 0,
        y = 0
    },
    display_size = {
        w = 71 * 1, 
        h = 95 * 1
    },
    cost = 6,
    rarity = 3,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'chipspin',
    
    loc_vars = function(self, info_queue, card)
        
        return {vars = {((G.GAME.dollars or 0)) * 0.1}}
    end,
    
    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main  then
            return {
                x_chips = (G.GAME.dollars) * 0.1
            }
        end
    end
}