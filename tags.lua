SMODS.Tag {
    key = "twitch_booster",
    min_ante = 0,
    atlas = 'ttv_CustomTags',
    unlocked = true,
    discovered = true,
    pos = {x = 0, y = 0},
    --    loc_vars = function(self, info_queue, tag)
    --        info_queue[#info_queue + 1] = G.P_CENTERS.p_standard_mega_1
    --    end,
    loc_txt = {
        name = 'Twitch Pack',
        text = {
            'Create a free',
            '{C:Purple}Twitch{} Booster.'
        }
    },
    apply = function(self, tag, context)
        if context.type == 'new_blind_choice' then
            local lock = tag.ID
            G.CONTROLLER.locks[lock] = true
            tag:yep('+', G.C.SECONDARY_SET.Spectral, function()
                local booster = SMODS.create_card {key = 'p_ttv_twitch_pack_1', area = G.play}
                booster.T.x = G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2
                booster.T.y = G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2
                booster.T.w = G.CARD_W * 1.27
                booster.T.h = G.CARD_H * 1.27
                booster.cost = 0
                booster.from_tag = true
                G.FUNCS.use_card({config = {ref_table = booster}})
                booster:start_materialize()
                G.CONTROLLER.locks[lock] = nil
                return true
            end)
            tag.triggered = true
            return true
        end
    end
}
