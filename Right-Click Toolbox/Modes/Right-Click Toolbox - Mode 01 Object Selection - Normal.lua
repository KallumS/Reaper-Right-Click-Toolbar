-- @description Right-Click Toolbox - Object Selection tool, Normal mode
-- @about
--   Switches the mouse to the Cubase-style "Object Selection" tool in "Normal" mode.
--   REAPER's normal behaviour, with all your own settings.
--   Handy in a right-click submenu or on a toolbar; it lights up while active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "../lib/RightClickToolbox_core.lua")
toolbox.run_mode_action("select", "normal", section, cmd)
