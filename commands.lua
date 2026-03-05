local chat_commands = {}
local mod = SMODS.Mods.twitchintegration

assert(SMODS.load_file("jimbo_chatter.lua"))()

-- TODO: make this separate
local whitelist = {chowder9o8 = true, jackmacwindows = true, korgeaux = true}

local last_destroy_time = 0

local function is_on_cooldown()
    local current_time = os.time()
    local mod = SMODS.Mods.twitchintegration
    local cooldown = 0

    if mod and mod.config and mod.config.cooldown_sec then
        cooldown = tonumber(mod.config.cooldown_sec) or cooldown
    end

    if current_time - (last_destroy_time or 0) < cooldown then
        return true
    end

    -- +/- 10% of random cooldown adjustment to avoid chatters calculating exact times
    last_destroy_time = current_time + (math.random() - 0.5) * (cooldown * 0.2)
    return false
end


function attention_text2(args)
    -- Replace copy_table with a dummy so we can modify the color after :)
    --It's broken gradiant text doesn't flash like it's supposed to :(
    local old_copy = copy_table
    function copy_table(o) return o end

    local ok, err = pcall(attention_text, args)
    copy_table = old_copy
    if not ok then error(err, 2) end
end

--This was a test command probably rework it to generate any joker
chat_commands.blueprint = function(modifier)
    if is_on_cooldown() then return end
    if G.STAGE == G.STAGES.RUN and G.jokers then
        if #G.jokers.cards >= G.jokers.config.card_limit then
            modifier = "negative"
        end
        local card = create_card('Joker', G.jokers, nil, nil, nil, nil, 'j_blueprint')
        attention_text({
            colour = G.C.WHITE,
            text = 'BLUEPRINT!',
            scale = 1,
            hold = 2,
            major = G.jokers,
            backdrop_colour = G.C.BLUE
        })
        card:add_to_deck()
        G.jokers:emplace(card)
        if modifier == "foil" then
            card:set_edition({foil = true}, true, true)
        elseif modifier == "holo" then
            card:set_edition({holo = true}, true, true)
        elseif modifier == "poly" or modifier == "polychrome" then
            card:set_edition({polychrome = true}, true, true)
        elseif modifier == "negative" then
            card:set_edition({negative = true}, true, true)
        end
        card:juice_up(0.3, 0.5)
        play_sound('card1', 1)
    end
end

chat_commands.destroy = function()
    if is_on_cooldown() then return end
    if G.STAGE == G.STAGES.RUN and G.jokers and #G.jokers.cards > 0 then
        local target = G.jokers.cards[math.random(#G.jokers.cards)]
        target:start_dissolve()
        attention_text({
            colour = G.C.WHITE,
            text = 'GONE!',
            scale = 1,
            hold = 2,
            major = G.jokers,
            backdrop_colour = G.C.PURPLE
        })
    end
end

---@type JimboChatter
local jimbo_chatter = nil
chat_commands.text = function(_, user, text_to_show)
    if not whitelist[user:lower()] then return end
    if not jimbo_chatter or jimbo_chatter.removed then
        jimbo_chatter = JimboChatter({x = 4.8, y = 3.4})
    end
    jimbo_chatter:say(text_to_show)
end

chat_commands.bankrupt = function()
    if is_on_cooldown() then return end
    if G.STAGE ~= G.STAGES.RUN then return end
    local current_dollars = G.GAME.dollars
    local difference = 0 - current_dollars
    ease_dollars(difference)
    attention_text({
        colour = G.C.WHITE,
        text = 'BANKRUPT!',
        scale = 1,
        hold = 2,
        major = G.play,
        backdrop_colour = G.C.BLACK
    })
    play_sound('ttv_BANKRUPT', 1, 1)
end

chat_commands.jackpot = function()
    if is_on_cooldown() then return end
    if G.STAGE ~= G.STAGES.RUN then return end
    attention_text2({
        colour = SMODS.Gradients['ttv_jackpot1'],
        text = 'JACKPOT!',
        scale = 1,
        hold = 11,
        major = G.play,
        backdrop_colour = SMODS.Gradients['ttv_jackpot2']
    })
    play_sound('ttv_jackpot', 1, 1)
    G.E_MANAGER:add_event(Event({
        func = function()
            for i = 1, 30 do
                ease_dollars(i > 20 and 50 or 25)
                delay(0.25)
            end
            return true
        end
    }))
end

chat_commands.inflation = function()
    if is_on_cooldown() then return end

    if G.STATE ~= G.STATES.SHOP or not G.shop then return end

    play_sound('coin1', 1.5, 0.7)

    if G.shop_jokers and G.shop_jokers.cards then
        for _, card in ipairs(G.shop_jokers.cards) do
            card.cost = card.cost + 5
        end
    end

    if G.shop_booster and G.shop_booster.cards then
        for _, card in ipairs(G.shop_booster.cards) do
            card.cost = card.cost + 5
        end
    end

    if G.shop_vouchers and G.shop_vouchers.cards then
        for _, card in ipairs(G.shop_vouchers.cards) do
            card.cost = card.cost + 5
        end
    end
end

chat_commands.alien = function()
    if is_on_cooldown() then return end
    pcall(function() play_sound('ttv_alien_gibberish', 1, 1) end)
    G.ROOM.jiggle = G.ROOM.jiggle + 25

    local atlas_data = G.ASSET_ATLAS["ttv_alien_overlay"]
    if not atlas_data then return end

    local screen_w = love.graphics.getWidth()
    local screen_h = love.graphics.getHeight()
    local target_h = screen_h * 0.6
    local scale_factor = target_h / atlas_data.py

    local random_x = math.random() * (screen_w - atlas_data.px * scale_factor)
    local random_y = math.random() * (screen_h - target_h)

    G.alien_jumpscare_active = {
        image = atlas_data.image,
        x = random_x,
        y = random_y,
        scale = scale_factor
    }

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 5,
        func = function()
            G.alien_jumpscare_active = nil
            return true
        end
    }))
end

chat_commands.fart = function()
    if is_on_cooldown() then return end
    pcall(function() play_sound('ttv_fart_sound1', 1, 1) end)
end

--Todo: Better name for commands
chat_commands.leveldown = function()
    if is_on_cooldown() then return end
    if G.STAGE ~= G.STAGES.RUN or not G.GAME then return end
    local triggered = false
    for key, hand in pairs(G.GAME.hands) do
        if hand.level > 0 then
            triggered = true
            level_up_hand(nil, key, true, -1)
        end
    end
    if triggered then
        play_sound('ttv_fart_sound1', 1)
    end
end

chat_commands.levelup = function()
    if is_on_cooldown() then return end
    if G.STAGE ~= G.STAGES.RUN or not G.GAME then return end
    SMODS.upgrade_poker_hands({level_up = 1})
    play_sound('ttv_fart_sound1', 1) -- maybe a different sound
end

chat_commands.soul = function()
    if is_on_cooldown() then return end
    if G.STAGE == G.STAGES.RUN and G.consumeables then
        SMODS.add_card({key = 'c_ttv_thefakesoul', no_edition = true})
    end
end

chat_commands.randomjkr = function()
    if is_on_cooldown then
        if G.STAGE ~= G.STAGES.RUN or not G.GAME then return end
    end
    local card = SMODS.add_card {set = 'Joker'}
    attention_text({colour = G.C.WHITE, text = 'FREE JOKER!', scale = 1, hold = 2, major = G.jokers, backdrop_colour = G.C.RED})
    if #G.jokers.cards >= G.jokers.config.card_limit + 1 then
        card:set_edition({negative = true}, true, true)
    end
    card:juice_up(0.3, 0.5)
    play_sound('card1', 1)
end

chat_commands.shufflejkrs = function(self, card, context)
    if G.STAGE ~= G.STAGES.RUN or not G.GAME then return end
    if #G.jokers.cards > 1 then
        G.jokers:unhighlight_all()
        G.E_MANAGER:add_event(Event({
            trigger = 'before',
            func = function()
                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.jokers:shuffle('aajk')
                        play_sound('cardSlide1', 0.85)
                        return true
                    end
                }))
                delay(0.15)
                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.jokers:shuffle('aajk')
                        play_sound('cardSlide1', 1.15)
                        return true
                    end
                }))
                delay(0.15)
                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.jokers:shuffle('aajk')
                        play_sound('cardSlide1', 1)
                        return true
                    end
                }))
                delay(0.5)
                return true
            end
        }))
    end
end


chat_commands.shufflehand = function()
    if G.STAGE == G.STAGES.RUN and G.hand then
        if #G.hand.cards then
            for i = 1, #G.hand.cards do
                G.hand.cards[i]:flip()
                play_sound('card1', 1)
                G.hand:unhighlight_all()
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    func = function()
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                G.hand:shuffle('aajk')
                                play_sound('card1', 0.85)
                                return true
                            end
                        }))
                        delay(0.15)
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                G.hand:shuffle('aajk')
                                play_sound('card1', 1.15)
                                return true
                            end
                        }))
                        delay(0.15)
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                G.hand:shuffle('aajk')
                                play_sound('card1', 1)
                                return true
                            end
                        }))
                        delay(0.15)
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                G.hand.cards[i]:flip()
                                play_sound('card1', 1)
                                return true
                            end
                        }))
                        delay(0.05)
                        return true
                    end
                }))
            end
        end
    end
end

chat_commands.destroycard = function()
    if is_on_cooldown() then return end
    local random = pseudorandom("ttv_830127", 1, #G.hand.cards)
    if G.STATE ~= G.STATES.SELECTING_HAND then return end
    if G.STAGE == G.STAGES.RUN and G.hand then
        if #G.hand.cards > 0 then
            SMODS.destroy_cards(G.hand.cards[random], nil, nil)
            attention_text({text = 'YOINK!', scale = 1, hold = 2, major = G.play, backdrop_colour = G.C.RED})
            play_sound('ttv_fart_sound1', 1)
        end
    end
end


--Split these commands up
chat_commands.tarot = function()
    if is_on_cooldown() then return end
    if G.STAGE == G.STAGES.RUN and G.consumeables then
        SMODS.add_card({set = "Tarot", no_edition = true})
        play_sound('card1', 1)
    end
end

chat_commands.planet = function()
    if is_on_cooldown() then return end
    if G.STAGE == G.STAGES.RUN and G.consumeables then
        SMODS.add_card({set = "Planet", no_edition = true})
        play_sound('card1', 1)
    end
end

chat_commands.spectral = function()
    if is_on_cooldown() then return end
    if G.STAGE == G.STAGES.RUN and G.consumeables then
        SMODS.add_card({set = "Spectral", no_edition = true})
        play_sound('card1', 1)
    end
end

chat_commands.bomb = function(arg, user)
    if not arg:match "^%d%d%d%d$" then return end
    if is_on_cooldown() then return end
    if #SMODS.find_card('j_ttv_bomb') == 1 then return end
    if G.STAGE == G.STAGES.RUN and G.jokers then
        play_sound('ttv_bomb_plant', 1, 1)
        local card = SMODS.add_card({key = 'j_ttv_bomb', no_edition = true})
        card.ability.extra.number = tonumber(arg) or math.random(0, 9999) -- just in case
        attention_text({text = user .. ' planted a bomb!', scale = 0.5, hold = G.SPEEDFACTOR * 1.2, major = card, offset = {x = 0, y = 1.5}, backdrop_colour = G.C.RED})
    end
end

chat_commands.banana = function()
    if is_on_cooldown() then return end
    local RanSet = {"j_gros_michel", "j_cavendish"}
    local RanSelect = math.random(#RanSet)
    local RanCreate = RanSet[RanSelect]
    local random = pseudorandom("ttv_389201", 1, #G.jokers.cards)

    if G.STAGE == G.STAGES.RUN and G.jokers then
        if #G.jokers.cards > 0 then
            G.jokers.cards[random]:set_ability(G.P_CENTERS[RanCreate])
        end
    end
end

chat_commands.enhance = function()
    if is_on_cooldown() then return end
    if G.STATE ~= G.STATES.SELECTING_HAND then return end
    if G.STAGE == G.STAGES.RUN and G.hand then
        for i = 1, #G.hand.cards do
            G.hand.cards[i]:flip()
        end
        attention_text2({colour = SMODS.Gradients['ttv_ehancing'], text = 'CARDS ARE BEING ENHANCED!', scale = 1, hold = 4, major = G.play, backdrop_colour = SMODS.Gradients['ttv_ehancing2']})
        play_sound('card1', 1)
        G.E_MANAGER:add_event(Event({
            func = function()
                local RanSet = {"ttv_merasmus1", "ttv_merasmus2", 'ttv_merasmus3', 'ttv_merasmus4', 'ttv_merasmus5',
                    'ttv_merasmus6', "ttv_merasmus7", "ttv_merasmus8", 'ttv_merasmus9', 'ttv_merasmus10',
                    'ttv_merasmus11'}
                local RanSelect = math.random(#RanSet)
                local RanCreate = RanSet[RanSelect]
                G.hand:unhighlight_all()
                for k, v in pairs(G.hand.cards) do
                    v:set_ability(SMODS.poll_enhancement({guaranteed = true}))
                    G.hand:shuffle('aajk')
                    play_sound('card1', 0.85)
                    play_sound(RanCreate)
                    play_sound('ttv_magic')
                    return true
                end
            end
        }))
        if #G.hand.cards > 1 then
            G.E_MANAGER:add_event(Event({
                trigger = 'before',
                func = function()
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            play_sound('card1', 1)
                            G.hand:unhighlight_all()
                            for k, v in pairs(G.hand.cards) do
                                v:set_ability(SMODS.poll_enhancement({guaranteed = true}))
                                G.hand:shuffle('aajk')
                                play_sound('card1', 0.85)
                                return true
                            end
                        end
                    }))
                    delay(0.15)
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            G.hand:shuffle('aajk')
                            for k, v in pairs(G.hand.cards) do
                                v:set_ability(SMODS.poll_enhancement({guaranteed = true}))
                                play_sound('card1', 1.15)
                                return true
                            end
                        end
                    }))
                    delay(0.15)
                    for _ = 1, 5 do
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                G.hand:shuffle('aajk')
                                for k, v in pairs(G.hand.cards) do
                                    v:set_ability(SMODS.poll_enhancement({guaranteed = true}))
                                    play_sound('card1', 1)
                                    return true
                                end
                            end
                        }))
                        delay(0.15)
                    end
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            G.hand:shuffle('aajk')
                            for k, v in pairs(G.hand.cards) do
                                v:set_ability(SMODS.poll_enhancement({guaranteed = true}))
                                play_sound('card1', 1)
                                for i = 1, #G.hand.cards do
                                    if G.hand.cards[i].facing == 'back' then
                                        G.hand.cards[i]:flip()
                                    end
                                end
                            end
                            return true
                        end
                    }))
                    return true
                end
            }))
        end
    end
end

chat_commands.firesale = function()
    if is_on_cooldown() then return end
    if G.STAGE ~= G.STAGES.RUN then return end
    if G.STAGE == G.STAGES.RUN and G.jokers then
        add_tag({key = 'tag_coupon'})
        attention_text({text = 'NEXT SHOP IS FREE!', scale = 1, hold = 2, major = G.play, backdrop_colour = G.C.RED})
    end
end

chat_commands.blind = function()
    if is_on_cooldown() then return end
    if G.STAGE ~= G.STAGES.RUN then return end
    if SMODS.Mods.twitchintegration.flashlight_on == false then
        SMODS.Mods.twitchintegration.flashlight_on = true
        attention_text({colour = G.C.GREY, text = 'BLINDED FOR 30 SECONDS!', scale = 1, hold = 11, major = G.play, backdrop_colour = G.C.BLACK})
    end
    play_sound('ttv_flashlight')
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        blocking = false,
        delay = G.SPEEDFACTOR * (24.5),
        func = function()
            if SMODS.Mods.twitchintegration.flashlight_on == true then
                SMODS.Mods.twitchintegration.flashlight_on = false
                play_sound('ttv_flashlight')
            end
            return true
        end
    }))
end

chat_commands.agga = function()
    if is_on_cooldown() then return end
    mod.glitch = 30
end

return chat_commands
