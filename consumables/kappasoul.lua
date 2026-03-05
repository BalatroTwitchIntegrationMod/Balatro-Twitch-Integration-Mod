SMODS.Consumable {
    key = 'kappsoul',
    set = 'Spectral',
    pos = {x = 3, y = 0},
    loc_txt = {
        name = 'The Kappa\'s Soul',
        text = {
            'Creates a {C:spectral}Legendary{} {C:purple}Twitch{} Joker',
            '{C:inactive}(Must have room){}'
        }
    },
    cost = 4,
    unlocked = true,
    discovered = true,
    hidden = true,
    can_repeat_soul = false,
    atlas = 'CustomConsumables',
    soul_set = 'ttv_ttv_twitch_jokers',
    soul_rate = 0.13, -- find the sweat spot for spawn rate
    soul_pos = {
        x = 4,
        y = 0
    },
    use = function(self, card, area, copier)
        local used_card = copier or card
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('timpani')
                if #G.jokers.cards + G.GAME.joker_buffer < G.jokers.config.card_limit then
                    G.GAME.joker_buffer = G.GAME.joker_buffer + 1
                    local new_joker = SMODS.add_card({set = 'ttv_legendary_ttv_jokers', rarity = 'Legendary'})
                    if new_joker then
                    end
                    G.GAME.joker_buffer = 0
                end
                used_card:juice_up(0.3, 0.5)
                return true
            end
        }))
        delay(0.6)
    end,
    can_use = function(self, card)
        return true
    end
}
