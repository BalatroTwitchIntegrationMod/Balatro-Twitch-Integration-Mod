---@class Mod
local mod = SMODS.current_mod

local action_countdown = 3
local chat_user_ids = {} ---@type { [string]: boolean }
local chat_votes = {} ---@type { [string]: { key: string, params: string[], count: number } }

---@type { [string]: { pattern: string, exec: fun(...) } }
local ACTIONS = {
    PLAY = {
        pattern = "^p$",
        exec = function()
            if #G.hand.highlighted <= 0 or G.GAME.blind.block_play or #G.hand.highlighted > math.max(G.GAME.starting_params.play_limit, 1) then
                return
            end
            G.FUNCS.play_cards_from_highlighted()
        end
    },
    DISCARD = {
        pattern = "^d$",
        exec = function()
            if G.GAME.current_round.discards_left <= 0 or #G.hand.highlighted <= 0 or #G.hand.highlighted > math.max(G.GAME.starting_params.discard_limit, 0) then
                return
            end
            G.FUNCS.discard_cards_from_highlighted()
        end
    },
    SORT = {
        pattern = "^s([or])$",
        exec = function(option)
            if option == "o" then
                G.FUNCS.sort_hand_suit({})
            elseif option == "r" then
                G.FUNCS.sort_hand_value({})
            end
        end
    },
    HAND = {
        pattern = "^h([1-9][0-9]*)$",
        exec = function(index)
            local card = tonumber(index)
            if card and card <= #G.hand.cards then
                G.hand.cards[card]:click()
            end
        end
    },
    JOKER = {
        pattern = "^j([1-9][0-9]*)([s]?)$",
        exec = function(index, option)
            local card = tonumber(index)
            if not (card and card <= #G.jokers.cards and option) then
                return
            end
            local joker = G.jokers.cards[card]
            if option == "" then
                joker:click()
            elseif option == "s" and joker:can_sell_card() then
                joker:sell_card()
            end
        end
    },
    CONSUMABLE = {
        pattern = "^c([1-9][0-9]*)([su]?)$",
        exec = function(index, option)
            local card = tonumber(index)
            if not (card and card <= #G.consumeables.cards and option) then
                return
            end
            local consumable = G.consumeables.cards[card]
            if option == "" then
                consumable:click()
            elseif option == "s" and consumable:can_sell_card() then
                consumable:sell_card()
            elseif option == "u" and consumable:can_use_consumeable() then
                consumable.area:remove_card(consumable)
                consumable:use_consumeable(consumable.area)
            end
        end
    },
}

mod.hook:add(function(dt)
    if G.SETTINGS.paused or G.STATE ~= G.STATES.SELECTING_HAND or chat_votes == {} then
        return
    end

    if action_countdown == 0 then
        action_countdown = 1

        local max_votes = 0
        local winner = nil

        for _, vote in pairs(chat_votes) do
            if vote.count > max_votes then
                winner = vote
            end
        end

        chat_user_ids = {}
        chat_votes = {}

        if winner then
            G.E_MANAGER:add_event(Event({
                func = function()
                    if G.SETTINGS.paused or G.STATE ~= G.STATES.SELECTING_HAND then
                        return false
                    end

                    ACTIONS[winner.key].exec(unpack(winner.params))

                    return true
                end
            }))
        end
    else
        action_countdown = math.max(action_countdown - dt, 0)
    end
end)

---@param state boolean
local function apply_control_state(state)
    local areas = { G.jokers, G.consumeables, G.hand }

    for _, area in ipairs(areas) do
        if area then
            for _, card in ipairs(area.cards) do
                card.states.collide.can = state
                if card.children and card.children.use_button then
                    card.children.use_button.states.collide.can = state
                end
            end
        end
    end
end

mod.hook:add(function(dt)
    if not (G.GAME and G.GAME.blind and G.GAME.blind.config.blind.key == "bl_ttv_me") then
        return
    end

    local config = G.GAME.blind.effect

    if config.take_control_away == true then
        apply_control_state(false)
    end

    if config.take_control_away == false then
        config.take_control_away = nil
        apply_control_state(true)
    end
end)

SMODS.Blind {
    key = "me",
    loc_txt = {
        name = "Twitch Plays Balatro",
        text = {
            "Streamer back up,",
            "CHATTERS play for you :)",
        },
        unlock = { "Unlocked by default." }
    },
    atlas = "me",
    discovered = true,
    dollars = 5,
    mult = 0.5,
    pos = { x = 0, y = 0 },
    boss = { min = 1, max = 10 },
    boss_colour = HEX("69359C"),
    config = {
        take_control_away = nil
    },

    set_blind = function(self)
        G.GAME.blind.effect.take_control_away = true
        action_countdown = 3
        chat_user_ids = {}
        chat_votes = {}
    end,

    defeat = function(self)
        G.GAME.blind.effect.take_control_away = false
    end,

    disable = function(self)
        G.GAME.blind.effect.take_control_away = false
    end,

    add_vote = function(self, text, user_id)
        if chat_user_ids[user_id] then
            return
        end

        for key, action in pairs(ACTIONS) do
            local params = { string.match(text, action.pattern) }

            if #params > 0 then
                chat_user_ids[user_id] = true

                if chat_votes[text] then
                    chat_votes[text].count = chat_votes[text].count + 1
                else
                    chat_votes[text] = { key = key, params = params, count = 1 }
                end

                break
            end
        end
    end
}
