-- @description Cubase Toolbox - Draw (Pencil) tool
-- @about
--   Switches the mouse to the Cubase-style "Draw (Pencil)" tool.
--   Put this on a toolbar button or a keyboard shortcut; the button lights up
--   while the tool is active.

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "lib/CubaseToolbox_core.lua")
toolbox.remember_script("draw", section, cmd)
toolbox.set_tool("draw")
