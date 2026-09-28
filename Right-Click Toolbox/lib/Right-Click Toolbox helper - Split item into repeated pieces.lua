-- @description Right-Click Toolbox helper - Split item into repeated pieces
-- @about
--   Cuts the clicked item into repeated pieces (Split tool, Alt+click).
--   Used internally by the toolbox's mouse settings; you don't need to run it yourself.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "RightClickToolbox_core.lua")
toolbox.split_repeat_at_mouse()
