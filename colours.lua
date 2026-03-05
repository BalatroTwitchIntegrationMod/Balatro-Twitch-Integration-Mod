--It's just easier to find this way lol
SMODS.Gradient {
    key = 'ttv_jackpot1',
    colours = {G.C.GOLD, G.C.RED, G.C.MONEY, G.C.FILTER, G.C.BLUE, G.C.PURPLE, G.C.GREEN},
    cycle = 0.3,
    interpolation = 'linear'
}
-- These could use better colours but it's fine for now
SMODS.Gradient {
    key = 'ttv_jackpot2',
    colours = {G.C.RED, G.C.BLUE, G.C.GREEN, G.C.MONEY, G.C.GOLD, G.C.FILTER, G.C.PURPLE},
    cycle = 0.3,
    interpolation = 'linear'
}

SMODS.Gradient {
    key = 'ttv_ehancing',
    colours = {G.C.PURPLE, G.C.BLUE, G.C.SUITS.Spades},
    cycle = 0.6,
    interpolation = 'linear'
}

SMODS.Gradient {
    key = 'ttv_ehancing2',
    colours = {G.C.BLUE, G.C.SUITS.Spades, G.C.PURPLE},
    cycle = 0.6,
    interpolation = 'linear'
}

loc_colour()
G.ARGS.LOC_COLOURS.ttv_purple = HEX('69359c')
G.ARGS.LOC_COLOURS.ttv_purple2 = HEX('a562cf')
G.ARGS.LOC_COLOURS.ttv_jackpot = HEX('D19431')
