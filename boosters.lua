-- Moving jokers to twitch pack
--SMODS.Booster {
--    key = 'vargthumb_pack',
--    loc_txt = {
--        name = "VargThumb Pack",
--        text = {
--            [1] = '{X:tarot,C:white}This is a test that will change  later{}'
--        },
--        group_name = "Joey Jokers"
--    },
--    config = { extra = 3, choose = 1 },
--    atlas = "CustomBoosters",
--    pos = { x = 0, y = 0 },
--    discovered = true,
--    loc_vars = function(self, info_queue, card)
--        local cfg = (card and card.ability) or self.config
--        return {
--            vars = { cfg.choose, cfg.extra }
--        }
--    end,
--    create_card = function(self, card, i)
--        return {
--            set = "ttv_memejokers",
--            area = G.pack_cards,
--            skip_materialize = true,
--            soulable = true,
--            key_append = "ttv_vargthumb_pack"
--        }
--    end,
--    ease_background_colour = function(self)
--        ease_colour(G.C.DYN_UI.MAIN, HEX("1e5b29"))
--        ease_background_colour({ new_colour = HEX('1e5b29'), special_colour = HEX("09c51e"), contrast = 2 })
--    end,
--    particles = function(self)
--    end,
--}
--

SMODS.Booster {
    key = 'twitch_pack_1',
    loc_txt = {
        name = "Twitch Standard Pack",
        text = {
            'A booster pack with {C:purple}Twitch{} Jokers.',
            'Might even see a {C:legendary}legendary.'
        },
        group_name = "Twitch Jokers"
    },
    config = {extra = 3, choose = 1, weight = 1},
    atlas = "CustomBoosters",
    pos = {x = 1, y = 0},
    discovered = true,
    weight = 1,
    loc_vars = function(self, info_queue, card)
        local cfg = (card and card.ability) or self.config
        return {
            vars = {cfg.choose, cfg.extra, cfg.weight}
        }
    end,
    create_card = function(self, card, i)
        return {
            set = #get_current_pool("ttv_memejokers") > 1 and "ttv_memejokers" or "Joker",
            area = G.pack_cards,
            skip_materialize = true,
            soulable = true,
            key_append = "ttv_twitch_pack_1"
        }
    end,
    ease_background_colour = function(self)
        ease_colour(G.C.DYN_UI.MAIN, HEX("b118c5"))
        ease_background_colour({new_colour = HEX('b118c5'), special_colour = HEX("9c2d9f"), contrast = 2})
    end,
    particles = function(self)
    end
}


SMODS.Booster {
    key = 'temu_pack',
    loc_txt = {
        name = "Temu Pack",
        text = {
            'Need a cheap {C:orange}joker{}?'
        },
        group_name = "Temu Jokers"
    },
    config = {extra = 5, choose = 1},
    cost = 1,
    atlas = "CustomBoosters",
    pos = {x = 2, y = 0},
    discovered = true,
    loc_vars = function(self, info_queue, card)
        local cfg = (card and card.ability) or self.config
        return {
            vars = {cfg.choose, cfg.extra}
        }
    end,
    create_card = function(self, card, i)
        local random = pseudorandom("ttv_830127", 1, 5)
        return {
            set = i == random and "ttv_Temu_jokers" or "Joker",
            edition = "e_ttv_bootleg",
            area = G.pack_cards,
            skip_materialize = true,
            soulable = true
        }
    end,
    ease_background_colour = function(self)
        ease_colour(G.C.DYN_UI.MAIN, HEX("ff8100"))
        ease_background_colour({new_colour = HEX('ff8100'), special_colour = HEX("d56917"), contrast = 2})
    end,
    particles = function(self)
    end
}

SMODS.Booster {
    key = 'jumbo_twitch_pack',
    loc_txt = {
        name = "Jumbo Twitch Pack",
        text = {
            [1] = 'A booster pack with {C:purple}Twitch{} Jokers.'
        },
        group_name = "ttv_boosters"
    },
    config = { extra = 4, choose = 1 },
    atlas = "CustomBoosters",
    pos = { x = 3, y = 0 },
    discovered = true,
    loc_vars = function(self, info_queue, card)
        local cfg = (card and card.ability) or self.config
        return {
            vars = { cfg.choose, cfg.extra }
        }
    end,
    create_card = function(self, card, i)
        return {
            set = #get_current_pool("ttv_memejokers") > 1 and "ttv_memejokers" or "Joker",
            area = G.pack_cards,
            skip_materialize = true,
            soulable = true,
            key_append = "twitchin_jumbo_twitch_pack"
        }
    end,
    ease_background_colour = function(self)
        ease_colour(G.C.DYN_UI.MAIN, HEX("b118c5"))
        ease_background_colour({new_colour = HEX('b118c5'), special_colour = HEX("9c2d9f"), contrast = 2})
    end,
    particles = function(self)
        -- No particles for joker packs
        end,
    }