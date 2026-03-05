SMODS.Joker {
    key = "monkey",
    config = {
        extra = {
            xmultvar = 1
        }
    },
    loc_txt = {
        ['name'] = 'Monkey',
        ['text'] = {
            'Monkey gains {X:red,C:white}X2{} Mult for every',
            '{C:attention}Gros Michel{} eaten',
            '& {X:red,C:white}X4{} for every {C:attention}Cavendish',
            '{C:inactive}(Currently {X:red,C:white}X#1#{} Mult){}'
        },
        ['unlock'] = {
            ''
        }
    },
    pos = {
        x = 6,
        y = 0
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 7,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'CustomJokers',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.xmultvar}}
    end,

    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            G.E_MANAGER:add_event(Event({
                func = function()
                    play_sound("ttv_dkbanana")

                    return true
                end
            }))
            return {
                func = function() --This is spagetti code but it works LOL
                    if #SMODS.find_card('j_cavendish') == 1 then
                        card.ability.extra.xmultvar = (card.ability.extra.xmultvar) + 4
                    elseif #SMODS.find_card('j_gros_michel') == 1 then
                        card.ability.extra.xmultvar = (card.ability.extra.xmultvar) + 2
                    end
                    return true
                end,
                extra = {
                    func = function()
                        for i, joker in ipairs(G.jokers.cards) do
                            if (joker.config.center.key == "j_cavendish" or joker.config.center.key == "j_gros_michel") and not SMODS.is_eternal(joker) and not joker.getting_sliced then
                                joker.getting_sliced = true
                                G.E_MANAGER:add_event(Event({
                                    func = function()
                                        joker:start_dissolve({G.C.RED}, nil, 1.6)
                                        return true
                                    end
                                }))
                                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = "Eaten!", colour = G.C.RED})
                                break
                            end
                        end
                        return true
                    end,
                    colour = G.C.RED
                }
            }
        end
        if context.cardarea == G.jokers and context.joker_main then
            return {
                xmult = card.ability.extra.xmultvar
            }
        end
    end
}
