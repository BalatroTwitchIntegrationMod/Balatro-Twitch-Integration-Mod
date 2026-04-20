SMODS.Consumable {
    key = 'dangerous',
    set = 'Tarot',
    pos = { x = 0, y = 0 },
    config = { extra = { odds = 10 } },
    loc_txt = {
        name = 'Dangerously',
        text = {
            '{C:green}#1# in #2#{} chance to get all {C:legendary}Legendary{} {C:attention}Jokers{}',
            'or',
            'Crash the game'
        }
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 5, card.ability.extra.odds, 'c_ttv_5050')
        return { vars = { numerator, denominator } }
    end,
    cost = 3,
    unlocked = true,
    discovered = true,
    hidden = false,
    can_repeat_soul = false,
    atlas = 'CustomConsumables',
    use = function(self, card, area, copier)
        if SMODS.pseudorandom_probability(card, 'group_0_f5a4b0f7', 5, card.ability.extra.odds, 'c_ttv_5050') then
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('timpani')
        for _, joker in pairs({ 'j_perkeo', 'j_chicot', 'j_yorick', 'j_triboulet' }) do
            local card = SMODS.add_card({ set = 'Joker', key = joker })
            if #G.jokers.cards >= G.jokers.config.card_limit then
                card:set_edition({ negative = true }, true, true)
            end
        end
                return true
        end
        }))
        else
            G.E_MANAGER:add_event(Event({
                        error("Skill Issue Crash")
                    }))
                end
            delay(0.6)
        end,
    can_use = function(self, card)
    return true
    end
}
