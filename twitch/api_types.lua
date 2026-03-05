---@meta

---@class Pagination: table
---@field cursor string

---@class BanUserParams: table
---@field broadcaster_id string
---@field moderator_id string
---@field user_id string
---@field duration? number
---@field reason? string

---@class BanUserResponse: table
---@field broadcaster_id string
---@field moderator_id string
---@field user_id string
---@field created_at string
---@field end_time string

---@class GetStreamsParams: table
---@field user_id? string|string[]
---@field user_login? string|string[]
---@field game_id? string|string[]
---@field type? "all" | "live"
---@field language? string|string[]
---@field first? number
---@field before? string
---@field after? string

---@class GetStreamsResponse: table
---@field id string
---@field user_id string
---@field user_login string
---@field user_name string
---@field game_id string
---@field game_name string
---@field type "" | "live"
---@field title string
---@field tags string[]
---@field viewer_count number
---@field started_at string
---@field language string
---@field thumbnail_url string
---@field tag_ids string[]
---@field is_mature boolean

---@class GetUsersParams: table
---@field id? string|string[]
---@field login? string|string[]

---@class GetUsersResponse: table
---@field id string
---@field login string
---@field display_name string
---@field type "" | "admin" | "global_mod" | "staff"
---@field broadcaster_type "" | "affiliate" | "partner"
---@field description string
---@field profile_image_url string
---@field offline_image_url string
---@field view_count number
---@field email string
---@field created_at string
