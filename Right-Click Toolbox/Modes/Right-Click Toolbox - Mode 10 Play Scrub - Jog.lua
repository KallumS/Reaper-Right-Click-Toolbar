-- @description Right-Click Toolbox - Play / Scrub tool, Jog mode
-- @about
--   Switches the mouse to the Cubase-style "Play / Scrub" tool in "Jog" mode.
--   Drag to play forwards (or backwards) at your own speed. In the MIDI editor, drag to hear notes.
--   Handy in a right-click submenu or on a toolbar; it lights up while active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "../lib/RightClickToolbox_core.lua")
toolbox.run_mode_action("play", "jog", section, cmd)
