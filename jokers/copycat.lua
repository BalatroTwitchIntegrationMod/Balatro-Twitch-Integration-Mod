local function create_voting_ui(state)
    local names = {}
    local votes = {}

    for i, joker in ipairs(state.options) do
        names[#names + 1] = {
            n = G.UIT.R,
            config = { align = "tl" },
            nodes = { { n = G.UIT.T, config = { text = string.format("%1d: %s", i, joker.name), colour = G.C.UI.TEXT_LIGHT, scale = 0.5 } } }
        }

        votes[#votes + 1] = {
            n = G.UIT.R,
            config = { align = "tl" },
            nodes = { { n = G.UIT.T, config = { ref_table = state.votes, ref_value = i, colour = G.C.UI.TEXT_LIGHT, scale = 0.5 } } }
        }
    end

    return {
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
                    { n = G.UIT.T, config = { ref_table = state, ref_value = "time_left", colour = G.C.UI.TEXT_LIGHT, scale = 0.5 } }
                }
            } }
        }, {
            n = G.UIT.R,
            config = { align = "tl" },
            nodes = {
                { n = G.UIT.C, config = { align = "cl" },                                     nodes = names },
                { n = G.UIT.C, config = { align = "cr", minw = 1, id = "ttv_copycat_votes" }, nodes = votes },
            }
        } }
    }
end

SMODS.Joker {
    key = "copycat",
    config = {},
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
        local voting = {
            user_ids = {},
            options = {},
            votes = {},
            timestamp = os.time(),
            time_left = "",
            countdown = 30,
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

            voting.options[i] = {
                card = joker,
                name = localize({ type = "name_text", set = "Joker", key = joker }),
            }
            voting.votes[i] = 0
        end

        voting.options[#voting.options + 1] = {
            card = nil,
            name = "Nothing"
        }
        voting.votes[#voting.votes + 1] = 0

        card.children.ttv_copycat_box = UIBox({
            definition = create_voting_ui(voting),
            config = { align = "cm", interactable = false, collideable = false, can_collide = false },
        })

        if not card.config.extra then
            card.config.extra = {}
        end

        card.config.extra.voting = voting
    end,
    remove_from_deck = function(self, card, from_debuff)
        if card.children.ttv_copycat_box then
            card.children.ttv_copycat_box:remove()
            card.children.ttv_copycat_box = nil
        end
    end,
    update = function(self, card, dt)
        if not (card.config.extra and card.config.extra.voting) then
            return
        end

        if card.config.extra.voting.done then
            return
        end

        local voting = card.config.extra.voting
        local elapsed = os.difftime(os.time(), voting.timestamp)

        voting.time_left = string.format("%d seconds", math.floor(voting.countdown - elapsed))

        if elapsed >= voting.countdown then
            voting.done = true

            local max_votes = 0
            local winner = nil

            for i, votes in ipairs(voting.votes) do
                if votes > max_votes then
                    max_votes = votes
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
    end,
    add_vote = function(self, card, vote, user_id)
        if not (card.config.extra and card.config.extra.voting) then
            return
        end

        local voting = card.config.extra.voting

        if vote < 1 or vote > #voting.options then
            return
        end

        if voting.user_ids[user_id] then
            return
        end

        voting.user_ids[user_id] = true

        voting.votes[vote] = voting.votes[vote] + 1

        self:juice_up_vote(card, vote)
    end,
    juice_up_vote = function(self, card, i)
        if not card.children.ttv_copycat_box then
            return
        end

        local node = card.children.ttv_copycat_box:get_UIE_by_ID("ttv_copycat_votes")

        if not node then
            return
        end

        if node.children[i] and node.children[i].children[1] then
            node.children[i].children[1]:juice_up()
            play_sound("voice" .. math.random(11), 1, 0.3)
        end
    end
}
