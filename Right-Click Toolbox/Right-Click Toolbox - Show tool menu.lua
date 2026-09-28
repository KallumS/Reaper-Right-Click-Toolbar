-- @description Right-Click Toolbox - Show tool menu
-- @about
--   Pops up the Cubase-style toolbox at the mouse cursor.
--   Add it to REAPER's right-click menus (see README) or give it a shortcut.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "lib/RightClickToolbox_core.lua")
toolbox.show_menu()
