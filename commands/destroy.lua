---@class Mod
local mod = SMODS.current_mod

mod.commands.destroyjkr = {
    can_exec = function(params)
        if not G.jokers or #G.jokers.cards <= 0 then
            return false
        end

        return true
    end,
    exec = function(params)
        local target = G.jokers.cards[math.random(#G.jokers.cards)]

        target:start_dissolve()

        attention_text({
            colour = G.C.WHITE,
            text = "GONE!",
            scale = 1,
            hold = 2,
            major = G.jokers,
            backdrop_colour = G.C.PURPLE
        })
    end
}

mod.commands.destroycard = {
    can_exec = function(params)
        if not G.hand or G.STATE ~= G.STATES.SELECTING_HAND then
            return false
        end

        if #G.hand.cards <= 0 then
            return false
        end

        return true
    end,
    exec = function(params)
        local random = pseudorandom("ttv_830127", 1, #G.hand.cards)

        SMODS.destroy_cards(G.hand.cards[random], nil, nil)

        attention_text({
            text = "YOINK!",
            scale = 1,
            hold = 2,
            major = G.play,
            backdrop_colour = G.C.RED
        })

        play_sound("ttv_fart_sound1", 1)
    end
}
