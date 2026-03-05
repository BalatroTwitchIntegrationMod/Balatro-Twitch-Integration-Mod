SMODS.Joker {
    key = "f",
    config = {
        extra = {
            mult = 0,
            change = 10,
            user_ids = {}
        }
    },
    loc_txt = {
        name = "F",
        text = {
            "This Joker gains {C:red}+10{} Mult for every",
            "unique {C:tarot}chat member{} {C:attention}timed out{} typing {C:attention}F{}.",
            "{C:inactive}(Currently{} {C:red}+#1#{} {C:inactive}Mult){}"
        },
        unlock = {
            "Unlocked by default."
        }
    },
    pos = {
        x = 0,
        y = 0
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 4,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = "CustomJokers",
    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.mult}}
    end,
    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main then
            return {
                mult = card.ability.extra.mult
            }
        end
    end,
    apply_ban = function(self, card, user_id)
        if not card.ability.extra.user_ids[user_id] then
            card.ability.extra.user_ids[user_id] = true
            SMODS.scale_card(card, {
                ref_table = card.ability.extra,
                ref_value = "mult",
                scalar_value = "change",
                scaling_message = {
                    message = "Banned!",
                    colour = G.C.RED
                }
            })
        end
    end
}
