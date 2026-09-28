-- @description Cubase Toolbox helper - Glue item under mouse to next
-- @about
--   Joins the item under the mouse to the next item on its track (Glue tool).
--   Used internally by the toolbox's mouse settings; you don't need to run it yourself.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "CubaseToolbox_core.lua")
toolbox.glue_item_under_mouse()
