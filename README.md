# Cubase Toolbox for REAPER

A set of ReaScripts that give REAPER a **Cubase-style right-click toolbox**:
right-click, pick a tool (Draw, Eraser, Split, Glue, Mute, Zoom…), and your
left mouse button now works like that Cubase tool until you pick another one.

## How it works

REAPER doesn't have "tools" the way Cubase does. What a click or drag does is
set by **mouse modifiers** (*Options > Preferences > Editing Behavior > Mouse
Modifiers*). Scripts can change these settings.

Picking a tool changes the plain click and drag settings (no Shift, Ctrl or
Alt held) in the places that tool needs, like items, empty track space,
automation and the MIDI editor. For example:

| You pick… | The script tells REAPER… |
|---|---|
| **Eraser** | clicking an item deletes it, clicking a MIDI note erases it, clicking an automation point deletes it |
| **Draw** | dragging on an empty track draws a new MIDI item, dragging on automation draws freehand, and so on |
| **Object Selection** | put every setting back exactly how it was before |

Before any setting is changed, your own setting is saved. Choosing **Object
Selection** puts all of them back, even if you had customised them.

## Installing

1. In REAPER choose **Options > Show REAPER resource path in explorer/finder**.
2. Open the **Scripts** folder there and copy the whole **`Cubase Toolbox`**
   folder into it.
3. In REAPER open the **Actions** window (press `?`), click
   **New action… > Load ReaScript…** and choose
   **`Cubase Toolbox - Install (run once).lua`**.
4. Select it in the list and click **Run**. This adds every tool to REAPER's
   action list for the main window and the MIDI editor.

### Making it appear on right-click

1. **Options > Customize menus/toolbars…**
2. In the drop-down at the top-left choose **Ruler/arrange context**. This is
   the menu you get when you right-click empty space in the arrange view.
3. Click **Add… > Action…**, type `Cubase Toolbox` in the filter box, and add
   the tools you want. You can also add only **Cubase Toolbox - Show tool
   menu**, which opens a small toolbox at the mouse.
4. Drag the new entries to the top of the list so they sit first, like in
   Cubase. Tick **Include default menu as submenu** so REAPER's normal
   right-click commands stay available.
5. Repeat for **Media item context** (right-clicking an item). In the MIDI
   editor, do the same for its menus, which have names starting with "MIDI".
6. Click **Save**.

The tool that's active has a tick next to it in the menu.

### Other ways to switch tools

- **Keyboard shortcuts.** In the Actions window, select a tool and click
  **Add…** under Shortcuts. Cubase uses the number keys 1–9. REAPER already
  uses some of those keys, so pick ones you don't use.
- **Toolbar buttons.** Add the tool actions to a toolbar. The active tool's
  button lights up.

## The tools

| Cubase tool | What it does in REAPER | Notes |
|---|---|---|
| **Object Selection** | REAPER's normal behaviour: select, move, resize, copy and trim | Puts back all your original settings |
| **Sizing Applies Time Stretch** | Like Object Selection, but dragging an audio item's edge time-stretches it | |
| **Range Selection** | Drag to select a time range across tracks (REAPER's *razor edit*) | Best in REAPER 7 |
| **Split (Scissors)** | Click an item to split it at the mouse. In the MIDI editor, click a note to split it | |
| **Glue** | Click an item to join it to the next item on the same track | See the glue note below |
| **Eraser** | Click to delete items, MIDI notes, CC events and automation points. Drag to erase notes in the MIDI editor | |
| **Zoom** | Drag a box to zoom into it. Click to zoom in, **Alt+click** to zoom out, centred on the mouse | |
| **Mute** | Click items or MIDI notes to mute or unmute them. Clicking a selected item mutes every selected item | |
| **Draw (Pencil)** | Drag on an empty track to draw a MIDI item. Draw automation freehand. Draw MIDI notes and CC data | |
| **Line** | MIDI editor: draw straight ramps of CC and velocity, or a straight line of notes. Automation: click to add points joined by straight lines | Only straight lines, no curves |
| **Play / Scrub** | Drag to scrub audio like tape. In the MIDI editor, drag to hear notes | Needs REAPER 7 |
| **Hand** | Drag to scroll around the project without changing the zoom | Needs REAPER 7 |
| **Drumstick** | MIDI editor: click or drag to paint hits, click an existing hit to remove it | |
| **Time Warp** | Click to add a tempo marker at the nearest grid line. Drag tempo markers in the ruler to line the grid up with your audio; the tempo before the marker adjusts to fit | See the time warp note below |

**Glue.** MIDI items are joined into one MIDI item, and no audio is rendered.
For audio, pieces of a clip that you split are joined back together without
making a new audio file. REAPER can't join two *different* audio recordings
into one item without bouncing, so in that case the two items are **grouped**
instead: they move together, and nothing is bounced.

**Time Warp.** To keep audio where it is while you move the grid, set its
timebase to *Time*. For items, use *Item properties > Timebase*. For the whole
project, use *Project settings > Timebase*.

## Things that work differently from Cubase

- **The mouse pointer doesn't change shape.** REAPER doesn't let scripts do
  that. Instead, a small "Tool: …" label appears by the mouse when you switch,
  and the active tool is ticked in the menu and lit on toolbars.
- **The Eraser can't wipe out several items with one drag.** Click each item.
  In the MIDI editor, dragging does erase several notes.
- **Holding Shift, Ctrl or Alt keeps REAPER's normal behaviour** in every
  tool, except Alt+click with the Zoom tool.
- **Switching tools isn't an undo step.** Undo only affects your edits.

## If something isn't right

- Right-click, open the toolbox, and choose **Troubleshooting report**. It
  prints the toolbox's current state to REAPER's console window. If you ask
  for help, copy that text into your message.
- If a tool can only partly switch on (for example, an older REAPER is
  missing a feature), a message in the console lists what didn't work. The
  rest of the tool still works.
- **Choose Object Selection** to put every setting back.
- Last resort: in *Preferences > Mouse modifiers*, use the **Import/Export**
  button to restore factory defaults. This also clears your own
  customisations.

## Requirements

- REAPER 6 or newer. **REAPER 7 or newer** is needed for Hand and
  Play/Scrub, and is recommended for Range Selection.
- No extensions are needed. With the optional
  [js_ReaScriptAPI](https://forum.cockos.com/showthread.php?t=212174)
  extension, the pop-up menu opens a little more smoothly on Windows.

## Files

```
Cubase Toolbox/
  Cubase Toolbox - Install (run once).lua   adds everything to the action list
  Cubase Toolbox - Show tool menu.lua       the pop-up toolbox
  Cubase Toolbox - Tool 01 … 14 ….lua       one action per tool (for menus, shortcuts, toolbars)
  lib/CubaseToolbox_core.lua                the engine: tool definitions, backup/restore
  lib/Cubase Toolbox helper - ….lua         small click actions (erase, mute, glue, zoom, tempo)
```

The tools are defined in the `M.TOOLS` table in `lib/CubaseToolbox_core.lua`.
Each tool lists the mouse settings it changes, so you can adjust a tool there.
