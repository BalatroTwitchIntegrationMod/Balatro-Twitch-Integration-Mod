local function defuse_button(card)
  return UIBox {
    definition = {
      n = G.UIT.ROOT,
      config = {
        colour = G.C.CLEAR
      },
      nodes = {
        {
          n = G.UIT.C,
          config = {
            align = 'cm',
            padding = 0.15,
            r = 0.08,
            hover = true,
            shadow = true,
            colour = G.C.MULT,                  -- color of the button background
            button = 'ttv_defuse_button_click', -- function in G.FUNCS that will run when this button is clicked
            func = 'ttv_defuse_button_func',    -- function in G.FUNCS that will run every frame this button exists (optional)
            ref_table = card
          },
          nodes = {
            {
              n = G.UIT.R,
              nodes = {
                {
                  n = G.UIT.T,
                  config = {
                    text = "Defuse",
                    colour = G.C.UI.TEXT_LIGHT, -- color of the button text
                    scale = 0.4
                  }
                },
                {
                  n = G.UIT.B,
                  config = {
                    w = 0.1,
                    h = 0.8
                  }
                }
              }
            }
          }
        }
      }
    },
    config = {
      align = 'cr', -- position relative to the card, meaning "center left". Follow the SMODS UI guide for more alignment options
      major = card,
      parent = card,
      offset = {x = -0.2, y = 0.1}   -- depends on the alignment you want, without an offset the button will look as if floating next to the card, instead of behind it
    }
  }
end

-- Will be called whenever the button is clicked
G.FUNCS.ttv_defuse_button_click = function(e)
  local card = e.config.ref_table -- access the card this button was on
  play_sound("ttv_bomb_explosion", 1.0, 0.7)
  SMODS.destroy_cards(card, true, true)
  G.E_MANAGER:add_event(Event({
    trigger = 'after',
    delay = 0.5,
    func = function()
      if G.STAGE == G.STAGES.RUN then
        G.STATE = G.STATES.GAME_OVER
        G.STATE_COMPLETE = false
      end
    end
  }))
  -- Show a message on the card, as an example
  SMODS.calculate_effect({message = "Hi!"}, card)
end

-- Will run every frame while the button exists
G.FUNCS.ttv_defuse_button_func = function(e)
  local card = e.config.ref_table -- access the card this button was on (unused here, but you can access it)

  -- In vanilla, this is generally used to define when the button can be used, for example:
  local can_use = true -- can be any condition you want

  -- Removes the button when the card can't be used, otherwise makes it use the previously defined button click
  e.config.button = can_use and 'ttv_defuse_button_click' or nil
  -- Changes the color of the button depending on whether it can be used or not
  e.config.colour = can_use and G.C.MULT or G.C.UI.BACKGROUND_INACTIVE
end


SMODS.draw_ignore_keys.ttv_bomb_button = true


local highlight_ref = Card.highlight
function Card.highlight(self, is_highlighted)
  if is_highlighted and self.config.center.key == 'j_ttv_bomb' and self.area == G.jokers then
    self.children.ttv_bomb_button = defuse_button(self)
  elseif self.children.ttv_bomb_button then
    self.children.ttv_bomb_button:remove()
    self.children.ttv_bomb_button = nil
  end

  return highlight_ref(self, is_highlighted)
end
