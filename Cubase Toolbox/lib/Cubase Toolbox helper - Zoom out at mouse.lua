-- @description Cubase Toolbox helper - Zoom out at mouse
-- @about
--   Zooms out around the mouse (Zoom tool).
--   Used internally by the toolbox's mouse settings; you don't need to run it yourself.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "CubaseToolbox_core.lua")
toolbox.zoom_at_mouse(0.5)
