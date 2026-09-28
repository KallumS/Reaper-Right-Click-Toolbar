-- @description Right-Click Toolbox helper - Zoom in at mouse
-- @about
--   Zooms in around the mouse (Zoom tool).
--   Used internally by the toolbox's mouse settings; you don't need to run it yourself.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "RightClickToolbox_core.lua")
toolbox.zoom_at_mouse(2)
