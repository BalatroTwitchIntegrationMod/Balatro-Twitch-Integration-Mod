SMODS.Back {
    key = 'twitch_deck',
    pos = {x = 0, y = 0},
    config = {
    },
    loc_txt = {
        name = 'Twitch Deck',
        text = {
            'Start A run with 1 {C:tarot}Twitch{} related {C:attention}joker{}'
        }
    },
    unlocked = true,
    discovered = true,
    no_collection = false,
    atlas = 'CustomDecks',
    apply = function(self, back)
        G.E_MANAGER:add_event(Event({
            func = function()
                play_sound('timpani')
                if #G.jokers.cards + G.GAME.joker_buffer < G.jokers.config.card_limit then
                    G.GAME.joker_buffer = G.GAME.joker_buffer + 1
                    SMODS.add_card({set = 'ttv_ttv_twitch_jokers'})
                    G.GAME.joker_buffer = 0
                end
                return true
            end
        }))
    end
}
