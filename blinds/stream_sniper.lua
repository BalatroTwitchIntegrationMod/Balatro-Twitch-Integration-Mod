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

    defeat = function(self)
        for _, joker in ipairs(G.jokers.cards) do
            SMODS.debuff_card(joker, false, "ttv")
        end
    end
}
