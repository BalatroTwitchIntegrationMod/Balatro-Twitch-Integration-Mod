SMODS.Joker {
    key = "thebanhammer",
    config = {
        extra = {
            xmult = 0,
            change = 10,
            user_ids = {}
        }
    },
    loc_txt = {
        name = "The Ban Hammer",
        text = {
            "Gains {X:red,C:white}X#1#{} Mult for every",
            "{C:red}permanently banned{} unique {C:tarot}chat member{}",
            "{C:inactive}(Currently{} {X:red,C:white}X#2#{} {C:inactive}Mult){}"
        },
        unlock = {
            "Unlocked by default."
        }
    },
    pos = {
        x = 0,
        y = 1
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 20,
    rarity = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = "CustomJokers",
    in_pool = function(self, args)
        return (
                not args
                or args.source ~= "sho" and args.source ~= "buf" and args.source ~= "jud" and args.source ~= "sou"
                or args.source ~= "rif" or args.source ~= "rta" or args.source ~= "uta" or args.source ~= "wra"
            )
            and true
    end,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.change,
                card.ability.extra.xmult
            }
        }
    end,
    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main then
            return {
                xmult = card.ability.extra.xmult
            }
        end
    end,
    apply_ban = function(self, card, user_id)
        if not card.ability.extra.user_ids[user_id] then
            card.ability.extra.user_ids[user_id] = true
            SMODS.scale_card(card, {
                ref_table = card.ability.extra,
                ref_value = "xmult",
                scalar_value = "change",
                scaling_message = {
                    message = "Banned!",
                    colour = G.C.RED
                }
            })
        end
    end
}
