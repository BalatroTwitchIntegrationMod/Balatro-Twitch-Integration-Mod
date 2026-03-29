---@class Mod
local mod = SMODS.current_mod

mod.commands.shufflehand = {
    can_exec = function(params)
        if not G.hand or #G.hand.cards <= 0 then
            return false
        end

        return true
    end,
    exec = function(params)
        for i = 1, #G.hand.cards do
            G.hand.cards[i]:flip()

            G.hand:unhighlight_all()

            G.E_MANAGER:add_event(Event({
                trigger = "before",
                func = function()
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            G.hand:shuffle("aajk")
                            play_sound("card1", 0.85)
                            return true
                        end
                    }))

                    delay(0.15)

                    G.E_MANAGER:add_event(Event({
                        func = function()
                            G.hand:shuffle("aajk")
                            play_sound("card1", 1.15)
                            return true
                        end
                    }))

                    delay(0.15)

                    G.E_MANAGER:add_event(Event({
                        func = function()
                            G.hand:shuffle("aajk")
                            play_sound("card1", 1)
                            return true
                        end
                    }))

                    delay(0.15)

                    G.E_MANAGER:add_event(Event({
                        func = function()
                            G.hand.cards[i]:flip()
                            play_sound("card1", 1)
                            return true
                        end
                    }))

                    delay(0.05)

                    return true
                end
            }))
        end
    end
}

mod.commands.shufflejkrs = {
    can_exec = function(params)
        if #G.jokers.cards <= 0 then
            return false
        end

        return true
    end,
    exec = function(params)
        G.jokers:unhighlight_all()

        G.E_MANAGER:add_event(Event({
            trigger = "before",
            func = function()
                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.jokers:shuffle("aajk")
                        play_sound("cardSlide1", 0.85)
                        return true
                    end
                }))

                delay(0.15)

                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.jokers:shuffle("aajk")
                        play_sound("cardSlide1", 1.15)
                        return true
                    end
                }))

                delay(0.15)

                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.jokers:shuffle("aajk")
                        play_sound("cardSlide1", 1)
                        return true
                    end
                }))

                delay(0.5)

                return true
            end
        }))
    end
}
