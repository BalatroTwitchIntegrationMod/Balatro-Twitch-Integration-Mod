
SMODS.Consumable {
    key = '5050',
    set = 'Tarot',
    pos = { x = 0, y = 0 },
    config = {
        extra = {
            odds = 2
        }
    },
    loc_txt = {
        name = '50/50',
        text = {
            [1] = '{X:blue,C:white}50%{} (Ability)',
            [2] = '{X:blue,C:white}50%{} Crash the game'
        }
    },
    cost = 3,
    unlocked = true,
    discovered = true,
    hidden = false,
    can_repeat_soul = false,
    atlas = 'CustomConsumables',
    use = function(self, card, area, copier)
        local used_card = copier or card
        if SMODS.pseudorandom_probability(card, 'group_0_f5a4b0f7', 1, card.ability.extra.odds, 'c_ttv_5050', true) then
            local title = "Skill Issue Crash"
            local message = "LOL no. The game will now crash :)"
            local buttons = {"OK", escapebutton = 1}

            local pressedbutton = love.window.showMessageBox(title, message, buttons)
            error("Skill Issue Crash")
            delay(1.0)
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
            if pressedbutton == 1 then
                love.event.quit()
            end
        end
        }))
    end
    end,
    can_use = function(self, card)
        return true
    end
}