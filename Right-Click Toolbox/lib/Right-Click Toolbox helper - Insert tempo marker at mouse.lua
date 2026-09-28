-- @description Right-Click Toolbox helper - Insert tempo marker at mouse
-- @about
--   Adds a tempo marker at the grid line nearest the mouse (Time Warp tool).
--   Used internally by the toolbox's mouse settings; you don't need to run it yourself.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "RightClickToolbox_core.lua")
toolbox.tempo_marker_at_mouse()
