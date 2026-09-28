-- @description Cubase Toolbox - Split (Scissors) tool, Split At Mouse mode
-- @about
--   Switches the mouse to the Cubase-style "Split (Scissors)" tool in "Split At Mouse" mode.
--   Click an item (or MIDI note) to split it at the mouse.
--   Handy in a right-click submenu or on a toolbar; it lights up while active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "../lib/CubaseToolbox_core.lua")
toolbox.run_mode_action("split", "mouse", section, cmd)
