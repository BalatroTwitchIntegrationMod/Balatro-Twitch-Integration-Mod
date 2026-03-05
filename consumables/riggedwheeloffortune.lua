SMODS.Consumable {
    key = 'riggedwheeloffortune',
    set = 'Tarot',
    pos = {x = 0, y = 1},
    loc_txt = {
        name = 'The Wheel of Fortune (buffed)',
        text = {
            "{C:green}1 in 3{} chance to add",
            "{C:dark_edition}Foil{}, {C:dark_edition}Holographic{}, or",
            "{C:dark_edition}Polychrome{} edition",
            "to a random {C:attention}Joker"
        }
    },
    cost = 3,
    unlocked = true,
    discovered = true,
    hidden = false,
    atlas = 'Tarot',
    prefix_config = {atlas = false},
    generate_ui = function(self, info_queue, card, desc_nodes, specific_vars, full_UI_table)
        SMODS.Consumable.generate_ui(self, info_queue, card, desc_nodes, specific_vars, full_UI_table)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_foil
        info_queue[#info_queue + 1] = G.P_CENTERS.e_holo
        info_queue[#info_queue + 1] = G.P_CENTERS.e_polychrome
    end,
    use = function(self, card, area, copier)
        local used_card = copier or card
        G.E_MANAGER:add_event(Event {trigger = 'after', delay = 0.4, func = function()
            attention_text({
                text = localize('k_nope_ex'),
                scale = 1.3,
                hold = 1.4,
                major = used_card,
                backdrop_colour = G.C.SECONDARY_SET.Tarot,
                align = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and 'tm' or 'cm',
                offset = {x = 0, y = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and -0.2 or 0},
                silent = true
            })
            G.E_MANAGER:add_event(Event {trigger = 'after', delay = 0.06 * G.SETTINGS.GAMESPEED, blockable = false, blocking = false, func = function()
                play_sound('tarot2', 0.76, 0.4)
                return true
            end})
            play_sound('tarot2', 1, 0.4)
            used_card:juice_up(0.3, 0.5)
            return true
        end})
        delay(0.6)
    end,
    can_use = function(self, card)
        for k, v in pairs(G.jokers.cards) do
            if v.ability.set == 'Joker' and (not v.edition) then
                return true
            end
        end
        return false
    end
}
