---@class Mod
local mod = SMODS.current_mod

if not mod.utils then
    mod.utils = {}
end

mod.utils.url = assert(SMODS.load_file("twitch/url.lua"))()
mod.utils.secure_socket = assert(SMODS.load_file("twitch/ssl.lua"))()

---@class Twitch
---@field auth TwitchAuth
---@field api TwitchApi
---@field chat TwitchChat
local Twitch = {
    auth = assert(SMODS.load_file("twitch/auth.lua"))();
    api = assert(SMODS.load_file("twitch/api.lua"))();
    chat = assert(SMODS.load_file("twitch/chat.lua"))();
}

return Twitch
