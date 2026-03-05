assert(SMODS.load_file("twitch/utils.lua"))()

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
