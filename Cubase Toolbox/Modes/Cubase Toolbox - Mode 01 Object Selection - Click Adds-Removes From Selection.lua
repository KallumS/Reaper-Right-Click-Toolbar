-- @description Cubase Toolbox - Object Selection tool, Click Adds/Removes From Selection mode
-- @about
--   Switches the mouse to the Cubase-style "Object Selection" tool in "Click Adds/Removes From Selection" mode.
--   Clicking an item adds it to the selection, or removes it if it's already selected.
--   Handy in a right-click submenu or on a toolbar; it lights up while active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "../lib/CubaseToolbox_core.lua")
toolbox.run_mode_action("select", "toggle", section, cmd)
