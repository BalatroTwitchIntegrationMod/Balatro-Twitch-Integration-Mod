---@class Mod
local mod = SMODS.current_mod

---@class ChatMessage
---@field user_id string
---@field user_login string
---@field user_name string
---@field text string
---@field privileged boolean
---@field subscriber boolean

---@class ChatCommand
---@field anywhere? boolean
---@field restricted? boolean
---@field unprotected? boolean
---@field no_cooldown? boolean
---@field can_exec? fun(params: { arg: string, text: string, message: ChatMessage, extra: table }): boolean
---@field exec fun(params: { arg: string, text: string, message: ChatMessage, extra: table })

---@type { [string]: ChatCommand }
mod.commands = {}

local privileged_users = {
    chowder9o8 = true,
    jackmacwindows = true,
    korgeaux = true,
    mossloth_ = true,
}

local privileged_badges = {
    broadcaster = true,
    moderator = true,
    vip = true,
}

---@class ChatCommandRunner
local ChatCommandRunner = {}

---@param payload EventSubPayload
---@return ChatMessage
local function get_message_info(payload)
    local user_id = payload.event.chatter_user_id
    local user_login = payload.event.chatter_user_login
    local user_name = payload.event.chatter_user_name
    local text = payload.event.message.text
    local privileged = false
    local subscriber = false

    if privileged_users[user_login] then
        privileged = true
    end

    for _, badge in pairs(payload.event.badges) do
        if privileged_badges[badge.set_id] then
            privileged = true
        end

        if badge.set_id == "subscriber" then
            subscriber = true
        end
    end

    return {
        user_id = user_id,
        user_login = user_login,
        user_name = user_name,
        text = text,
        privileged = privileged,
        subscriber = subscriber,
    }
end

local cooldown_adjustment = 0
local last_cooldown_timestamp = nil

---@return boolean
local function is_on_cooldown()
    local current_time = os.time()

    if last_cooldown_timestamp == nil then
        last_cooldown_timestamp = current_time
        return false
    end

    local cooldown = tonumber(mod.config.cooldown_sec) + cooldown_adjustment

    if os.difftime(current_time, last_cooldown_timestamp) < cooldown then
        return true
    end

    -- +/- 10% of random cooldown adjustment to avoid chatters calculating exact times
    cooldown_adjustment = (math.random() - 0.5) * (cooldown * 0.2)
    last_cooldown_timestamp = current_time

    return false
end

---@param message ChatMessage
---@return boolean
local function check_protection(message)
    for _, joker in ipairs(SMODS.find_card("j_ttv_mods")) do
        joker.config.center:decrease_protections(joker)

        if not message.privileged then
            mod.twitch.api:ban_user({
                broadcaster_id = mod.twitch.user.id,
                moderator_id = mod.twitch.user.id,
                user_id = message.user_id,
                duration = 60,
                reason = "Balatro Twitch Integration"
            })
        end

        return true
    end

    return false
end

---@param payload EventSubPayload
function ChatCommandRunner:message(payload)
    local message = get_message_info(payload)

    local command, rest = string.match(message.text, "!([^%s]+)%s?(.*)")

    if command == "__default__" then
        return
    end

    if not command then
        command = "__default__"
        rest = message.text
    end

    local cmd = mod.commands[string.lower(command)]

    if not (cmd and cmd.exec) then
        return
    end

    if not cmd.anywhere and G.STAGE ~= G.STAGES.RUN and G.GAME then
        return
    end

    if cmd.restricted and not message.privileged then
        return
    end

    local params = {
        arg = string.match(rest, "[^%s]*"),
        text = rest,
        message = message,
        extra = {}
    }

    if cmd.can_exec and not cmd.can_exec(params) then
        return
    end

    if not cmd.no_cooldown and is_on_cooldown() then
        return
    end

    if cmd.unprotected or not check_protection(message) then
        cmd.exec(params)
    end
end

---@param payload EventSubPayload
function ChatCommandRunner:ban(payload)
    if payload.event.is_permanent then
        for _, joker in ipairs(SMODS.find_card("j_ttv_thebanhammer")) do
            joker.config.center:apply_ban(joker, payload.event.user_id)
        end
    end
end

local nativefs = require("nativefs")

local function load_commands()
    local commands_path = "commands/"
    local full_commands_path = mod.path .. commands_path

    local entries = nativefs.getDirectoryItems(full_commands_path)

    for _, entry in pairs(entries) do
        local info = nativefs.getInfo(full_commands_path .. entry)
        if info.type == "file" and string.find(entry, ".+%.lua$") then
            assert(SMODS.load_file(commands_path .. entry))()
        end
    end
end

load_commands()

return ChatCommandRunner
