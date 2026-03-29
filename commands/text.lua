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
        if jimbo_chatter and not jimbo_chatter.removed then
            return false
        end

        return true
    end,
    exec = function(params)
        local config = G.STAGE == G.STAGES.MAIN_MENU and {
            x = 9, y = 3.15, speech_bubble_align = "bm"
        } or {
            x = 5, y = 3.5, speech_bubble_align = "cr"
        }

        jimbo_chatter = JimboChatter(config)

        jimbo_chatter:say(params.text)
    end
}
