---@class Twitch
---@field auth TwitchAuth
---@field api TwitchApi
---@field chat TwitchChat
local Twitch = {
    auth = require("twitch.auth"),
    api = require("twitch.api"),
    chat = require("twitch.chat"),
}

return Twitch
