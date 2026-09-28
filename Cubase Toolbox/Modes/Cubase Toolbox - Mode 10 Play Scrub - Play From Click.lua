-- @description Cubase Toolbox - Play / Scrub tool, Play From Click mode
-- @about
--   Switches the mouse to the Cubase-style "Play / Scrub" tool in "Play From Click" mode.
--   Click to play from that point, click again to stop. In the MIDI editor, drag to hear notes.
--   Handy in a right-click submenu or on a toolbar; it lights up while active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "../lib/CubaseToolbox_core.lua")
toolbox.run_mode_action("play", "click", section, cmd)
