-- @description Cubase Toolbox - Install (run once)
-- @about
--   Adds every Cubase Toolbox script to REAPER's Action List (main window and
--   MIDI editor), so they can be put on menus, toolbars and shortcuts.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "lib/CubaseToolbox_core.lua")

local registered, failed = toolbox.install()

local msg = "Cubase Toolbox is installed (" .. registered .. " actions added).\n\n" ..
  "Next step - make it appear when you right-click:\n" ..
  "1. Options > Customize menus/toolbars...\n" ..
  "2. In the list at the top-left pick 'Ruler/arrange context'.\n" ..
  "3. Click Add... > Action..., search for 'Cubase Toolbox', and add the tools\n" ..
  "   (or just 'Cubase Toolbox - Show tool menu').\n" ..
  "4. Do the same for 'Media item context' and the MIDI editor menus if you like.\n" ..
  "5. Click Save.\n\n" ..
  "See README.md for the full guide."
if #failed > 0 then
  msg = msg .. "\n\nThese files could not be added:\n" .. table.concat(failed, "\n")
end
reaper.ShowMessageBox(msg, toolbox.NAME, 0)
