SMODS.Joker {
    key = "bulletroulette",
    config = {
        extra = {
            bullets = 0
        }
    },
    loc_txt = {
        ['name'] = 'R.N.G',
        ['text'] = {
            'Destroys the {C:attention}Joker{} to the',
            '{C:attention}right{} and adds {C:attention}+1{} Bullet. Then,',
            '{C:purple}life or death{}: {C:green}#1# in 6{} chance',
            'for {X:mult,C:white}X#3#{} Mult ({X:mult,C:white}X0.5{} per Bullet),',
            '{C:green}#2# in 6{} chance for {C:attention}-1{} Bullet,',
            '{C:blue}-1{} Hand.'
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
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                6 - card.ability.extra.bullets,
                card.ability.extra.bullets,
                card.ability.extra.bullets / 2 + 1
            }
        }
    end,
    cost = 4,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'RRJokerAnima',

    calculate = function(self, card, context)
        if context.cardarea == G.jokers then
            if context.pre_joker then
                if card.ability.extra.bullets == 6 then return end
                for i = 1, #G.jokers.cards do
                    if G.jokers.cards[i] == card then
                        if i < #G.jokers.cards then
                            SMODS.destroy_cards({G.jokers.cards[i + 1]})
                            card.ability.extra.bullets = card.ability.extra.bullets + 1
                            card.children.center.sprite_pos = {x = card.ability.extra.bullets, y = 0}
                            G.E_MANAGER:add_event(Event({
                                trigger = 'after',
                                delay = 0.4,
                                func = function()
                                    attention_text({
                                        text = "+1 Bullet",
                                        scale = 1.3,
                                        hold = 1.4,
                                        major = card,
                                        backdrop_colour = G.C.GOLD,
                                        align = 'cm',
                                        offset = {x = 0, y = 0}
                                    })
                                    play_sound("ttv_bullet_load")
                                    return true
                                end
                            }))
                            delay(0.6)
                        end
                        return
                    end
                end
            elseif context.joker_main then
                if card.ability.extra.bullets == 0 then return end
                if SMODS.pseudorandom_probability(card, "Bullet Roulette", 6 - card.ability.extra.bullets, 6, nil, true) then
                    return {
                        xmult = card.ability.extra.bullets / 2 + 1
                    }
                else
                    card.ability.extra.bullets = card.ability.extra.bullets - 1
                    card.children.center.sprite_pos = {x = card.ability.extra.bullets, y = 0}
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.4,
                        func = function()
                            attention_text({
                                text = "-1 Bullet",
                                scale = 1.3,
                                hold = 1.4,
                                major = card,
                                backdrop_colour = G.C.RED,
                                align = 'cm',
                                offset = {x = 0, y = 0}
                            })
                            play_sound("ttv_gun_fire")
                            return true
                        end
                    }))
                    delay(0.6)
                    if G.GAME.current_round.hands_left > 0 then
                        ease_hands_played(-1)
                        delay(0.6)
                    end
                end
            end
        end
    end
}
