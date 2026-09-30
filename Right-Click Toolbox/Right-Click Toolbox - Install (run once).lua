-- @description Right-Click Toolbox - Install (run once)
-- @about
--   Adds every Right-Click Toolbox script to REAPER's Action List (main window and
--   MIDI editor), so they can be put on menus, toolbars and shortcuts.

local _, file = reaper.get_action_context()
local toolbox = dofile(file:match("^(.*[/\\])") .. "lib/RightClickToolbox_core.lua")

local registered, failed = toolbox.install()

local msg = "Right-Click Toolbox is installed (" .. registered .. " actions added).\n\n" ..
  "Next, choose how you want to pick tools (you can set up both):\n\n" ..
  "RIGHT-CLICK MENU\n" ..
  "  Options > Customize menus/toolbars... > 'Ruler/arrange context'\n" ..
  "  > Add... > Action... > search 'Right-Click Toolbox - Tool' > add them > Save.\n\n" ..
  "FLOATING TOOLBAR AT THE MOUSE\n" ..
  "  Options > Customize menus/toolbars... > 'Floating toolbar 1'\n" ..
  "  > add the 'Right-Click Toolbox - Tool' actions > Save.\n" ..
  "  Then in the Actions window, give 'Toolbar: Open/close toolbar 1 at\n" ..
  "  mouse cursor' a shortcut.\n\n" ..
  "README.md has step-by-step instructions for both."
if #failed > 0 then
  msg = msg .. "\n\nThese files could not be added:\n" .. table.concat(failed, "\n")
end
reaper.ShowMessageBox(msg, toolbox.NAME, 0)
