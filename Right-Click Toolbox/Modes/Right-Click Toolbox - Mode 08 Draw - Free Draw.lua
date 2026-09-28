-- @description Right-Click Toolbox - Draw (Pencil) tool, Free Draw mode
-- @about
--   Switches the mouse to the Cubase-style "Draw (Pencil)" tool in "Free Draw" mode.
--   Draw automation and MIDI CC freehand.
--   Handy in a right-click submenu or on a toolbar; it lights up while active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "../lib/RightClickToolbox_core.lua")
toolbox.run_mode_action("draw", "free", section, cmd)
