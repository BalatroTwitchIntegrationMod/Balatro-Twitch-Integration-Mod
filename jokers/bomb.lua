---@param card Card
---@param keypad_click_key string
---@return UINode
local function bomb_keypad_uidef(card, keypad_click_key)
    local ref_table = card.ability.extra.state

    local keypad_nodes = {}
    local keypad_glyphs = {
        { "1", "2", "3" },
        { "4", "5", "6" },
        { "7", "8", "9" },
        { "X", "0", "»" }
    }

    for r = 1, 4 do
        local row_nodes = {}

        for c = 1, 3 do
            local color = G.C.GREY
            local glyph = keypad_glyphs[r][c]

            if glyph == "X" then color = G.C.RED end
            if glyph == "»" then color = G.C.GREEN end

            table.insert(row_nodes, {
                n = G.UIT.C,
                nodes = { UIBox_button({ label = { glyph }, colour = color, button = keypad_click_key, minw = 0.3, minh = 0.2, scale = 0.3, id = glyph }) },
                config = { colour = G.C.CLEAR, padding = 0, w = 0.3, h = 0.2 }
            })
        end

        table.insert(keypad_nodes, {
            n = G.UIT.R,
            nodes = row_nodes,
            config = { colour = G.C.CLEAR, padding = 0.05, w = 1.0, h = 0.2, align = "cm" }
        })
    end

    ---@type UINode
    local uidef = {
        n = G.UIT.ROOT,
        config = { r = 0.1, align = "tm", padding = 0.05, colour = G.C.UI.TRANSPARENT_DARK, w = 1.0, h = 1.0 },
        nodes = { {
            n = G.UIT.C,
            config = { colour = G.C.CLEAR, padding = 0.0, w = 1.0, h = 1.0 },
            nodes = {
                {
                    n = G.UIT.R,
                    config = { colour = G.C.CLEAR, padding = 0.05, w = 1.0, h = 0.2 },
                    nodes = { {
                        n = G.UIT.C,
                        config = { colour = G.C.UI.TRANSPARENT_DARK, padding = 0.05, minw = 0.6, minh = 0.2 },
                        nodes = { { n = G.UIT.T, config = { colour = G.C.WHITE, padding = 0.15, ref_table = ref_table, ref_value = "code_text", scale = 0.3 } } }
                    }, {
                        n = G.UIT.C,
                        config = { colour = G.C.UI.TRANSPARENT_DARK, padding = 0.0, minw = 0.4, minh = 0.2, align = "cm" },
                        nodes = { { n = G.UIT.T, config = { colour = G.C.RED, padding = 0.15, ref_table = ref_table, ref_value = "countdown_text", scale = 0.3 } } }
                    } }
                },
                unpack(keypad_nodes)
            }
        } }
    }

    return uidef
end

SMODS.Joker { -- C4
    key = "bomb",
    config = {
        extra = {
            code_text = "4176",
            eternal = false,
            countdown = 60,
        }
    },
    loc_txt = {
        name = "C4",
        text = {
            "{C:dark_edition,E:1,s:2}DEFUSE THE BOMB OR LOSE!{}",
            "{C:inactive}{C:red,E:2}Self-destructs{} when timer runs out{}"
        },
        unlock = { "Unlocked by default." }
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
    atlas = "JokerSet1",

    in_pool = function()
        return false
    end,

    add_to_deck = function(self, card, from_debuff)
        -- Let it be sold the first time it appears, for the funnies
        self.config.extra.eternal = true
    end,

    set_ability = function(self, card, initial)
        if not initial then
            return
        end

        if self.config.extra.eternal and not G.SETTINGS.paused then
            card:set_eternal(true)
        end

        card.ability.extra.state = {
            code_text = "_",
            countdown = card.ability.extra.countdown,
            countdown_text = tostring(card.ability.extra.countdown),
            countdown_enabled = true,
            ticks_last = card.ability.extra.countdown * 2,
        }
    end,

    create_keypad = function(self, card)
        if card.children.ttv_bomb_keypad or not card.ability.extra.state.countdown_enabled then
            return
        end

        local keypad_click_key = tostring(card)

        G.FUNCS[keypad_click_key] = function(e)
            self:keypad_click(card, e)
        end

        local keypad = UIBox {
            definition = bomb_keypad_uidef(card, keypad_click_key),
            config = { align = "cm", parent = card, instance_type = "CARD", offset = { x = 0, y = 0.05 } }
        }
        local remove_ref = keypad.remove
        keypad.remove = function(s)
            remove_ref(s)
            G.FUNCS[keypad_click_key] = nil
        end

        card.children.ttv_bomb_keypad = keypad
    end,

    keypad_click = function(self, card, e)
        local state = card.ability.extra.state
        local action = e.config.id

        if action == "X" then
            state.code_text = "_"
        elseif action == "»" then
            local code = string.gsub(state.code_text, "_", "")
            state.code_text = "_"
            if code == card.ability.extra.code_text then
                if G.STAGE == G.STAGES.RUN then
                    SMODS.destroy_cards(card, true)
                    G.E_MANAGER:add_event(Event({
                        trigger = "after",
                        delay = 0.1 * G.SPEEDFACTOR,
                        blocking = false,
                        func = function()
                            card.children.ttv_bomb_keypad.states.visible = false
                            return true
                        end
                    }))
                end
                state.countdown_enabled = false
                play_sound("ttv_bomb_defuse", 1.0, 0.7)
            else
                play_sound("ttv_loud_incorrect_buzzer", 1.0, 1.5)
            end
        elseif string.find(state.code_text, "_") then
            state.code_text = string.gsub(state.code_text, "_", "")
            state.code_text = state.code_text .. action
            if #state.code_text < 4 then
                state.code_text = state.code_text .. "_"
            end
        end
    end,

    update = function(self, card, dt)
        self:create_keypad(card)

        local keypad = card.children.ttv_bomb_keypad
        local disable_collide = keypad and keypad.states.collide.is
        card.states.collide.can = not disable_collide
        card.zoom = false

        local state = card.ability.extra.state

        if not state.countdown_enabled then
            return
        end

        if state.countdown > 0 then
            state.countdown_text = tostring(math.ceil(math.max(state.countdown, 0)))
            local ticks = math.ceil(state.countdown * 2)
            if ticks ~= state.ticks_last and (state.countdown < 9 or math.fmod(ticks, 2) == 0) then
                card:juice_up(0.1, 0)
                play_sound("tarot1", 1.5, 0.5)
            end
            state.ticks_last = ticks
        else
            state.code_text = "BOOM!"
            state.countdown_text = ""
            state.countdown_enabled = false

            play_sound("ttv_bomb_explosion", 1.0, 0.7)

            SMODS.destroy_cards(card, true)

            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.25 * G.SPEEDFACTOR,
                func = function()
                    if G.STAGE == G.STAGES.RUN then
                        G.STATE = G.STATES.GAME_OVER
                        G.STATE_COMPLETE = false
                    end
                    return true
                end
            }))
        end

        state.countdown = state.countdown - (dt / G.SPEEDFACTOR)
    end,
}
