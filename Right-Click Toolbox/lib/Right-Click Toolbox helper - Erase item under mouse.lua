-- @description Right-Click Toolbox helper - Erase item under mouse
-- @about
--   Deletes the item under the mouse (Eraser tool).
--   Used internally by the toolbox's mouse settings; you don't need to run it yourself.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "RightClickToolbox_core.lua")
toolbox.erase_item_under_mouse()
