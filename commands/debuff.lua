---@class Mod
local mod = SMODS.current_mod

mod.commands.debuff = {
    no_cooldown = true,
    can_exec = function(params)
        if G.GAME.blind.disabled then
            return false
        end

        if G.GAME.blind.in_blind and G.GAME.blind.config.blind.key ~= "bl_ttv_stream_sniper" then
            return false
        end

        local number = string.match(params.arg, "^[0-9]+$")

        if not number then
            return false
        end

        local i = tonumber(number)

        if not G.jokers or i <= 0 or i > #G.jokers.cards then
            return false
        end

        params.extra.card = G.jokers.cards[i]

        return true
    end,
    exec = function(params)
        for _, joker in ipairs(G.jokers.cards) do
            SMODS.debuff_card(joker, false, "ttv")
        end

        SMODS.debuff_card(params.extra.card, true, "ttv")

        params.extra.card:juice_up()

        G.GAME.blind:wiggle()
    end
}
