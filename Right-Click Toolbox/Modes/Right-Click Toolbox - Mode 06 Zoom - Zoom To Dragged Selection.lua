-- @description Right-Click Toolbox - Zoom tool, Zoom To Dragged Selection mode
-- @about
--   Switches the mouse to the Cubase-style "Zoom" tool in "Zoom To Dragged Selection" mode.
--   Drag a box to zoom into it. Click to zoom in, Alt+click to zoom out, centred on the mouse.
--   Handy in a right-click submenu or on a toolbar; it lights up while active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "../lib/RightClickToolbox_core.lua")
toolbox.run_mode_action("zoom", "box", section, cmd)
