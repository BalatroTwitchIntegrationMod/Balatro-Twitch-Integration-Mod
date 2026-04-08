---@class TTVPlayAreaHelp: Moveable
TTVPlayAreaHelp = Moveable:extend()

---@param text string|string[]
---@param scale number?
local function help_uidef(text, scale)
    text = type(text) == "table" and text or { text }

    local text_nodes = {}

    for _, v in pairs(text) do
        table.insert(text_nodes, {
            n = G.UIT.R,
            config = {},
            nodes = { { n = G.UIT.T, config = { text = v, colour = G.C.WHITE, scale = scale or 0.4 } } }
        })
    end

    ---@type UINode
    local uidef = {
        n = G.UIT.ROOT,
        config = { align = "cm", colour = G.C.BLACK, padding = 0.1, r = 0.05 },
        nodes = { {
            n = G.UIT.C,
            config = {},
            nodes = text_nodes
        } }
    }

    return uidef
end

---@param args { jokers?: string, consumables?: string, hand?: string, buttons?: string }
function TTVPlayAreaHelp:init(args)
    Moveable.init(self)

    self.children = {}

    self.children.cta = UIBox {
        definition = help_uidef("Type commands in the chat NOW!", 0.6),
        config = { parent = self, align = "tm", major = G.jokers, can_collide = false, offset = { x = 0, y = -0.2 } }
    }

    if args.jokers then
        self.children.jokers = UIBox {
            definition = help_uidef(args.jokers),
            config = { parent = self, align = "bm", major = G.jokers, can_collide = false, offset = { x = 0, y = 0.2 } }
        }
    end

    if args.consumables then
        self.children.consumables = UIBox {
            definition = help_uidef(args.consumables),
            config = { parent = self, align = "bm", major = G.consumeables, can_collide = false, offset = { x = 0, y = 0.2 } }
        }
    end

    if args.hand then
        self.children.hand = UIBox {
            definition = help_uidef(args.hand),
            config = { parent = self, align = "tm", major = G.hand, can_collide = false, offset = { x = 0, y = -0.6 } }
        }
    end

    if args.buttons then
        self.children.buttons = UIBox {
            definition = help_uidef(args.buttons),
            config = { parent = self, align = "bm", major = G.buttons, can_collide = false, offset = { x = 0, y = 0.2 } }
        }
        self.children.buttons.states.visible = G.buttons ~= nil
    end

    self.attention_text = true

    if getmetatable(self) == TTVPlayAreaHelp then
        table.insert(G.I.UIBOX, self)
    end
end

function TTVPlayAreaHelp:update(dt)
    self.states.visible = G.STATE == G.STATES.SELECTING_HAND

    if self.children.buttons and G.buttons then
        self.children.buttons.states.visible = G.buttons.states.visible

        if self.children.buttons:get_major() ~= G.buttons then
            self.children.buttons:set_alignment({ major = G.buttons })
            self.children.buttons:align_to_major()
            self.children.buttons:hard_set_VT()
        end
    end
end

function TTVPlayAreaHelp:remove()
    remove_all(self.children)

    for k, v in pairs(G.I.UIBOX) do
        if v == self then
            table.remove(G.I.UIBOX, k)
        end
    end

    Moveable.remove(self)
end

return TTVPlayAreaHelp
