-- @description Right-Click Toolbox helper - Mute item under mouse
-- @about
--   Mutes/unmutes the item under the mouse (Mute tool).
--   Used internally by the toolbox's mouse settings; you don't need to run it yourself.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "RightClickToolbox_core.lua")
toolbox.mute_item_under_mouse()
