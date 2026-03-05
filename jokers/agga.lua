-- https://www.desmos.com/calculator/j8onmqu9ln
local sqrt, pi, exp, floor = math.sqrt, math.pi, math.exp, math.floor
local random_table = {}

-- constants
local H = 1.0 -- halfway point for pdf
local A1, A2 = 1.0, 2.0 -- distributions for left and right sides of curve
local step = 0.001 -- step for calculations, smaller is more accurate but slower

local As1, As2 = sqrt(2 * pi * A1^2), sqrt(2 * pi * A2^2)
local B = sqrt(A1 / A2)
A1, A2 = A1^2, A2^2
local function f(x)
    local a = x < H and A1 or A2
    local as = x < H and As1 or As2
    local b = x < H and B or 1/B
    return b / as * exp(-(x-H)^2 / (2 * a))
end
local c = 0
for x = -1, 8, step do c = c + f(x) * step end

local acc = 0
for x = -1, 8, step do
    random_table[floor(acc * 1000)] = floor(x * 100) / 100
    acc = acc + f(x) / c * step
end
local function random_xmult() return random_table[math.random(0, 1000)] or 1 end

SMODS.Joker{
    key = "agga",
    config = {
        extra = {
            max = 20,
            min = -8
        }
    },
    loc_txt = {
        ['name'] = 'AGGA',
        ['text'] = {
            '{C:dark_edition,E:1,s:1}RANDOM -/+ XMULT CHANCE{}'
        },
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
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'agga',

    loc_vars = function(self, info_queue, card)
        local r_mults = {}
        for i = card.ability.extra.min, card.ability.extra.max do
            r_mults[#r_mults + 1] = tostring(i)
        end
        local loc_mult = ' ' .. 'mult chance' .. ' '
        local loc_error = ' ' .. (localize('error')) .. ' '
        main_start = {
            { n = G.UIT.T, config = { text = '  X', colour = G.C.MULT, scale = 0.32, }, },
            { n = G.UIT.O, config = { object = DynaText({ string = r_mults, colours = { G.C.RED }, pop_in_rate = 9999999, silent = true, random_element = true, pop_delay = 0.5, scale = 0.32, min_cycle_time = 0 }) } },
            {
                n = G.UIT.O,
                config = {
                    object = DynaText({
                        string = {
                            { string = 'rand()', colour = G.C.JOKER_GREY }, { string = "#@" .. (G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.id or 11) .. (G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.suit:sub(1, 1) or 'D'), colour = G.C.RED },
                            loc_mult, loc_error, loc_mult, loc_error, loc_mult, loc_error, loc_mult, loc_mult, loc_mult,
                            loc_error, loc_mult, loc_mult, loc_error },
                        colours = { G.C.UI.TEXT_DARK },
                        pop_in_rate = 9999999,
                        silent = true,
                        random_element = true,
                        pop_delay = 0.2011,
                        scale = 0.32,
                        min_cycle_time = 0
                    })
                }
            },
        }
        return { main_start = main_start }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                xmult = random_xmult()
            }
        end
    end
}

--SMODS.Joker{
--    key = "agga",
--    config = {
--        extra = {
--            max = 6,
--            min = 1
--        }
--    },
--    loc_txt = {
--        ['name'] = 'AGGA',
--        ['text'] = {
--            '{C:red,X:red,C}x1-6{} Mult'
--        },
--    },
--    pos = {
--        x = 2,
--        y = 1
--    },
--    display_size = {
--        w = 71 * 1, 
--        h = 95 * 1
--    },
--    cost = 4,
--    rarity = 2,
--    blueprint_compat = true,
--    eternal_compat = true,
--    perishable_compat = true,
--    unlocked = true,
--    discovered = true,
--    atlas = 'CustomJokers',
--
--    loc_vars = function(self, info_queue, card)
--        local r_mults = {}
--        for i = card.ability.extra.min, card.ability.extra.max do
--            r_mults[#r_mults + 1] = tostring(i)
--        end
--        local loc_mult = ' ' .. (localize('k_mult')) .. ' '
--        local loc_error = ' ' .. (localize('error')) .. ' '
--        main_start = {
--            { n = G.UIT.T, config = { text = '  X', colour = G.C.MULT, scale = 0.32, }, },
--            { n = G.UIT.O, config = { object = DynaText({ string = r_mults, colours = { G.C.RED }, pop_in_rate = 9999999, silent = true, random_element = true, pop_delay = 0.5, scale = 0.32, min_cycle_time = 0 }) } },
--            {
--                n = G.UIT.O,
--                config = {
--                    object = DynaText({
--                        string = {
--                            { string = 'rand()', colour = G.C.JOKER_GREY }, { string = "#@" .. (G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.id or 11) .. (G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.suit:sub(1, 1) or 'D'), colour = G.C.RED },
--                            loc_mult, loc_error, loc_mult, loc_error, loc_mult, loc_error, loc_mult, loc_mult, loc_mult,
--                            loc_error, loc_mult, loc_mult, loc_error },
--                        colours = { G.C.UI.TEXT_DARK },
--                        pop_in_rate = 9999999,
--                        silent = true,
--                        random_element = true,
--                        pop_delay = 0.2011,
--                        scale = 0.32,
--                        min_cycle_time = 0
--                    })
--                }
--            },
--        }
--        return { main_start = main_start }
--    end,
--    calculate = function(self, card, context)
--        if context.joker_main then
--            return {
--                Xmult = pseudorandom('vremade_agga', card.ability.extra.min, card.ability.extra.max)
--            }
--        end
--    end
--}

