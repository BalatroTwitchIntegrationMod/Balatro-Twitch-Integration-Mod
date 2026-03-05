local hasBeenEternal = false

---@param card Card
---@param callback fun(pass: number)
---@return table
local function createDefuseUI(card, callback)
    local state = {text = "_"}
    local function add(n)
        return function()
            if not state.text:match "_$" then return end
            state.text = state.text:sub(1, -2) .. n
            if #state.text < 4 then state.text = state.text .. "_" end
        end
    end
    local instance_key = tostring(state) .. "_"
    for i = 0, 9 do G.FUNCS[instance_key .. i] = add(i) end
    G.FUNCS[instance_key .. "x"] = function() state.text = "_" end
    G.FUNCS[instance_key .. "y"] = function() if #state.text == 4 and state.text:match "^%d%d%d%d$" then callback(tonumber(state.text) or 0) else callback(-1) end state.text = "_" end
    return {n = G.UIT.ROOT, config = {r = 0.1, align = "tm", padding = 0.05, colour = G.C.UI.TRANSPARENT_DARK, w = 1.0, h = 1.0, hover = true}, nodes = {
        {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 1.0, h = 1.0}, nodes = {
            {n = G.UIT.R, config = {colour = G.C.CLEAR, padding = 0.05, w = 1.0, h = 0.2}, nodes = {
                {n = G.UIT.C, config = {colour = G.C.UI.TRANSPARENT_DARK, padding = 0.05, minw = 0.6, minh = 0.2}, nodes = {
                    {n = G.UIT.T, config = {colour = G.C.WHITE, padding = 0.15, ref_table = state, ref_value = "text", scale = 0.3}}
                }}, {n = G.UIT.C, config = {colour = G.C.UI.TRANSPARENT_DARK, padding = 0.0, minw = 0.4, minh = 0.2, align = "cm"}, nodes = {
                    {n = G.UIT.T, config = {colour = G.C.RED, padding = 0.15, ref_table = card.ability.extra, ref_value = "Remaining_text", scale = 0.3}}
                }}
            }},
            {n = G.UIT.R, config = {colour = G.C.CLEAR, padding = 0.05, w = 1.0, h = 0.2, align = "cm"}, nodes = {
                {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 0.3, h = 0.2}, nodes = {
                    UIBox_button {label = {"1"}, colour = G.C.GREY, button = instance_key .. "1", minw = 0.3, minh = 0.2, scale = 0.3},
                }}, {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 0.3, h = 0.2}, nodes = {
                    UIBox_button {label = {"2"}, colour = G.C.GREY, button = instance_key .. "2", minw = 0.3, minh = 0.2, scale = 0.3},
                }}, {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 0.3, h = 0.2}, nodes = {
                    UIBox_button {label = {"3"}, colour = G.C.GREY, button = instance_key .. "3", minw = 0.3, minh = 0.2, scale = 0.3},
                }}
            }},
            {n = G.UIT.R, config = {colour = G.C.CLEAR, padding = 0.05, w = 1.0, h = 0.2, align = "cm"}, nodes = {
                {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 0.3, h = 0.2}, nodes = {
                    UIBox_button {label = {"4"}, colour = G.C.GREY, button = instance_key .. "4", minw = 0.3, minh = 0.2, scale = 0.3},
                }}, {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 0.3, h = 0.2}, nodes = {
                    UIBox_button {label = {"5"}, colour = G.C.GREY, button = instance_key .. "5", minw = 0.3, minh = 0.2, scale = 0.3},
                }}, {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 0.3, h = 0.2}, nodes = {
                    UIBox_button {label = {"6"}, colour = G.C.GREY, button = instance_key .. "6", minw = 0.3, minh = 0.2, scale = 0.3},
                }}
            }},
            {n = G.UIT.R, config = {colour = G.C.CLEAR, padding = 0.05, w = 1.0, h = 0.2, align = "cm"}, nodes = {
                {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 0.3, h = 0.2}, nodes = {
                    UIBox_button {label = {"7"}, colour = G.C.GREY, button = instance_key .. "7", minw = 0.3, minh = 0.2, scale = 0.3},
                }}, {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 0.3, h = 0.2}, nodes = {
                    UIBox_button {label = {"8"}, colour = G.C.GREY, button = instance_key .. "8", minw = 0.3, minh = 0.2, scale = 0.3},
                }}, {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 0.3, h = 0.2}, nodes = {
                    UIBox_button {label = {"9"}, colour = G.C.GREY, button = instance_key .. "9", minw = 0.3, minh = 0.2, scale = 0.3},
                }}
            }},
            {n = G.UIT.R, config = {colour = G.C.CLEAR, padding = 0.05, w = 1.0, h = 0.2, align = "cm"}, nodes = {
                {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 0.3, h = 0.2}, nodes = {
                    UIBox_button {label = {"X"}, colour = G.C.RED, button = instance_key .. "x", minw = 0.3, minh = 0.2, scale = 0.3},
                }}, {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 0.3, h = 0.2}, nodes = {
                    UIBox_button {label = {"0"}, colour = G.C.GREY, button = instance_key .. "0", minw = 0.3, minh = 0.2, scale = 0.3},
                }}, {n = G.UIT.C, config = {colour = G.C.CLEAR, padding = 0.0, w = 0.3, h = 0.2}, nodes = {
                    UIBox_button {label = {"»"}, colour = G.C.GREEN, button = instance_key .. "y", minw = 0.3, minh = 0.2, scale = 0.3},
                }}
            }}
        }}
    }}
end

SMODS.Joker { --C4
    key = "bomb",
    config = {
        extra = {
            Remaining = 60,
            number = 0
        }
    },
    loc_txt = {
        ['name'] = 'C4',
        ['text'] = {
            '{C:dark_edition,E:1,s:2}DEFUSE THE BOMB OR LOSE!{}',
            '{C:inactive}{C:red,E:2}Self-destructs{} when timer runs out{}'
        },
        ['unlock'] = {
            'Unlocked by default.'
        }
    },
    pos = {
        x = 7,
        y = 0
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 10,
    rarity = 4,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = false,
    unlocked = true,
    discovered = true,
    atlas = 'CustomJokers',
    in_pool = function() return false end,

    set_ability = function(self, card, initial)
        if initial then
            -- let it be sold the first time it appears, for the funnies
            if hasBeenEternal then
                card:set_eternal(true)
            else
                hasBeenEternal = true
            end
        end
    end,

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.Remaining}}
    end,

    add_to_deck = function(self, card, from_debuff)
        card.ttv_bomb_keypad = UIBox {
            definition = createDefuseUI(card, function(pass)
                if pass == card.ability.extra.number then
                    SMODS.destroy_cards(card, true)
                    play_sound("ttv_bomb_defuse", 1.0, 0.7)
                else
                    play_sound("ttv_loud_incorrect_buzzer", 1.0, 1.5)
                end
            end),
            config = {align = "cm", parent = card, collideable = true, instance_type = "POPUP"}
        }
    end,

    update = function(self, card, dt)
        if not card.ability.extra.Remaining then return end
        if card.ability.extra.Remaining <= 0 then
            card.ability.extra.Remaining = nil
            play_sound("ttv_bomb_explosion", 1.0, 0.7)
            SMODS.destroy_cards(card, true, true)
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                func = function()
                    if G.STAGE == G.STAGES.RUN then
                        G.STATE = G.STATES.GAME_OVER
                        G.STATE_COMPLETE = false
                    end
                end
            }))
        else
            if card.ability.extra.Remaining < 10 and card.ability.extra.Remaining % 1 >= 0.5 and math.max(0, (card.ability.extra.Remaining) - dt / G.SPEEDFACTOR) % 1 < 0.5 then
                card:juice_up(0.1, 0.1)
                play_sound("tarot1", 1.5, 0.5)
            end
            card.ability.extra.Remaining = math.max(0, (card.ability.extra.Remaining) - dt / G.SPEEDFACTOR)
            if math.floor(card.ability.extra.Remaining) ~= card.ability.extra.Remaining_text then
                card:juice_up(0.1, 0.1)
                play_sound("tarot1", 1.5, 0.5)
            end
            card.ability.extra.Remaining_text = math.floor(card.ability.extra.Remaining)
        end
    end,

    remove_from_deck = function(self, card, from_debuff)
        card.ttv_bomb_keypad:remove()
        card.ttv_bomb_keypad = nil
    end
}

SMODS.DrawStep {
    key = 'defuse_button',
    order = -30, -- before the Card is drawn
    func = function(card, layer)
        --        if card.children.ttv_bomb_button then
        --            card.children.ttv_bomb_button:draw()
        --        end
    end
}

SMODS.DrawStep {
    key = 'defuse_button',
    order = 80, -- after the Card is drawn
    func = function(card, layer)
        if card.ttv_bomb_keypad then
            card.ttv_bomb_keypad:draw()
        end
    end
}
