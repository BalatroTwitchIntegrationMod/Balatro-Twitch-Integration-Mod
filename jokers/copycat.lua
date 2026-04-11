---@param voting { options: { name: string, couunt: number }[], time_left: string }
---@return UINode
local function voting_panel_uidef(voting)
    local names = {}
    local votes = {}

    for i, joker in ipairs(voting.options) do
        table.insert(names, {
            n = G.UIT.R,
            config = { align = "tl" },
            nodes = { { n = G.UIT.T, config = { text = string.format("%1d: %s", i, joker.name), colour = G.C.UI.TEXT_LIGHT, scale = 0.5 } } }
        })
        table.insert(votes, {
            n = G.UIT.R,
            config = { align = "tl" },
            nodes = { { n = G.UIT.T, config = { ref_table = joker, ref_value = "count", colour = G.C.UI.TEXT_LIGHT, scale = 0.5 } } }
        })
    end

    ---@type UINode
    local uidef = {
        n = G.UIT.ROOT,
        config = { align = "tl", colour = G.C.UI.HOVER, hover = true, padding = 0.2, r = 0.1 },
        nodes = { {
            n = G.UIT.R,
            config = { align = "tm" },
            nodes = { {
                n = G.UIT.C,
                config = { align = "cl" },
                nodes = { { n = G.UIT.T, config = { text = "Vote on a Joker by typing a number!", colour = G.C.IMPORTANT, scale = 0.5 } } }
            } }
        }, {
            n = G.UIT.R,
            config = { align = "tm" },
            nodes = { {
                n = G.UIT.C,
                config = { align = "cl" },
                nodes = {
                    { n = G.UIT.T, config = { text = "Time left: ", colour = G.C.UI.TEXT_LIGHT, scale = 0.5 } },
                    { n = G.UIT.T, config = { ref_table = voting, ref_value = "time_left", colour = G.C.UI.TEXT_LIGHT, scale = 0.5 } }
                }
            } }
        }, {
            n = G.UIT.R,
            config = { align = "tl" },
            nodes = {
                { n = G.UIT.C, config = { align = "cl" },                         nodes = names },
                { n = G.UIT.C, config = { align = "cr", minw = 1, id = "votes" }, nodes = votes },
            }
        } }
    }

    return uidef
end

SMODS.Joker { -- Copy Cat
    key = "copycat",
    config = {
        extra = {
            countdown = 30,
        }
    },
    loc_txt = {
        name = "Copy Cat",
        text = {
            "Turns this {C:attention}Joker{} into",
            "whatever {C:tarot}chat{} chooses."
        },
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
    atlas = "JokerSet1",

    add_to_deck = function(self, card, from_debuff)
        if from_debuff then
            return
        end

        local voting = {
            user_ids = {},
            options = {},
            time_left = "",
            countdown = self.config.extra.countdown,
            done = false,
        }

        local pool = SMODS.get_clean_pool("Joker")

        for i, _ in ipairs(pool) do
            if pool[i] == "j_ttv_copycat" then
                pool[i] = nil
            end
        end

        for i = 1, 4 do
            local joker, key = pseudorandom_element(pool, "ttv_copycat")

            if key then
                pool[key] = nil
            else
                break
            end

            table.insert(voting.options, {
                card = joker,
                name = localize({ type = "name_text", set = "Joker", key = joker }),
                count = 0,
            })
        end

        table.insert(voting.options, {
            card = nil,
            name = "Nothing",
            count = 0,
        })

        card.ability.extra.voting = voting
    end,

    create_voting_ui = function(self, card)
        if card.children.ttv_copycat_box then
            return
        end

        card.children.ttv_copycat_box = UIBox({
            definition = voting_panel_uidef(card.ability.extra.voting),
            config = { align = "cm", can_collide = false, r_bond = "Weak", instance_type = "ALERT" },
        })

        card.children.ttv_copycat_box:juice_up(0.1)
    end,

    update = function(self, card, dt)
        if not (card.ability.extra and card.ability.extra.voting) then
            return
        end

        if card.ability.extra.voting.done then
            return
        end

        self:create_voting_ui(card)

        local voting = card.ability.extra.voting

        voting.time_left = string.format("%d seconds", math.ceil(math.max(voting.countdown, 0)))

        if voting.countdown <= 0 then
            voting.done = true

            if card.children.ttv_copycat_box then
                card.children.ttv_copycat_box.states.visible = false
            end

            local max_votes = 0
            local winner = nil

            for i, option in ipairs(voting.options) do
                if option.count > max_votes then
                    max_votes = option.count
                    winner = i
                end
            end

            if winner and voting.options[winner].card then
                SMODS.add_card({ key = voting.options[winner].card })
            else
                card_eval_status_text(card, "jokers", nil, nil, nil, {
                    color = G.C.WHITE,
                    message = "Nothing!",
                    sound = "ttv_fart_sound1"
                })
            end

            SMODS.destroy_cards(card, nil, true)
        end

        voting.countdown = voting.countdown - (dt / G.SPEEDFACTOR)
    end,

    add_vote = function(self, card, vote, user_id)
        if G.SETTINGS.paused then
            return
        end

        if not (card.ability.extra and card.ability.extra.voting) then
            return
        end

        local voting = card.ability.extra.voting

        if vote < 1 or vote > #voting.options then
            return
        end

        if voting.user_ids[user_id] then
            return
        end

        voting.user_ids[user_id] = true

        voting.options[vote].count = voting.options[vote].count + 1

        self:juice_up_vote(card, vote)
    end,

    juice_up_vote = function(self, card, vote)
        if not card.children.ttv_copycat_box then
            return
        end

        local node = card.children.ttv_copycat_box:get_UIE_by_ID("votes")

        if not node then
            return
        end

        if node.children[vote] and node.children[vote].children[1] then
            node.children[vote].children[1]:juice_up()
            play_sound("voice" .. math.random(11), 1, 0.3)
        end
    end
}
