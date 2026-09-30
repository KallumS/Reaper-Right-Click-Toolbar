-- @description Right-Click Toolbox helper - Play from mouse
-- @about
--   Plays from the mouse position, or stops if already playing (Play tool, Play From Click mode).
--   Used internally by the toolbox's mouse settings; you don't need to run it yourself.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "RightClickToolbox_core.lua")
toolbox.play_from_mouse()
