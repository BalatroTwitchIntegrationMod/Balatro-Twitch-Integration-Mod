SMODS.Joker {
    key = "mods",
    config = {
        extra = {
            protections = 5,
            change = 1
        }
    },
    loc_txt = {
        ["name"] = "Mods",
        ["text"] = {
            "Protect from incoming {C:purple}Twitch{} commands!",
            "{C:tarot}chat members{} will get a",
            "{C:red}timeout{} for 1 minute to remove protections.",
            "{C:inactive}(Currently{} {C:red}#1#{} {C:inactive}Protections Remaining){}"
        },
        ["unlock"] = {
            "Unlocked by default."
        }
    },
    pos = {
        x = 2,
        y = 1
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 6,
    rarity = 3,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = "CustomJokers",
    pools = {
        ["ttv_ttv_jokers"] = true
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.protections
            }
        }
    end,
    decrease_protections = function(self, card)
        SMODS.scale_card(card, {
            ref_table = card.ability.extra,
            ref_value = "protections",
            scalar_value = "change",
            operation = '-',
            scaling_message = {
                message = "Protected!",
                colour = G.C.GREEN
            }
        })

        if card.ability.extra.protections <= 0 then
            SMODS.destroy_cards(card)
        end
    end
}
