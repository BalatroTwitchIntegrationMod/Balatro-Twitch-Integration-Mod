---@class Mod
local mod = SMODS.current_mod

mod.commands.__default__ = {
    unprotected = true,
    no_cooldown = true,
    exec = function(params)
        if string.lower(params.text) == "f" then
            for _, joker in ipairs(SMODS.find_card("j_ttv_f")) do
                joker.config.center:apply_ban(joker, params.message.user_id)
            end
            return
        end

        local number = tonumber(string.match(params.text, "^[0-9]+$"))
        if number then
            for _, joker in ipairs(SMODS.find_card("j_ttv_copycat")) do
                joker.config.center:add_vote(joker, number, params.message.user_id)
            end
            return
        end

        if G.GAME.blind and G.GAME.blind.config.blind and G.GAME.blind.config.blind.run_command then
            G.GAME.blind.config.blind:run_command(G.GAME.blind, params.text)
        end
    end
}
