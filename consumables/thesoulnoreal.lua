SMODS.Consumable {
    key = 'thefakesoul',
    set = 'Spectral',
    pos = {x = 0, y = 0},
    loc_txt = {
        name = 'The Soul',
        text = {
            'Creates a {C:spectral}Legendary{} Joker',
            '{C:inactive}(Must have room){}'
        }
    },
    cost = 4,
    unlocked = false,
    discovered = true,
    hidden = false,
    can_repeat_soul = false,
    atlas = 'CustomConsumables',
    use = function(self, card, area, copier)
        local used_card = copier or card
        G.E_MANAGER:add_event(Event({
            func = function()
                play_sound("ttv_fart_sound1")
                SMODS.calculate_effect({message = "PRANKED!"}, card)
                return true
            end
        }))
    end,
    no_mod_badge = true,
    no_collection = true,
    can_use = function(self, card)
        return true
    end
}
