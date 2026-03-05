---@class CopycatVotingState
---@field time_left string
---@field options table[]
---@field votes number[]
---@field uibox_key number

---@param state CopycatVotingState
---@return table
local function createVotingUI(state)
    local colA, colB = {}, {}
    local def = {n = G.UIT.ROOT, config = {align = "tl", colour = G.C.UI.HOVER, hover = true, padding = 0.1}, nodes = {
        {n = G.UIT.R, config = {align = "tm"}, nodes = {
            {n = G.UIT.C, config = {align = "cl"}, nodes = {
                {n = G.UIT.T, config = {text = "Vote on a Joker by typing a number!", colour = G.C.PURPLE, scale = 0.5}}
            }},
        }},
        {n = G.UIT.R, config = {align = "tm"}, nodes = {
            {n = G.UIT.C, config = {align = "cl"}, nodes = {
                {n = G.UIT.T, config = {text = "Time left: ", colour = G.C.UI.TEXT_LIGHT, scale = 0.5}},
                {n = G.UIT.T, config = {ref_table = state, ref_value = "time_left", colour = G.C.UI.TEXT_LIGHT, scale = 0.5}}
            }}
        }},
        {n = G.UIT.R, config = {align = "tl"}, nodes = {
            {n = G.UIT.C, config = {align = "cl"}, nodes = colA},
            {n = G.UIT.C, config = {align = "cr", minw = 1}, nodes = colB},
        }}
    }}
    for i, v in ipairs(state.options) do
        colA[#colA + 1] = {n = G.UIT.R, config = {align = "tl"}, nodes = {{n = G.UIT.T, config = {text = i .. ". " .. v.name, colour = G.C.UI.TEXT_LIGHT, scale = 0.5}}}}
        colB[#colB + 1] = {n = G.UIT.R, config = {align = "tl"}, nodes = {{n = G.UIT.T, config = {ref_table = state.votes, ref_value = i, colour = G.C.UI.TEXT_LIGHT, scale = 0.5}}}}
    end
    colA[#colA + 1] = {n = G.UIT.R, config = {align = "tl"}, nodes = {{n = G.UIT.T, config = {text = (#state.options + 1) .. ". Nothing", colour = G.C.UI.TEXT_LIGHT, scale = 0.5}}}}
    colB[#colB + 1] = {n = G.UIT.R, config = {align = "tl"}, nodes = {{n = G.UIT.T, config = {ref_table = state.votes, ref_value = #state.options + 1, colour = G.C.UI.TEXT_LIGHT, scale = 0.5}}}}
    return def
end

SMODS.Joker {
    key = "copycat",
    config = {
        extra = {
        }
    },
    loc_txt = {
        ['name'] = 'Copy Cat',
        ['text'] = {
            'Turns this {C:attention}Joker{} into',
            'whatever {C:tarot}chat{} chooses.'
        },
        ['unlock'] = {
            ''
        }
    },
    pos = {
        x = 3,
        y = 0
    },
    display_size = {
        w = 71 * 1,
        h = 95 * 1
    },
    cost = 10,
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'CustomJokers',
    add_to_deck = function(self, card, from_debuff)
        local options = {}
        local map = {}
        for i = 1, 4 do
            local c
            repeat
                c = G.P_CENTER_POOLS.Joker[math.random(1, #G.P_CENTER_POOLS.Joker)]
            until not map[c]
            map[c] = true
            options[i] = c
        end
        local state = {time_left = "0:30", options = options, votes = {0, 0, 0, 0, 0}}
        local ui = UIBox {
            definition = createVotingUI(state),
            config = {align = "cm", interactable = false, collideable = false, can_collide = false},
            T = {0, 0, 0, 0}
        }
        ui.attention_text = true -- hack
        --state.uibox_key = #G.I.UIBOX+1
        --G.I.UIBOX[state.uibox_key] = ui
        card.children.ttv_copycat_box = ui
        --card.ui = ui
        --card.ui_key = state.uibox_key
        SMODS.Mods.twitchintegration:add_vote(card, state, ui)
    end,
    remove_from_deck = function(self, card, from_debuff)
        --card.ui:remove()
        --if G.I.UIBOX[card.ui_key] == card.ui then table.remove(G.I.UIBOX, card.ui_key) end
    end
}
