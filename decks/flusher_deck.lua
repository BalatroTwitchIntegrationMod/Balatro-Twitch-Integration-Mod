SMODS.Back {
    key = 'flusher_deck',
    pos = {x = 1, y = 0},
    config = {
    },
    loc_txt = {
        name = 'FLUSHER DECK',
        text = {
            'THE ALL MIGHTY FLUSHER!',
            '{E:1}All cards are {C:hearts}hearts{}.{}',
            '{E:1}Blind scores increased by {X:blue,C:white}x2{}{}'
        }
    },
    unlocked = true,
    discovered = true,
    no_collection = false,
    atlas = 'CustomDecks',
    apply = function(self, back)
        G.E_MANAGER:add_event(Event({
            func = function()
                for k, v in pairs(G.playing_cards) do
                    if v.base.suit == 'Spades' or v.base.suit == 'Diamonds' or v.base.suit == 'Clubs' then
                        assert(SMODS.change_base(v, 'Hearts'))
                    end
                end
                G.GAME.starting_deck_size = #G.playing_cards
                return true
            end
        }))
        G.E_MANAGER:add_event(Event({
            func = function()
                G.GAME.starting_params.ante_scaling = G.GAME.starting_params.ante_scaling * 2
                return true
            end
        }))
    end
}
