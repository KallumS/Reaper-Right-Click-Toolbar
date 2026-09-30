-- @description Right-Click Toolbox helper - Select items under mouse on all tracks
-- @about
--   Selects every item under the mouse, on all tracks (Object tool, Select Events Under Cursor mode).
--   Used internally by the toolbox's mouse settings; you don't need to run it yourself.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "RightClickToolbox_core.lua")
toolbox.select_at_mouse()
