# 2026-10-14 — The toolbox's words, to Apple's writing guidelines

Part of a sweep across all of the user's repositories, after Noterator's
decision 0053 (`KallumS/Noterator`, `docs/decisions/0053-*.md`). This repo has
no decision records, so the rules are kept here.

## The rules

- **Menu items** in title-style capitals, a verb first where they act: "Print
  Troubleshooting Report to Console", "Close Floating Toolbar After Picking a
  Tool", "About the Current Tool", "Zoom Modes", "(Active)". Short words — to,
  at, from, in, on, of, by, with, a, the, and, or — stay lower case: "Split at
  Mouse", "Zoom to Dragged Selection", "Play from Click", "Click Adds/Removes
  from Selection", "Drumstick (MIDI Editor)".
- **Help text, tooltips and console messages** in sentence case, full stops on
  sentences: "There’s no item to the right of this one to glue to."
- **Messages** say what happened, then what to do: a missing helper script
  now says to copy the whole folder back and run the installer; files the
  installer couldn’t add say where the folder must be.
- **Typography**: em dash between a tool and its mode ("Zoom — Zoom
  Vertically"), curly quotes and apostrophes. REAPER's own menu paths
  ("Options > Customize menus/toolbars...") are quoted as REAPER writes them.
- **Undo names** (what Edit > Undo shows) in title style: "Erase Item",
  "Split into Repeated Pieces", "Insert Tempo Marker".

## What was not changed, and why

- **No file was renamed.** Every script's file name is its REAPER action
  name, which people put on menus, toolbars and shortcuts. Mode file names
  were *generated from the mode labels* (`M.mode_file`), so retitling "Split
  At Mouse" would have made the installer look for a file that does not
  exist. Each retitled mode now carries its old label in `file`, and
  `mode_file` uses it. Checked headless: all 34 tool and mode files the core
  names still exist.
- **`@description` lines** match the file names and are left alone; the
  `@about` text took the new labels.
- **The troubleshooting report's body** stays as it was (but for one dash):
  it is meant to be pasted into a help request, and its wording is about
  REAPER's internals.
- **The `CubaseToolbox` ExtState keys** and every stored value are unchanged.
- **REAPER's message box** chooses its own buttons; only the text changed.

## Verification

There are no tests here and nothing runs outside REAPER, so: every script
passes `luac5.4 -p`; a scratch Lua harness with a mocked `reaper` and `gfx`
loaded the core, built the tool menu and the Zoom mode menu, picked "About
the Current Tool" by counting selectable items as `gfx.showmenu` does, and
got the help box ("Object Selection — Normal …"). Not yet run in REAPER.
