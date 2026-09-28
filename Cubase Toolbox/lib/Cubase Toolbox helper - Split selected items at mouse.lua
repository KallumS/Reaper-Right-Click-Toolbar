-- @description Cubase Toolbox helper - Split selected items at mouse
-- @about
--   Splits the clicked item and all selected items at the mouse (Split tool, Split All Selected Items mode).
--   Used internally by the toolbox's mouse settings; you don't need to run it yourself.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "CubaseToolbox_core.lua")
toolbox.split_selected_at_mouse()
