-- @description Right-Click Toolbox - Split (Scissors) tool, Split All Selected Items mode
-- @about
--   Switches the mouse to the Cubase-style "Split (Scissors)" tool in "Split All Selected Items" mode.
--   Click to split the clicked item and every selected item at that position.
--   Handy in a right-click submenu or on a toolbar; it lights up while active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "../lib/RightClickToolbox_core.lua")
toolbox.run_mode_action("split", "selected", section, cmd)
