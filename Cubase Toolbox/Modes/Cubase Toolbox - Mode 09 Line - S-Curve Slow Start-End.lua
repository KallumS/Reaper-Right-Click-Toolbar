-- @description Cubase Toolbox - Line tool, S-Curve (Slow Start/End) mode
-- @about
--   Switches the mouse to the Cubase-style "Line" tool in "S-Curve (Slow Start/End)" mode.
--   Ramps that ease in and ease out, like a sine.
--   Handy in a right-click submenu or on a toolbar; it lights up while active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "../lib/CubaseToolbox_core.lua")
toolbox.run_mode_action("line", "scurve", section, cmd)
