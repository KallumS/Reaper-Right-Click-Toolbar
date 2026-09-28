# Cubase Toolbox for REAPER

A set of ReaScripts that give REAPER a **Cubase-style toolbox**. Right-click
(or press a shortcut to open a toolbar at the mouse) and pick a tool, such as
Draw, Eraser, Split, Glue, Mute or Zoom. Your left mouse button then works
like that Cubase tool until you pick another one.

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

## Choosing a tool

There are two main ways to pick a tool. You can set up either one, or both.

| | Right-click menu | Floating toolbar at the mouse |
|---|---|---|
| **What you see** | A list of tool names | A panel of buttons with icons or short labels |
| **How you open it** | Right-click | A shortcut you choose (a key or a mouse button) |
| **Active tool shown by** | A tick next to its name | Its button lights up |

### Way 1: right-click menu

1. **Options > Customize menus/toolbars…**
2. In the drop-down at the top-left choose **Ruler/arrange context**. This is
   the menu you get when you right-click empty space in the arrange view.
3. Click **Add… > Action…**, type `Cubase Toolbox - Tool` in the filter box,
   and add the tools you want.
   *Shorter option:* add only **Cubase Toolbox - Show tool menu**. That adds
   one entry which opens the full toolbox at the mouse.
4. Drag the new entries to the top of the list so they sit first, like in
   Cubase. Tick **Include default menu as submenu** so REAPER's normal
   right-click commands stay available.
5. Repeat for **Media item context** (right-clicking an item). In the MIDI
   editor, do the same for its menus, which have names starting with "MIDI".
6. Click **Save**.

### Way 2: floating toolbar at the mouse

This is the closest match to Cubase's toolbox: a panel of tool buttons that
pops up where your mouse is.

**Build the toolbar (once):**

1. **Options > Customize menus/toolbars…**
2. In the drop-down at the top-left choose **Floating toolbar 1**. Pick
   another number if you already use toolbar 1.
3. Click **Add… > Action…**, type `Cubase Toolbox - Tool` in the filter box,
   and add all the tools.
4. Give each button a label: select it, then use the icon/text options in the
   window (for example **Text icon…**) to type a short name like `Select`,
   `Range`, `Split`, `Glue`, `Erase`, `Zoom`, `Mute`, `Draw`, `Line`, `Play`,
   `Hand`, `Drum` or `Warp`. You can choose picture icons instead if you prefer.
5. Click **Save**.

**Give it a shortcut:**

1. Open the **Actions** window (press `?`).
2. Search for `at mouse cursor` and find the action that opens your toolbar
   there. It's something like *Toolbar: Open/close toolbar 1 at mouse
   cursor*. Use the number you picked above.
3. Select it and click **Add…** under Shortcuts, then press the key or mouse
   button you want to use.

Now press that shortcut to open the toolbox at the mouse, then click a tool.
Press the shortcut again to close it.

You can also add that "open toolbar at mouse cursor" action to the
right-click menu (see Way 1). It takes one extra click, but you don't need a
shortcut.

### Extras

- **Keyboard shortcut per tool.** In the Actions window, select any
  `Cubase Toolbox - Tool …` action and click **Add…** under Shortcuts. Cubase
  uses the number keys 1–9, but REAPER already uses some of them, so pick keys
  you don't use.
- **Always-visible buttons.** You can put your favourite tools on the main
  toolbar or the **Empty TCP area toolbar** (the space under your track names).

**After restarting REAPER** no tool is ticked or lit until you pick one. The
tool you last used is still active, though.

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

- Run **Cubase Toolbox - Show tool menu** (from the right-click menu, or the
  Actions window) and choose **Troubleshooting report**. It
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
