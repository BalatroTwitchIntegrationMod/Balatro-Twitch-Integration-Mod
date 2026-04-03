---@class Mod
local mod = SMODS.current_mod

assert(SMODS.load_file("custom/jimbo_chatter.lua"))()

local jimbo_chatter = nil ---@type JimboChatter?

mod.commands.text = {
    anywhere = true,
    restricted = true,
    unprotected = true,
    no_cooldown = true,
    can_exec = function(params)
        return not (jimbo_chatter and jimbo_chatter.talking)
    end,
    exec = function(params)
        local config = G.STAGE == G.STAGES.MAIN_MENU and {
            x = 9, y = 3.15, speech_bubble_align = "bm"
        } or {
            x = 5, y = 3.5, speech_bubble_align = "cr"
        }

        if jimbo_chatter then
            jimbo_chatter:remove()
        end

        jimbo_chatter = JimboChatter(config)

        jimbo_chatter:say(params.text)
    end
}
