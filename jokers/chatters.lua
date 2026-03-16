---@type Mod
local mod = SMODS.current_mod

SMODS.Joker {
    key = "chatters",
    config = {
        extra = {
            chips = 0,
            scaling = 0.1
        }
    },
    loc_txt = {
        ["name"] = "Chatters",
        ["text"] = {
            "Gain {C:blue}+#1#{} Chip per viewer.",
            "{C:inactive}(Currently{} {C:blue}+#2#{} {C:inactive}chips){}"
        },
        ["unlock"] = {
            "Unlocked by default."
        }
    },
    pos = {
        x = 5,
        y = 0
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = "CustomJokers",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.scaling,
                (card.added_to_deck and card.ability.extra.chips or mod.viewer_count) * card.ability.extra.scaling
            }
        }
    end,
    add_to_deck = function(self, card, from_debuff)
        card.ability.extra.chips = mod.viewer_count
    end,
    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main then
            return {
                chips = card.ability.extra.chips * card.ability.extra.scaling
            }
        end
    end,
    set_chips = function(self, card, chips)
        card.ability.extra.chips = chips
    end
}
