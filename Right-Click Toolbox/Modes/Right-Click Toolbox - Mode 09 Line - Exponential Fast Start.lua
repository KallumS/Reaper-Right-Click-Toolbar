-- @description Right-Click Toolbox - Line tool, Exponential (Fast Start) mode
-- @about
--   Switches the mouse to the Cubase-style "Line" tool in "Exponential (Fast Start)" mode.
--   Ramps that change quickly at first, then level off.
--   Handy in a right-click submenu or on a toolbar; it lights up while active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "../lib/RightClickToolbox_core.lua")
toolbox.run_mode_action("line", "fast", section, cmd)
