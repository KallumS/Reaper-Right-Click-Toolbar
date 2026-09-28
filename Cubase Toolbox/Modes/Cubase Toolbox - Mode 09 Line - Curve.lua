-- @description Cubase Toolbox - Line tool, Curve mode
-- @about
--   Switches the mouse to the Cubase-style "Line" tool in "Curve" mode.
--   Smooth curved ramps (bezier) you can bend afterwards.
--   Handy in a right-click submenu or on a toolbar; it lights up while active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "../lib/CubaseToolbox_core.lua")
toolbox.run_mode_action("line", "curve", section, cmd)
