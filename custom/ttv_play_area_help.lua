---@class TTVPlayAreaHelp: Moveable
TTVPlayAreaHelp = Moveable:extend()

---@param text string | string[]
---@param hint? string[]
---@param scale? number
local function help_uidef(text, hint, scale)
    text = type(text) == "table" and text or { text }

    local lines = {}

    for _, v in pairs(text) do
        if type(v) == "table" and #v == 2 then
            local line = { n = G.UIT.R, config = { align = "cl", padding = 0.02 }, nodes = {} }

            table.insert(line.nodes, {
                n = G.UIT.C,
                config = { align = "cr", minw = 0.5 },
                nodes = { {
                    n = G.UIT.R,
                    config = {},
                    nodes = { { n = G.UIT.T, config = { text = v[1], colour = G.C.WHITE, scale = scale or 0.3 } } }
                } }
            })
            table.insert(line.nodes, {
                n = G.UIT.C,
                config = {},
                nodes = { { n = G.UIT.T, config = { text = " - ", colour = G.C.UI.TEXT_INACTIVE, scale = scale or 0.3 } } }
            })
            table.insert(line.nodes, {
                n = G.UIT.C,
                config = {},
                nodes = { {
                    n = G.UIT.R,
                    config = {},
                    nodes = { { n = G.UIT.T, config = { text = v[2], colour = G.C.WHITE, scale = scale or 0.3 } } }
                } }
            })

            table.insert(lines, line)
        elseif type(v) == "string" then
            local line = { n = G.UIT.R, config = { align = "cm" }, nodes = {} }

            table.insert(line.nodes, {
                n = G.UIT.C,
                config = { padding = 0.1, align = "cm" },
                nodes = { { n = G.UIT.T, config = { text = v, colour = G.C.JOKER_GREY, scale = scale or 0.3 } } }
            })

            table.insert(lines, line)
        end
    end


    if hint then
        local line = { n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = { { n = G.UIT.C, config = {}, nodes = {} } } }

        for _, v in pairs(hint) do
            table.insert(line.nodes[1].nodes, {
                n = G.UIT.R,
                config = { align = "cm" },
                nodes = { { n = G.UIT.T, config = { text = v, colour = G.C.GOLD, scale = 0.3 } } }
            })
        end

        table.insert(lines, line)
    end

    ---@type UINode
    local uidef = {
        n = G.UIT.ROOT,
        config = { align = "cm", colour = G.C.UI.HOVER, hover = true, padding = 0.12, r = 0.05 },
        nodes = { {
            n = G.UIT.C,
            config = {},
            nodes = lines
        } }
    }

    return uidef
end

---@param args { header?: string, contents?: string|string[], hint?: string[] }
function TTVPlayAreaHelp:init(args)
    Moveable.init(self)

    self.children = {}

    if args.header then
        self.children.header = UIBox {
            definition = help_uidef(args.header, nil, 0.55),
            config = { parent = self, align = "tmi", major = G.ROOM_ATTACH, can_collide = false, offset = { x = 0.0, y = 2.9 } }
        }
    end

    if args.contents then
        self.children.contents = UIBox {
            definition = help_uidef(args.contents, args.hint),
            config = { parent = self, align = "cri", major = G.ROOM_ATTACH, can_collide = false, offset = { x = 0.5, y = 0.0 } }
        }
    end

    self.attention_text = true

    if getmetatable(self) == TTVPlayAreaHelp then
        table.insert(G.I.UIBOX, self)
    end
end

function TTVPlayAreaHelp:update(dt)
    self.states.visible = G.STATE == G.STATES.SELECTING_HAND
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
