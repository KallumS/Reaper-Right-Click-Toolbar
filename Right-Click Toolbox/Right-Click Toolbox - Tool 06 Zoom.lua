-- @description Right-Click Toolbox - Zoom tool
-- @about
--   Switches the mouse to the Cubase-style "Zoom" tool.
--   Modes: Zoom To Dragged Selection, Zoom Horizontally, Zoom Vertically.
--   Click this button again while the tool is active to pick a mode.
--   Put this on a toolbar button, a menu or a keyboard shortcut; it lights
--   up while the tool is active. If it's on a floating toolbar, that toolbar
--   closes once you've picked the tool (switch this off in the tool menu).

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "lib/RightClickToolbox_core.lua")
toolbox.run_tool_action("zoom", section, cmd)
