-- @description Cubase Toolbox - Split (Scissors) tool
-- @about
--   Switches the mouse to the Cubase-style "Split (Scissors)" tool.
--   Put this on a toolbar button or a keyboard shortcut; the button lights up
--   while the tool is active. If it's on a floating toolbar, that toolbar
--   closes once you've picked the tool (switch this off in the tool menu).

if reaper.set_action_options then reaper.set_action_options(3) end
local _, file, section, cmd = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "lib/CubaseToolbox_core.lua")
toolbox.run_tool_action("split", section, cmd)
