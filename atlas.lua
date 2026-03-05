SMODS.Atlas({
    key = "alien_overlay",
    path = "alien.png",
    px = 800,
    py = 450,
    atlas_table = "ASSET_ATLAS"
})

SMODS.Atlas({
    key = "modicon",
    path = "ModIcon.png",
    px = 34,
    py = 34,
    atlas_table = "ASSET_ATLAS"
})

SMODS.Atlas({
    key = "balatro",
    path = "balatro.png",
    px = 333,
    py = 216,
    prefix_config = {key = false},
    atlas_table = "ASSET_ATLAS"
})

SMODS.Atlas({
    key = "CustomJokers",
    path = "CustomJokers.png",
    px = 71,
    py = 95,
    atlas_table = "ASSET_ATLAS"
})

SMODS.Atlas({
    key = "CustomConsumables",
    path = "CustomConsumables.png",
    px = 71,
    py = 95,
    atlas_table = "ASSET_ATLAS"
})

SMODS.Atlas({
    key = "CustomBoosters",
    path = "CustomBoosters.png",
    px = 71,
    py = 95,
    atlas_table = "ASSET_ATLAS"
})

SMODS.Atlas({
    key = "RRJokerAnima",
    path = "RRjoker.png",
    px = 71,
    py = 95,
    atlas_table = "ASSET_ATLAS"
})

SMODS.Atlas({
    key = "CustomDecks",
    path = "CustomDecks.png",
    px = 71,
    py = 95,
    atlas_table = "ASSET_ATLAS"
})

SMODS.Atlas({
    key = "TemplateSprites",
    path = "TemplateSprites.png",
    px = 71,
    py = 95,
    atlas_table = "ASSET_ATLAS"
})

SMODS.Atlas({
    key = "CustomTags",
    path = "CustomTags.png",
    px = 34,
    py = 34,
    atlas_table = "ASSET_ATLAS"
})

SMODS.Atlas({
    key = "chipspin",
    path = "chipspin.png",
    frames = 8,
    px = 71,
    py = 95,
    atlas_table = "ANIMATION_ATLAS"
})

SMODS.Atlas({
    key = "agga",
    path = "agga.png",
    frames = 15,
    fps = 30,
    px = 71,
    py = 95,
    atlas_table = "ANIMATION_ATLAS"
})

local NFS = require("nativefs")
to_big = to_big or function(a) return a end
lenient_bignum = lenient_bignum or function(a) return a end

local jokerIndexList = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}

local function load_jokers_folder()
    local mod_path = SMODS.current_mod.path
    local jokers_path = mod_path .. "/jokers"
    local files = NFS.getDirectoryItemsInfo(jokers_path)
    for i = 1, #jokerIndexList do
        local file_name = files[jokerIndexList[i]].name
        if file_name:sub(-4) == ".lua" then
            assert(SMODS.load_file("jokers/" .. file_name))()
        end
    end
end


local consumableIndexList = {1, 2, 3, 4}

local function load_consumables_folder()
    local mod_path = SMODS.current_mod.path
    local consumables_path = mod_path .. "/consumables"
    local files = NFS.getDirectoryItemsInfo(consumables_path)
    local set_file_number = #files + 1
    for i = 1, #files do
        if files[i].name == "sets.lua" then
            assert(SMODS.load_file("consumables/sets.lua"))()
            set_file_number = i
        end
    end
    for i = 1, #consumableIndexList do
        local j = consumableIndexList[i]
        if j >= set_file_number then
            j = j + 1
        end
        local file_name = files[j].name
        if file_name:sub(-4) == ".lua" then
            assert(SMODS.load_file("consumables/" .. file_name))()
        end
    end
end

local editionIndexList = {1}

local function load_editions_folder()
    local mod_path = SMODS.current_mod.path
    local editions_path = mod_path .. "/editions"
    local files = NFS.getDirectoryItemsInfo(editions_path)
    for i = 1, #editionIndexList do
        local file_name = files[editionIndexList[i]].name
        if file_name:sub(-4) == ".lua" then
            assert(SMODS.load_file("editions/" .. file_name))()
        end
    end
end

local deckIndexList = {2, 1}

local function load_decks_folder()
    local mod_path = SMODS.current_mod.path
    local decks_path = mod_path .. "/decks"
    local files = NFS.getDirectoryItemsInfo(decks_path)
    for i = 1, #deckIndexList do
        local file_name = files[deckIndexList[i]].name
        if file_name:sub(-4) == ".lua" then
            assert(SMODS.load_file("decks/" .. file_name))()
        end
    end
end

local function load_boosters_file()
    local mod_path = SMODS.current_mod.path
    assert(SMODS.load_file("boosters.lua"))()
end

load_boosters_file()
assert(SMODS.load_file("sounds.lua"))()
assert(SMODS.load_file("usebuttons.lua"))()
assert(SMODS.load_file("colours.lua"))()
assert(SMODS.load_file("shaders.lua"))()
assert(SMODS.load_file("tags.lua"))()
load_jokers_folder()
load_consumables_folder()
load_editions_folder()
load_decks_folder()
SMODS.ObjectType({
    key = "ttv_food",
    cards = {
        ["j_gros_michel"] = true,
        ["j_egg"] = true,
        ["j_ice_cream"] = true,
        ["j_cavendish"] = true,
        ["j_turtle_bean"] = true,
        ["j_diet_cola"] = true,
        ["j_popcorn"] = true,
        ["j_ramen"] = true,
        ["j_selzer"] = true
    }
})

SMODS.ObjectType({
    key = "ttv_memejokers",
    cards = {
        ["j_ttv_f"] = true,
        ["j_ttv_balkan"] = true,
        ["j_ttv_bulletroulette"] = true,
        ["j_ttv_monkey"] = true,
        ["j_ttv_copycat"] = true,
        ["j_ttv_chatters"] = true,
        ["c_ttv_kappsoul"] = true,
        ["j_ttv_chimpanzee"] = true,
        ["j_ttv_dinner"] = true,
        ["j_ttv_clown"] = true,
        ["j_ttv_happycat"] = true,
        ["j_ttv_mods"] = true,
        ["j_ttv_agga"] = true,
        ["j_ttv_oneguy"] = true
    }
})

SMODS.ObjectType({
    key = "ttv_ttv_twitch_jokers",
    cards = {
        ["j_ttv_f"] = true,
        ["j_ttv_copycat"] = true,
        ["j_ttv_chatters"] = true,
        ["j_ttv_oneguy"] = true,
        ["j_ttv_mods"] = true
    }
})

SMODS.ObjectType({
    key = "ttv_Temu_jokers",
    cards = {
        ["j_ttv_clown"] = true,
        ["j_ttv_happycat"] = true
    }
})

SMODS.ObjectType({
    key = "ttv_legendary_ttv_jokers",
    default = "j_ttv_thebanhammer",
    cards = {
        ["j_ttv_thebanhammer"] = true
    }
})

SMODS.current_mod.optional_features = function()
    return {
        cardareas = {}
    }
end

return {}
