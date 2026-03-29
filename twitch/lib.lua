---@class Twitch
local Twitch = {
    auth = require("twitch.auth"),
    api = require("twitch.api"),
    eventsub = require("twitch.eventsub"),
}

return Twitch
