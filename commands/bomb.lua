---@class Mod
local mod = SMODS.current_mod

mod.commands.bomb = {
    can_exec = function(params)
        if not G.jokers then
            return false
        end

        if not string.match(params.arg, "^%d%d%d%d$") then
            return false
        end

        if #SMODS.find_card("j_ttv_bomb") > 0 then
            return false
        end

        return true
    end,
    exec = function(params)
        local card = SMODS.add_card({ key = "j_ttv_bomb", no_edition = true })

        card.ability.extra.code_text = params.arg
        card.ability.extra.user_name = params.message.user_login

        attention_text({
            text = params.message.user_name .. " planted a bomb!",
            scale = 0.5,
            hold = G.SPEEDFACTOR * 1.2,
            major = card,
            offset = { x = 0, y = 1.5 },
            backdrop_colour = G.C.RED
        })

        play_sound("ttv_bomb_plant", 1, 1)
    end
}
