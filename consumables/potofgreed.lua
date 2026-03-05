SMODS.Consumable {
    key = 'potofgreed',
    set = 'Tarot',
    pos = {x = 2, y = 0},
    loc_txt = {
        name = 'Pot Of Greed',
        text = {
            'Draw 2 cards.'
        }
    },
    cost = 3,
    unlocked = true,
    discovered = true,
    hidden = false,
    can_repeat_soul = false,
    atlas = 'CustomConsumables',
    select_card = 'consumeables',
    use = function(self, card, area, copier)
        SMODS.draw_cards(2)
    end,
    can_use = function(self, card)
        return (G.GAME.blind.in_blind) and (G.hand and #G.hand.cards > 0)
    end
}
