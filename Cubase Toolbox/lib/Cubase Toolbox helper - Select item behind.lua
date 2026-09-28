-- @description Cubase Toolbox helper - Select item behind
-- @about
--   Selects the overlapping item underneath the one you click (Object tool, Select Objects Behind mode).
--   Used internally by the toolbox's mouse settings; you don't need to run it yourself.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "CubaseToolbox_core.lua")
toolbox.select_behind()
