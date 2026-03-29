---@class Mod
local mod = SMODS.current_mod

mod.commands.firesale = {
    can_exec = function(params)
        if not G.GAME.tags then
            return false
        end

        for _, tag in pairs(G.GAME.tags) do
            if tag.key == "tag_coupon" then
                return false
            end
        end

        return true
    end,
    exec = function(params)
        add_tag(G.P_TAGS.tag_coupon)

        attention_text({
            text = "NEXT SHOP IS FREE!",
            scale = 1,
            hold = 2,
            major = G.play,
            backdrop_colour = G.C.RED
        })
    end
}
