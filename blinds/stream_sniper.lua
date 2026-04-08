---@class Mod
local mod = SMODS.current_mod

SMODS.Blind {
    key = "stream_sniper",
    loc_txt = {
        name = "Stream Sniper",
        text = {
            "One Joker is disabled at random",
            "by Twitch viewers,",
        },
        unlock = { "Unlocked by default." }
    },
    atlas = "stream_sniper",
    discovered = true,
    dollars = 8,
    mult = 2,
    pos = { x = 0, y = 0 },
    boss = { showdown = true },
    boss_colour = HEX("69359c"),

    disable = function(self)
        for _, joker in ipairs(G.jokers.cards) do
            SMODS.debuff_card(joker, false, "ttv")
        end
        if G.GAME.blind and G.GAME.blind.ttv_help then
            G.GAME.blind.ttv_help:remove()
        end
    end,

    defeat = function(self)
        for _, joker in ipairs(G.jokers.cards) do
            SMODS.debuff_card(joker, false, "ttv")
        end
        if G.GAME.blind and G.GAME.blind.ttv_help then
            G.GAME.blind.ttv_help:remove()
        end
    end
}

mod.hook:add(function(dt)
    if not (G.GAME and G.GAME.blind and G.GAME.blind.config.blind.key == "bl_ttv_stream_sniper") then
        return
    end

    if G.GAME.blind and not G.GAME.blind.ttv_help and not G.GAME.blind.disabled then
        G.GAME.blind.ttv_help = TTVPlayAreaHelp({ jokers = "!debuff #" })
    end
end)
