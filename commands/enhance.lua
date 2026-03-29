---@class Mod
local mod = SMODS.current_mod

mod.commands.enhance = {
    can_exec = function(params)
        if G.STATE ~= G.STATES.SELECTING_HAND or not G.hand or #G.hand.cards < 1 then
            return false
        end

        return true
    end,
    exec = function(params)
        for i = 1, #G.hand.cards do
            G.hand.cards[i]:flip()
        end

        attention_text({
            colour = SMODS.Gradients["ttv_ehancing"],
            text = "CARDS ARE BEING ENHANCED!",
            scale = 1,
            hold = 4,
            major = G.play,
            backdrop_colour = SMODS.Gradients["ttv_ehancing2"]
        })

        play_sound("card1", 1)

        G.E_MANAGER:add_event(Event({
            func = function()
                G.hand:unhighlight_all()

                for _, card in pairs(G.hand.cards) do
                    card:set_ability(SMODS.poll_enhancement({ guaranteed = true }))

                    G.hand:shuffle("aajk")

                    play_sound("card1", 0.85)
                    play_sound("ttv_merasmus" .. math.random(1, 12))
                    play_sound("ttv_magic")

                    return true
                end
            end
        }))

        if #G.hand.cards <= 1 then
            return
        end

        G.E_MANAGER:add_event(Event({
            trigger = "before",
            func = function()
                G.E_MANAGER:add_event(Event({
                    func = function()
                        play_sound("card1", 1)

                        G.hand:unhighlight_all()

                        for _, card in pairs(G.hand.cards) do
                            card:set_ability(SMODS.poll_enhancement({ guaranteed = true }))
                            G.hand:shuffle("aajk")
                            play_sound("card1", 0.85)
                        end

                        return true
                    end
                }))

                delay(0.15)

                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.hand:shuffle("aajk")

                        for _, card in pairs(G.hand.cards) do
                            card:set_ability(SMODS.poll_enhancement({ guaranteed = true }))
                            play_sound("card1", 1.15)
                        end

                        return true
                    end
                }))

                delay(0.15)

                for _ = 1, 5 do
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            G.hand:shuffle("aajk")

                            for _, card in pairs(G.hand.cards) do
                                card:set_ability(SMODS.poll_enhancement({ guaranteed = true }))
                                play_sound("card1", 1)
                            end

                            return true
                        end
                    }))

                    delay(0.15)
                end

                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.hand:shuffle("aajk")

                        for _, card in pairs(G.hand.cards) do
                            card:set_ability(SMODS.poll_enhancement({ guaranteed = true }))

                            play_sound("card1", 1)

                            for i = 1, #G.hand.cards do
                                if G.hand.cards[i].facing == "back" then
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
}
