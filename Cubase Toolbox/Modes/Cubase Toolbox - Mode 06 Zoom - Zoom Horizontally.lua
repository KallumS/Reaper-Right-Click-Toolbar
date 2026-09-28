-- @description Cubase Toolbox - Zoom tool, Zoom Horizontally mode
-- @about
--   Switches the mouse to the Cubase-style "Zoom" tool in "Zoom Horizontally" mode.
--   Drag left/right to zoom in and out horizontally. Click to zoom in, Alt+click to zoom out.
--   Handy in a right-click submenu or on a toolbar; it lights up while active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "../lib/CubaseToolbox_core.lua")
toolbox.run_mode_action("zoom", "horizontal", section, cmd)
