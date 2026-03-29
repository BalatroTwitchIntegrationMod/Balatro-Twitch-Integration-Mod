---@class Mod
local mod = SMODS.current_mod

mod.commands.inflation = {
    can_exec = function(params)
        if not G.shop or G.STATE ~= G.STATES.SHOP then
            return false
        end

        return true
    end,
    exec = function(params)
        play_sound("coin1", 1.5, 0.7)

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
}
