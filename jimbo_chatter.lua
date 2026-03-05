---@class JimboChatter: Moveable
JimboChatter = Moveable:extend()

---@param args {x: number, y: number, w: number, h: number}
function JimboChatter:init(args)
    Moveable.init(self, args.x or 1, args.y or 1, args.w or G.CARD_W * 1.1, args.h or G.CARD_H * 1.1)

    self.children = {}

    self.talking = false
    self.removed = false

    self.config = {
        colours = {G.C.PURPLE, G.C.WHITE, G.C.BLACK, G.C.WHITE}
    }

    self.children.card = Card(self.T.x, self.T.y, G.CARD_W, G.CARD_H, G.P_CARDS.empty, G.P_CENTERS["j_ttv_oneguy"], {bypass_discovery_center = true})
    self.children.card.states.visible = false
    self.children.card:set_alignment({major = self, type = "cm", offset = {x = 0, y = 0}})
    self.children.card.states.collide.can = false
    self.children.card.states.focus.can = false
    self.children.card.states.hover.can = true
    self.children.card.states.drag.can = false
    self.children.card.hover = Node.hover

    if getmetatable(self) == JimboChatter then
        table.insert(G.I.CARD, self)
    end
end

function JimboChatter:say(text)
    if self.talking or self.removed then
        return
    end

    self.talking = true

    if self.children.speech_bubble then
        self.children.speech_bubble:remove()
    end
    self.children.speech_bubble = UIBox({
        definition = G.UIDEF.speech_bubble("ttv_chatter", {text, quip = true}),
        config = {align = "cr", offset = {x = 0, y = 0}, parent = self}
    })
    self.children.speech_bubble:set_role({
        role_type = "Minor",
        xy_bond = "Weak",
        r_bond = "Strong",
        major = self
    })

    if self.children.particles then
        self.children.particles:remove()
    end
    self.children.particles = Particles(0, 0, 0, 0, {
        timer = 0.03,
        scale = 0.3,
        speed = 1.2,
        lifespan = 2,
        attach = self,
        colours = self.config.colours,
        fill = true
    })
    self.children.particles.static_rotation = true
    self.children.particles:set_role({
        role_type = "Minor",
        xy_bond = "Weak",
        r_bond = "Strong",
        major = self
    })
    self.children.speech_bubble.states.visible = false

    if self.children.card then
        self.children.card:start_materialize(self.config.colours, false, G.SPEEDFACTOR * 0.8)
    end

    G.E_MANAGER:add_event(Event({
        blocking = false,
        blockable = false,
        delay = G.SPEEDFACTOR * 0.8,
        trigger = "after",
        func = function(n)
            if self.children.speech_bubble then
                self.children.speech_bubble.states.visible = true
                play_sound("voice" .. math.random(1, 11), G.SPEEDFACTOR * (math.random() * 0.2 + 1), 0.5)
            end
            if self.children.card then
                self.children.card:juice_up()
            end
            return true
        end
    }))

    G.E_MANAGER:add_event(Event({
        blocking = false,
        blockable = false,
        delay = G.SPEEDFACTOR * 4.8,
        trigger = "after",
        func = function(n)
            self:hide()
            return true
        end
    }))
end

function JimboChatter:hide()
    if not self.talking or self.removed then
        return
    end

    if self.children.speech_bubble then
        self.children.speech_bubble.states.visible = false
    end

    if self.children.particles then
        self.children.particles:fade(0.8, 1)
    end

    if self.children.card then
        self.children.card:start_dissolve(self.config.colours, false, G.SPEEDFACTOR * 0.8)
    end

    G.E_MANAGER:add_event(Event({
        blocking = false,
        blockable = false,
        delay = G.SPEEDFACTOR * 0.8,
        trigger = "after",
        func = function(n)
            self.talking = false
            self:remove()
            return true
        end
    }))
end

function JimboChatter:move(dt)
    Moveable.move(self, dt)
end

function JimboChatter:draw()
    if self.children.particles then
        self.children.particles:draw()
    end

    if self.children.speech_bubble then
        self.children.speech_bubble:draw()
    end

    if self.children.card then
        self.children.card:draw()
    end

    add_to_drawhash(self)

    self:draw_boundingrect()
end

function JimboChatter:remove()
    if self.removed then
        return
    end

    self.removed = true

    remove_all(self.children)

    for k, v in pairs(G.I.CARD) do
        if v == self then
            table.remove(G.I.CARD, k)
        end
    end

    Moveable.remove(self)
end
