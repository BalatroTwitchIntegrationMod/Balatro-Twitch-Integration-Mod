SMODS.Blind {
    key = "me",
    loc_txt = {
        name = "Twitch Plays Balatro",
        text = {
            "Streamer back up,",
            "CHATTERS play for you :)",
        },
        unlock = { "Unlocked by default." }
    },
    atlas = "me",
    discovered = true,
    dollars = 5,
    mult = 0.1,
    pos = { x = 0, y = 0 },
    boss = { min = 1, max = 10 },
    boss_colour = HEX("69359c"),

    run_command = function(self, blind, text)
        local cmd, card, action = string.match(text, "^([cdhjps])([0-9]*)([rsuo]?)$")

        card = tonumber(card)

        G.E_MANAGER:add_event(Event({
            func = function()
                local can_play = not (#G.hand.highlighted <= 0 or G.GAME.blind.block_play or #G.hand.highlighted > math.max(G.GAME.starting_params.play_limit, 1))
                local can_discard = not (G.GAME.current_round.discards_left <= 0 or #G.hand.highlighted <= 0 or #G.hand.highlighted > math.max(G.GAME.starting_params.discard_limit, 0))

                if cmd == "p" and can_play then
                    G.FUNCS.play_cards_from_highlighted()
                elseif cmd == "d" and can_discard then
                    G.FUNCS.discard_cards_from_highlighted()
                elseif cmd == "j" and card and card <= #G.jokers.cards then
                    local j = G.jokers.cards[card]
                    if action == "" then
                        j:click()
                    elseif action == "s" and j:can_sell_card() then
                        j:sell_card()
                    end
                elseif cmd == "c" and card and card <= #G.consumeables.cards then
                    local c = G.consumeables.cards[card]
                    if action == "" then
                        c:click()
                    elseif action == "u" and c:can_use_consumeable() then
                        c:use_consumeable(c.area)
                    elseif action == "s" and c:can_sell_card() then
                        c.area:remove_card(c)
                        c:sell_card()
                    end
                elseif cmd == "h" and card and card <= #G.hand.cards then
                    G.hand.cards[card]:click()
                elseif cmd == "s" then
                    if action == "r" then
                        G.FUNCS.sort_hand_value({})
                    elseif action == "o" then
                        G.FUNCS.sort_hand_suit({})
                    end
                end
                return true
            end
        }))
    end
}
