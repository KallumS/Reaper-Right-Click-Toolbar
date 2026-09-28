--[[
  Right-Click Toolbox for REAPER - core library
  ----------------------------------------
  REAPER has no "tools" like Cubase. Instead, what the mouse does is decided by
  "mouse modifiers" (Preferences > Editing Behavior > Mouse Modifiers).

  This library emulates Cubase's tools by temporarily re-assigning the plain
  (no modifier key) left-click / left-drag behaviours in the relevant contexts.
  Before changing anything it backs up your own setting, and picking
  "Object Selection" puts every backed-up setting back exactly as it was.

  The other scripts in this folder are tiny wrappers around this file.
]]

local r = reaper
local M = {}

M.NAME = "Right-Click Toolbox"
-- ExtState section used for all saved data. Kept from the toolbox's original
-- name so settings saved by earlier versions (including your backed-up mouse
-- settings) are still found.
M.EXT  = "CubaseToolbox"

M.SECTION_MAIN = 0
M.SECTION_MIDI = 32060

M.lib_dir  = debug.getinfo(1, "S").source:match("^@?(.*[/\\])")
M.lib_dir  = M.lib_dir:gsub("[^/\\]+[/\\]%.%.[/\\]", "")   -- tidy "Modes/../lib/" to "lib/"
M.root_dir = M.lib_dir:match("^(.*[/\\])[^/\\]+[/\\]$")

-- Modifier-key flags used by SetMouseModifier
local NONE, ALT = 0, 4

---------------------------------------------------------------------------
-- Tool definitions
---------------------------------------------------------------------------
-- Each tool has one or more modes (like the modes on Cubase's tool buttons).
-- What a tool/mode does is a list of "slots"; each slot is one mouse-modifier
-- assignment:
--   ctx   = mouse context (see reaper-mouse.ini)
--   mod   = modifier flag (0 = no modifier key held, 4 = Alt)
--   one of:
--     id / name  = built-in mouse behaviour. The name is tried first, the id
--                  (" m") is the fallback.
--     helper     = one of this package's helper scripts (see HELPERS below)
--     action     = a built-in REAPER action, checked/found by name at runtime
--
-- A mode's slots are added to the tool's slots (a mode slot for the same
-- context and modifier replaces the tool's one).
--
-- override = letter of a REAPER 7 "arrange view override" set (A-D). When set,
--            left-drag anywhere in the arrange view (items or empty space)
--            uses that set instead of the normal contexts. A mode can set
--            override = false to turn the tool's override off.
-- fallback = slots used only if the override action can't be found.
-- config   = REAPER preferences changed while the mode is active, e.g. the
--            default shape of new MIDI CC events. Restored like the slots.

local SPLIT_ITEM   = { section = 0,     id = 40746, words = { "split", "item", "mouse" } }
local SPLIT_NOTES  = { section = 32060,             words = { "split", "note", "mouse" } }
local ZOOM_IN_V    = { section = 0,     id = 40111, words = { "zoom in vertical" } }
local ZOOM_OUT_V   = { section = 0,     id = 40112, words = { "zoom out vertical" } }

local ITEM_NO_DRAG = {
  { ctx = "MM_CTX_ITEM",          mod = NONE, id = 0, name = "No action" },
  { ctx = "MM_CTX_ITEMLOWER",     mod = NONE, id = 0, name = "Pass through to item drag context" },
  { ctx = "MM_CTX_ITEMLOWER_CLK", mod = NONE, id = 0, name = "Pass through to item click context" },
}

local function with(base, extra)
  local t = {}
  for _, s in ipairs(base) do t[#t + 1] = s end
  for _, s in ipairs(extra) do t[#t + 1] = s end
  return t
end

-- Line tool curve shapes. midiccenv = "default shape for CC segments"
-- (Preferences > MIDI editor); defenvs bits 16-18 = "default envelope point
-- shape" (Preferences > Track/send defaults).
local function line_shape(id, label, help, cc_shape, env_shape)
  return {
    id = id, label = label, help = help,
    config = {
      { name = "midiccenv", value = cc_shape },
      { name = "defenvs", mask = 0x70000, value = env_shape << 16 },
    },
  }
end

M.TOOLS = {
  {
    id = "select", label = "Object Selection", file = "01 Object Selection",
    help = "Select, move, resize, copy and trim.",
    slots = {},
    modes = {
      { id = "normal", label = "Normal",
        help = "REAPER's normal behaviour, with all your own settings." },
      { id = "stretch", label = "Sizing Applies Time Stretch",
        help = "Dragging an item edge time-stretches the audio.",
        slots = { { ctx = "MM_CTX_ITEMEDGE", mod = NONE, id = 2, name = "Stretch item" } } },
      { id = "toggle", label = "Click Adds/Removes From Selection",
        help = "Clicking an item adds it to the selection, or removes it if it's already selected.",
        slots = { { ctx = "MM_CTX_ITEM_CLK", mod = NONE, id = 4, name = "Toggle item selection" } } },
      { id = "under", label = "Select Events Under Cursor",
        help = "Click anywhere to select every item at that position, on all tracks.",
        slots = {
          { ctx = "MM_CTX_ITEM_CLK",  mod = NONE, helper = "select_at_mouse" },
          { ctx = "MM_CTX_TRACK_CLK", mod = NONE, helper = "select_at_mouse" },
        } },
      { id = "behind", label = "Select Objects Behind",
        help = "Click overlapping items to select the one underneath. Click again to go one further down.",
        slots = { { ctx = "MM_CTX_ITEM_CLK", mod = NONE, helper = "select_behind" } } },
    },
  },
  {
    id = "range", label = "Range Selection", file = "02 Range Selection",
    help = "Drag to select a time range across tracks (REAPER razor edit).",
    override = "B",
    slots = {},
    fallback = {
      { ctx = "MM_CTX_ITEM",  mod = NONE, id = 62, name = "Select razor edit area" },
      { ctx = "MM_CTX_TRACK", mod = NONE,          name = "Select razor edit area" },
    },
  },
  {
    id = "split", label = "Split (Scissors)", file = "03 Split",
    help = "Alt+click an item to cut it into repeated pieces of the length you clicked.",
    slots = with(ITEM_NO_DRAG, {
      { ctx = "MM_CTX_ITEM_CLK",      mod = ALT,  helper = "split_repeat" },
      { ctx = "MM_CTX_MIDI_NOTE_CLK", mod = NONE, action = SPLIT_NOTES },
      { ctx = "MM_CTX_MIDI_NOTE",     mod = NONE, id = 0, name = "No action" },
    }),
    modes = {
      { id = "mouse", label = "Split At Mouse",
        help = "Click an item (or MIDI note) to split it at the mouse.",
        slots = { { ctx = "MM_CTX_ITEM_CLK", mod = NONE, action = SPLIT_ITEM } } },
      { id = "selected", label = "Split All Selected Items",
        help = "Click to split the clicked item and every selected item at that position.",
        slots = { { ctx = "MM_CTX_ITEM_CLK", mod = NONE, helper = "split_selected" } } },
    },
  },
  {
    id = "glue", label = "Glue", file = "04 Glue",
    help = "Click an item to join it to the next item on the same track.",
    slots = with(ITEM_NO_DRAG, {
      { ctx = "MM_CTX_ITEM_CLK", mod = NONE, helper = "glue" },
    }),
  },
  {
    id = "erase", label = "Eraser", file = "05 Eraser",
    help = "Click items, MIDI notes, CC events or envelope points to delete them.",
    slots = with(ITEM_NO_DRAG, {
      { ctx = "MM_CTX_ITEM_CLK",       mod = NONE, helper = "erase" },
      { ctx = "MM_CTX_ENVPT",          mod = NONE, id = 4, name = "Delete envelope point" },
      { ctx = "MM_CTX_ENVSEG",         mod = NONE, id = 0, name = "No action" },
      { ctx = "MM_CTX_MIDI_NOTE_CLK",  mod = NONE, id = 6, name = "Erase note" },
      { ctx = "MM_CTX_MIDI_NOTE",      mod = NONE, id = 3, name = "Erase notes" },
      { ctx = "MM_CTX_MIDI_PIANOROLL", mod = NONE, id = 3, name = "Erase notes" },
      { ctx = "MM_CTX_MIDI_CCEVT",     mod = NONE, id = 3, name = "Erase CC event" },
      { ctx = "MM_CTX_MIDI_CCLANE",    mod = NONE, id = 3, name = "Erase CC events" },
    }),
  },
  {
    id = "zoom", label = "Zoom", file = "06 Zoom",
    help = "Zoom the view.",
    override = "D",
    slots = {
      { ctx = "MM_CTX_ARRANGE_D", mod = NONE, id = 14, name = "Marquee zoom" },
      { ctx = "MM_CTX_ITEM_CLK",  mod = NONE, helper = "zoom_in" },
      { ctx = "MM_CTX_ITEM_CLK",  mod = ALT,  helper = "zoom_out" },
      { ctx = "MM_CTX_TRACK_CLK", mod = NONE, helper = "zoom_in" },
      { ctx = "MM_CTX_TRACK_CLK", mod = ALT,  helper = "zoom_out" },
    },
    fallback = {
      { ctx = "MM_CTX_ITEM",  mod = NONE, id = 48, name = "Marquee zoom" },
      { ctx = "MM_CTX_TRACK", mod = NONE, id = 22, name = "Marquee zoom" },
    },
    modes = {
      { id = "box", label = "Zoom To Dragged Selection",
        help = "Drag a box to zoom into it. Click to zoom in, Alt+click to zoom out, centred on the mouse." },
      { id = "horizontal", label = "Zoom Horizontally",
        help = "Drag left/right to zoom in and out horizontally. Click to zoom in, Alt+click to zoom out.",
        slots = { { ctx = "MM_CTX_ARRANGE_D", mod = NONE, id = 17, name = "Horizontal zoom" } } },
      { id = "vertical", label = "Zoom Vertically",
        help = "Click to make tracks taller, Alt+click to make them shorter. Drag a box to zoom into it.",
        slots = {
          { ctx = "MM_CTX_ITEM_CLK",  mod = NONE, action = ZOOM_IN_V },
          { ctx = "MM_CTX_ITEM_CLK",  mod = ALT,  action = ZOOM_OUT_V },
          { ctx = "MM_CTX_TRACK_CLK", mod = NONE, action = ZOOM_IN_V },
          { ctx = "MM_CTX_TRACK_CLK", mod = ALT,  action = ZOOM_OUT_V },
        } },
    },
  },
  {
    id = "mute", label = "Mute", file = "07 Mute",
    help = "Click items or MIDI notes to mute/unmute them.",
    slots = with(ITEM_NO_DRAG, {
      { ctx = "MM_CTX_ITEM_CLK",      mod = NONE, helper = "mute" },
      { ctx = "MM_CTX_MIDI_NOTE_CLK", mod = NONE, id = 7, name = "Toggle note mute" },
      { ctx = "MM_CTX_MIDI_NOTE",     mod = NONE, id = 0, name = "No action" },
    }),
  },
  {
    id = "draw", label = "Draw (Pencil)", file = "08 Draw",
    help = "Draw empty MIDI items, automation, MIDI notes and CC data.",
    slots = {
      { ctx = "MM_CTX_TRACK",          mod = NONE, id = 5, name = "Draw an empty MIDI item" },
      { ctx = "MM_CTX_MIDI_PIANOROLL", mod = NONE, id = 1, name = "Insert note, drag to extend or change pitch" },
    },
    modes = {
      { id = "free", label = "Free Draw",
        help = "Draw automation and MIDI CC freehand.",
        slots = {
          { ctx = "MM_CTX_ENVSEG",      mod = NONE, id = 3,  name = "Freehand draw envelope" },
          { ctx = "MM_CTX_ENVPT",       mod = NONE, id = 3,  name = "Freehand draw envelope" },
          { ctx = "MM_CTX_MIDI_CCLANE", mod = NONE, id = 1,  name = "Draw/edit CC events ignoring selection" },
          { ctx = "MM_CTX_MIDI_CCEVT",  mod = NONE, id = 18, name = "Draw/edit CC events ignoring selection" },
        } },
      { id = "line", label = "Line",
        help = "Draw straight lines of MIDI CC. On automation, click to add points joined by straight lines.",
        slots = {
          { ctx = "MM_CTX_ENVSEG",      mod = NONE, id = 2,  name = "Insert envelope point, drag to move" },
          { ctx = "MM_CTX_MIDI_CCLANE", mod = NONE, id = 5,  name = "Linear ramp CC events" },
          { ctx = "MM_CTX_MIDI_CCEVT",  mod = NONE, id = 24, name = "Linear ramp CC events" },
        } },
    },
  },
  {
    id = "line", label = "Line", file = "09 Line",
    help = "Draw ramps of MIDI CC/velocity, rows of notes, and automation points. The mode sets the curve shape.",
    slots = {
      { ctx = "MM_CTX_ENVSEG",         mod = NONE, id = 2, name = "Insert envelope point, drag to move" },
      { ctx = "MM_CTX_MIDI_PIANOROLL", mod = NONE, id = 23, name = "Paint a straight line of notes" },
      { ctx = "MM_CTX_MIDI_CCLANE",    mod = NONE, id = 5, name = "Linear ramp CC events" },
      { ctx = "MM_CTX_MIDI_CCEVT",     mod = NONE, id = 24, name = "Linear ramp CC events" },
    },
    modes = {
      line_shape("linear",   "Linear",                "Straight ramps.", 1, 0),
      line_shape("curve",    "Curve",                 "Smooth curved ramps (bezier) you can bend afterwards.", 5, 5),
      line_shape("scurve",   "S-Curve (Slow Start/End)", "Ramps that ease in and ease out, like a sine.", 2, 2),
      line_shape("fast",     "Exponential (Fast Start)", "Ramps that change quickly at first, then level off.", 3, 3),
      line_shape("slow",     "Logarithmic (Fast End)", "Ramps that start slowly and speed up at the end.", 4, 4),
      line_shape("square",   "Steps (Square)",        "Values jump from point to point with no ramp.", 0, 1),
    },
  },
  {
    id = "play", label = "Play / Scrub", file = "10 Play Scrub",
    help = "Listen to the project with the mouse.",
    override = "D",
    slots = {
      { ctx = "MM_CTX_MIDI_PIANOROLL", mod = NONE, id = 16, name = "Scrub preview MIDI" },
    },
    modes = {
      { id = "scrub", label = "Scrub",
        help = "Drag to scrub audio like tape. In the MIDI editor, drag to hear notes.",
        slots = { { ctx = "MM_CTX_ARRANGE_D", mod = NONE, id = 10, name = "Scrub audio" } } },
      { id = "jog", label = "Jog",
        help = "Drag to play forwards (or backwards) at your own speed. In the MIDI editor, drag to hear notes.",
        slots = { { ctx = "MM_CTX_ARRANGE_D", mod = NONE, id = 11, name = "Jog audio" } } },
      { id = "click", label = "Play From Click",
        help = "Click to play from that point, click again to stop. In the MIDI editor, drag to hear notes.",
        override = false,
        slots = with(ITEM_NO_DRAG, {
          { ctx = "MM_CTX_ITEM_CLK",  mod = NONE, helper = "play_from_mouse" },
          { ctx = "MM_CTX_TRACK_CLK", mod = NONE, helper = "play_from_mouse" },
        }) },
    },
  },
  {
    id = "hand", label = "Hand (Scroll)", file = "11 Hand",
    help = "Drag to scroll around the project without changing the zoom.",
    override = "D",
    slots = {
      { ctx = "MM_CTX_ARRANGE_D", mod = NONE, id = 8, name = "Hand scroll" },
    },
  },
  {
    id = "drumstick", label = "Drumstick (MIDI editor)", file = "12 Drumstick",
    help = "MIDI editor: click or drag to paint drum hits, click a hit to remove it.",
    slots = {
      { ctx = "MM_CTX_MIDI_PIANOROLL",     mod = NONE, id = 22, name = "Paint notes" },
      { ctx = "MM_CTX_MIDI_PIANOROLL_CLK", mod = NONE, id = 4,  name = "Insert note" },
      { ctx = "MM_CTX_MIDI_NOTE_CLK",      mod = NONE, id = 6,  name = "Erase note" },
    },
  },
  {
    id = "timewarp", label = "Time Warp", file = "13 Time Warp",
    help = "Click to add a tempo marker at the nearest grid line, then drag tempo markers in the ruler to line the grid up with the audio.",
    slots = with(ITEM_NO_DRAG, {
      { ctx = "MM_CTX_ITEM_CLK",     mod = NONE, helper = "tempo_marker" },
      { ctx = "MM_CTX_TRACK_CLK",    mod = NONE, helper = "tempo_marker" },
      { ctx = "MM_CTX_TEMPOMARKER",  mod = NONE, id = 3, name = "Move project tempo/time signature marker, adjusting previous tempo" },
    }),
  },
}

-- Script file names (relative to the "Right-Click Toolbox" folder).
function M.tool_file(tool)
  return "Right-Click Toolbox - Tool " .. tool.file .. ".lua"
end

function M.mode_file(tool, mode)
  local label = mode.label:gsub("/", "-"):gsub("[^%w%s%-]", ""):gsub("%s+", " ")
  return "Modes/Right-Click Toolbox - Mode " .. tool.file .. " - " .. label .. ".lua"
end

M.TOOLS_BY_ID = {}
for i, t in ipairs(M.TOOLS) do
  t.index = i
  -- Tools without modes get a single mode, so everything else can assume modes.
  t.modes = t.modes or { { id = "default", label = t.label, help = t.help } }
  t.modes_by_id = {}
  for _, mode in ipairs(t.modes) do
    mode.tool = t
    t.modes_by_id[mode.id] = mode
  end
  M.TOOLS_BY_ID[t.id] = t
end

-- Helper scripts (live next to this file), used for click behaviours REAPER
-- doesn't have built in.
M.HELPERS = {
  erase           = "Right-Click Toolbox helper - Erase item under mouse.lua",
  mute            = "Right-Click Toolbox helper - Mute item under mouse.lua",
  glue            = "Right-Click Toolbox helper - Glue item under mouse to next.lua",
  zoom_in         = "Right-Click Toolbox helper - Zoom in at mouse.lua",
  zoom_out        = "Right-Click Toolbox helper - Zoom out at mouse.lua",
  tempo_marker    = "Right-Click Toolbox helper - Insert tempo marker at mouse.lua",
  select_at_mouse = "Right-Click Toolbox helper - Select items under mouse on all tracks.lua",
  select_behind   = "Right-Click Toolbox helper - Select item behind.lua",
  split_selected  = "Right-Click Toolbox helper - Split selected items at mouse.lua",
  split_repeat    = "Right-Click Toolbox helper - Split item into repeated pieces.lua",
  play_from_mouse = "Right-Click Toolbox helper - Play from mouse.lua",
}

---------------------------------------------------------------------------
-- Small utilities
---------------------------------------------------------------------------
local function get(key)
  local v = r.GetExtState(M.EXT, key)
  if v == "" then return nil end
  return v
end

local function set(key, value)
  r.SetExtState(M.EXT, key, value, true)
end

local function del(key)
  r.DeleteExtState(M.EXT, key, true)
end

local function split(s, sep)
  local t = {}
  for part in (s or ""):gmatch("[^" .. sep .. "]+") do t[#t + 1] = part end
  return t
end

function M.log(msg)
  r.ShowConsoleMsg("[" .. M.NAME .. "] " .. msg .. "\n")
end

function M.no_undo()
  -- A script that ends via defer() doesn't create an undo point.
  r.defer(function() end)
end

---------------------------------------------------------------------------
-- Finding REAPER actions by name (so we don't depend on ID numbers alone)
---------------------------------------------------------------------------
local function action_name(section_id, cmd)
  local sec = r.SectionFromUniqueID(section_id)
  if not sec or not cmd or cmd == 0 then return "" end
  return (r.kbd_getTextFromCmd(cmd, sec) or ""):lower()
end

local function has_words(name, words)
  for _, w in ipairs(words) do
    if not name:find(w, 1, true) then return false end
  end
  return true
end

-- Returns the command ID of the shortest action name that passes `accept`.
local function search_actions(section_id, accept)
  local sec = r.SectionFromUniqueID(section_id)
  if not sec then return nil end
  local best, best_len
  for i = 0, 200000 do
    local cmd, name = r.kbd_enumerateActions(sec, i)
    if not cmd or cmd == 0 then break end
    name = (name or ""):lower()
    if accept(name, cmd) and (not best or #name < best_len) then
      best, best_len = cmd, #name
    end
  end
  return best
end

-- spec = { section = 0, id = <expected id, optional>, words = {...}, without = {...} }
function M.find_action(spec)
  local section = spec.section or 0
  local function accept(name)
    if not has_words(name, spec.words) then return false end
    for _, w in ipairs(spec.without or {}) do
      if name:find(w, 1, true) then return false end
    end
    return true
  end
  if spec.id and accept(action_name(section, spec.id)) then return spec.id end
  return search_actions(section, accept)
end

-- REAPER 7: the on/off action for "arrange view override mouse modifiers <letter>".
function M.find_override_action(letter)
  local key = "override_cmd_" .. letter
  local cached = tonumber(get(key) or "")
  local function accept(name, cmd)
    if not (name:find("override", 1, true) and name:find("arrange", 1, true)) then
      return false
    end
    for _, w in ipairs({ "momentary", "while", "hold" }) do
      if name:find(w, 1, true) then return false end
    end
    -- must be an on/off (toggle) action, not a one-way "set" action
    if r.GetToggleCommandStateEx(0, cmd) < 0 then return false end
    for word in name:gmatch("%w+") do
      if word == letter:lower() then return true end
    end
    return false
  end
  if cached and accept(action_name(0, cached), cached) then return cached end
  local cmd = search_actions(0, accept)
  if cmd then set(key, tostring(cmd)) end
  return cmd
end

---------------------------------------------------------------------------
-- Helper scripts: make sure they are in the action list, return their ID
---------------------------------------------------------------------------
function M.helper_action(helper)
  local file = M.HELPERS[helper]
  if not file then return nil end
  local key = "helper_" .. helper
  local named = get(key)
  if named and r.NamedCommandLookup("_" .. named) ~= 0 then
    return "_" .. named
  end
  local path = M.lib_dir .. file
  if not r.file_exists(path) then
    M.log("Missing helper script: " .. path)
    return nil
  end
  local cmd = r.AddRemoveReaScript(true, M.SECTION_MAIN, path, true)
  if not cmd or cmd == 0 then return nil end
  named = r.ReverseNamedCommandLookup(cmd)
  if not named or named == "" then return nil end
  set(key, named)
  return "_" .. named
end

---------------------------------------------------------------------------
-- Setting mouse modifiers safely
---------------------------------------------------------------------------
local SENTINEL = "0 m"   -- "No action" in every context

local function norm(s)
  s = tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
  return (s:gsub("%s+[mcMC]$", ""))
end

-- Returns the list of action strings to try for a slot (best first).
local function candidates(slot)
  local list = {}
  if slot.helper then
    local a = M.helper_action(slot.helper)
    if a then list[#list + 1] = a end
  elseif slot.action then
    local cmd = M.find_action(slot.action)
    if cmd then list[#list + 1] = tostring(cmd) .. " c" end
  else
    if slot.name then list[#list + 1] = slot.name end
    if slot.id then list[#list + 1] = tostring(slot.id) .. " m" end
  end
  return list
end

-- Sets a slot and reads it back, so we know whether REAPER accepted it.
local function try_set(ctx, mod, action)
  r.SetMouseModifier(ctx, mod, SENTINEL)
  r.SetMouseModifier(ctx, mod, action)
  local now = norm(r.GetMouseModifier(ctx, mod))
  local want = norm(action)
  if want:match("^%-?%d+$") then
    return now == want
  elseif want:sub(1, 1) == "_" then
    return now == want or tonumber(now) == r.NamedCommandLookup(want)
  else
    -- A behaviour given by name: accepted if it's no longer the sentinel.
    return now ~= "" and now ~= norm(SENTINEL)
  end
end

local function slot_key(ctx, mod) return ctx .. "|" .. mod end

local function backup_list() return split(get("backup_list"), ";") end

local function backup(ctx, mod)
  local key = slot_key(ctx, mod)
  local list = backup_list()
  for _, k in ipairs(list) do
    if k == key then return end   -- already have the user's original setting
  end
  local value = r.GetMouseModifier(ctx, mod)
  if not value or value == "" then value = "-1" end
  set("bk|" .. key, value)
  list[#list + 1] = key
  set("backup_list", table.concat(list, ";"))
end

local function restore_slot(key)
  local ctx, mod = key:match("^(.*)|(%-?%d+)$")
  if ctx then
    r.SetMouseModifier(ctx, tonumber(mod), get("bk|" .. key) or "-1")
  end
  del("bk|" .. key)
end

-- Preferences (reaper.ini settings) changed by a mode, e.g. the default
-- shape of new CC events. The user's own value is saved first.
local function config_list() return split(get("config_list"), ";") end

local function apply_config(cfg, problems)
  if not (r.get_config_var_string and r.set_config_var_string) then
    problems[#problems + 1] = "Changing the '" .. cfg.name .. "' preference needs a newer REAPER"
    return
  end
  local ok, current = r.get_config_var_string(cfg.name)
  if not ok then
    problems[#problems + 1] = "REAPER has no '" .. cfg.name .. "' preference"
    return
  end
  local list, known = config_list(), false
  for _, n in ipairs(list) do known = known or n == cfg.name end
  if not known then
    set("cfg|" .. cfg.name, current)
    list[#list + 1] = cfg.name
    set("config_list", table.concat(list, ";"))
  end
  local value = cfg.value
  if cfg.mask then
    value = ((math.tointeger(tonumber(current)) or 0) & ~cfg.mask) | cfg.value
  end
  r.set_config_var_string(cfg.name, tostring(value), 1)
end

-- Put back every mouse setting and preference we changed, and switch off any
-- override set that we switched on.
function M.restore_all()
  for _, key in ipairs(backup_list()) do restore_slot(key) end
  del("backup_list")
  for _, name in ipairs(config_list()) do
    local value = get("cfg|" .. name)
    if value and r.set_config_var_string then r.set_config_var_string(name, value, 1) end
    del("cfg|" .. name)
  end
  del("config_list")
  for _, letter in ipairs(split(get("overrides_on"), ",")) do
    local cmd = M.find_override_action(letter)
    if cmd and r.GetToggleCommandState(cmd) == 1 then
      r.Main_OnCommand(cmd, 0)
    end
  end
  del("overrides_on")
end

local function apply_slot(slot, problems)
  local list = candidates(slot)
  if #list == 0 then
    problems[#problems + 1] = slot.ctx .. ": could not find the action to use"
    return
  end
  backup(slot.ctx, slot.mod)
  for _, action in ipairs(list) do
    if try_set(slot.ctx, slot.mod, action) then return end
  end
  -- Nothing worked: put the original back straight away.
  local key = slot_key(slot.ctx, slot.mod)
  r.SetMouseModifier(slot.ctx, slot.mod, get("bk|" .. key) or "-1")
  problems[#problems + 1] = slot.ctx .. ": REAPER did not accept " .. table.concat(list, " / ")
end

local function enable_override(letter, problems)
  local cmd = M.find_override_action(letter)
  if not cmd then
    problems[#problems + 1] = "Could not find the 'arrange view override " .. letter ..
      "' action (needs REAPER 7 or newer)"
    return false
  end
  if r.GetToggleCommandState(cmd) ~= 1 then
    r.Main_OnCommand(cmd, 0)
    set("overrides_on", letter)
  end
  return true
end

---------------------------------------------------------------------------
-- Toolbar / menu toggle states
---------------------------------------------------------------------------
-- Scripts call this so their toolbar button / menu entry can light up.
-- key is a tool id ("split") or a tool:mode pair ("split:selected").
function M.remember_script(key, section, cmd)
  if not cmd or cmd == 0 then return end
  local named = r.ReverseNamedCommandLookup(cmd)
  if named and named ~= "" then
    set("cmd|" .. key .. "|" .. section, named)
  end
end

-- Every tool and mode key, with whether it is active right now.
local function script_keys()
  local keys = {}
  local current_tool, current_mode = M.current_tool(), nil
  current_mode = M.current_mode(current_tool)
  for _, tool in ipairs(M.TOOLS) do
    keys[#keys + 1] = { key = tool.id, on = tool.id == current_tool }
    if #tool.modes > 1 then
      for _, mode in ipairs(tool.modes) do
        keys[#keys + 1] = { key = tool.id .. ":" .. mode.id,
                            on = tool.id == current_tool and mode.id == current_mode }
      end
    end
  end
  return keys
end

function M.refresh_toggle_states()
  for _, k in ipairs(script_keys()) do
    for _, section in ipairs({ M.SECTION_MAIN, M.SECTION_MIDI }) do
      local named = get("cmd|" .. k.key .. "|" .. section)
      if named then
        local cmd = r.NamedCommandLookup("_" .. named)
        if cmd ~= 0 then
          r.SetToggleCommandState(section, cmd, k.on and 1 or 0)
          r.RefreshToolbar2(section, cmd)
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- Public: pick a tool
---------------------------------------------------------------------------
function M.current_tool()
  local id = get("current_tool")
  if id and M.TOOLS_BY_ID[id] then return id end
  return "select"
end

-- The mode last used with a tool (its first mode if never picked).
function M.current_mode(tool_id)
  local tool = M.TOOLS_BY_ID[tool_id]
  if not tool then return nil end
  local id = get("mode|" .. tool_id)
  if id and tool.modes_by_id[id] then return id end
  return tool.modes[1].id
end

local function full_label(tool, mode)
  if #tool.modes > 1 then return tool.label .. " - " .. mode.label end
  return tool.label
end

local function show_tooltip(text)
  local x, y = r.GetMousePosition()
  r.TrackCtl_SetToolTip(text, x + 16, y + 16, true)
  local start = r.time_precise()
  local function wait()
    if r.time_precise() - start < 1.2 then
      r.defer(wait)
    else
      r.TrackCtl_SetToolTip("", 0, 0, true)
    end
  end
  r.defer(wait)
end

-- The tool's slots, with the mode's slots added (a mode slot for the same
-- context and modifier replaces the tool's).
local function merged_slots(tool, mode)
  local list, index = {}, {}
  for _, source in ipairs({ tool.slots or {}, mode.slots or {} }) do
    for _, slot in ipairs(source) do
      local key = slot_key(slot.ctx, slot.mod)
      if index[key] then
        list[index[key]] = slot
      else
        list[#list + 1] = slot
        index[key] = #list
      end
    end
  end
  return list
end

-- Pick a tool. mode_id is optional: without it the tool's last-used mode is used.
function M.set_tool(id, mode_id)
  local tool = M.TOOLS_BY_ID[id]
  if not tool then
    M.log("Unknown tool: " .. tostring(id))
    return
  end
  local mode = tool.modes_by_id[mode_id or M.current_mode(id)] or tool.modes[1]

  local problems = {}
  M.restore_all()

  for _, slot in ipairs(merged_slots(tool, mode)) do apply_slot(slot, problems) end
  for _, cfg in ipairs(mode.config or {}) do apply_config(cfg, problems) end

  local override = tool.override
  if mode.override ~= nil then override = mode.override end
  if override and not enable_override(override, problems) then
    for _, slot in ipairs(mode.fallback or tool.fallback or {}) do apply_slot(slot, problems) end
  end

  set("current_tool", tool.id)
  set("mode|" .. tool.id, mode.id)
  M.refresh_toggle_states()

  if #problems > 0 then
    M.log("Tool '" .. full_label(tool, mode) .. "' is only partly active:\n  - " ..
          table.concat(problems, "\n  - ") ..
          "\nEverything else about this tool is working.")
  end
  show_tooltip("Tool: " .. full_label(tool, mode))
end

---------------------------------------------------------------------------
-- Closing the floating toolbar after a tool is picked (like Cubase)
---------------------------------------------------------------------------
function M.autoclose_enabled()
  return get("autoclose") ~= "0"
end

function M.set_autoclose(on)
  set("autoclose", on and "1" or "0")
end

-- Every tool action's ID, as it appears in reaper-menu.ini ("_RS...").
local function tool_action_ids()
  local ids = {}
  for _, k in ipairs(script_keys()) do
    for _, section in ipairs({ M.SECTION_MAIN, M.SECTION_MIDI }) do
      local named = get("cmd|" .. k.key .. "|" .. section)
      if named then ids[#ids + 1] = "_" .. named end
    end
  end
  return ids
end

-- Finds the floating toolbars the user put our tool buttons on, by reading
-- REAPER's toolbar settings file. Returns e.g. { {midi = false, n = 1} }.
function M.find_tool_toolbars()
  local found = {}
  local ids = tool_action_ids()
  if #ids == 0 then return found end
  local f = io.open(r.GetResourcePath() .. "/reaper-menu.ini", "r")
  if not f then return found end
  local current, matched
  for line in f:lines() do
    local header = line:match("^%[(.-)%]")
    if header then
      local n = header:match("^Floating toolbar (%d+)$")
      local midi_n = header:match("^Floating MIDI toolbar (%d+)$")
      if n then
        current = { midi = false, n = tonumber(n) }
      elseif midi_n then
        current = { midi = true, n = tonumber(midi_n) }
      else
        current = nil
      end
      matched = false
    elseif current and not matched and line:match("^item_%d+=") then
      for _, id in ipairs(ids) do
        if line:find(id, 1, true) then
          found[#found + 1] = current
          matched = true
          break
        end
      end
    end
  end
  f:close()
  return found
end

-- The on/off action for floating toolbar n (main window or MIDI editor).
local function toolbar_toggle_action(section, n, midi)
  return search_actions(section, function(name, cmd)
    if not (name:find("toolbar", 1, true) and name:find("open/close", 1, true)) then
      return false
    end
    if (name:find("midi", 1, true) ~= nil) ~= midi then return false end
    if r.GetToggleCommandStateEx(section, cmd) < 0 then return false end
    for word in name:gmatch("%w+") do
      if word == tostring(n) then return true end
    end
    return false
  end)
end

-- Closes any open floating toolbar that holds our tool buttons.
function M.close_tool_toolbars()
  for _, tb in ipairs(M.find_tool_toolbars()) do
    local section = tb.midi and M.SECTION_MIDI or M.SECTION_MAIN
    local cmd = toolbar_toggle_action(section, tb.n, tb.midi)
    if cmd and r.GetToggleCommandStateEx(section, cmd) == 1 then
      if section == M.SECTION_MIDI then
        r.MIDIEditor_LastFocused_OnCommand(cmd, false)
      else
        r.Main_OnCommand(cmd, 0)
      end
    end
  end
end

local function after_pick()
  if M.autoclose_enabled() then
    -- wait until the button click has finished before closing its toolbar
    r.defer(M.close_tool_toolbars)
  end
end

-- Called by the "Right-Click Toolbox - Tool ..." actions. Picking the tool that is
-- already active opens its modes menu (like the second click in Cubase).
function M.run_tool_action(id, section, cmd)
  M.remember_script(id, section, cmd)
  local tool = M.TOOLS_BY_ID[id]
  if tool and #tool.modes > 1 and M.current_tool() == id then
    local mode_id = M.show_mode_menu(id)
    if not mode_id then return M.no_undo() end
    M.set_tool(id, mode_id)
  else
    M.set_tool(id)
  end
  after_pick()
end

-- Called by the "Right-Click Toolbox - Mode ..." actions.
function M.run_mode_action(id, mode_id, section, cmd)
  M.remember_script(id .. ":" .. mode_id, section, cmd)
  M.set_tool(id, mode_id)
  after_pick()
end

---------------------------------------------------------------------------
-- Public: the right-click toolbox menu
---------------------------------------------------------------------------
local function show_menu_at_mouse(menu)
  local x, y = r.GetMousePosition()
  local title = M.NAME .. " menu"
  gfx.init(title, 0, 0, 0, x, y)
  if r.JS_Window_Find then   -- hide the helper window if js_ReaScriptAPI is installed
    local hwnd = r.JS_Window_Find(title, true)
    if hwnd then r.JS_Window_Show(hwnd, "HIDE") end
  end
  gfx.x, gfx.y = gfx.screentoclient(x, y)
  local choice = gfx.showmenu(menu)
  gfx.quit()
  return choice
end

local function menu_escape(s)
  -- '|' separates menu items, and a leading # ! > < has a special meaning.
  return (s:gsub("|", "/"):gsub("^[#!><]", ""))
end

-- Numbers gfx.showmenu gives back: every item counts, including grey ones,
-- but not separators or the ">" line that opens a submenu.
local function menu_lookup(items, actions)
  local lookup = {}
  for i, item in ipairs(items) do
    if item ~= "" and not item:match("^[#!]*>") then lookup[#lookup + 1] = actions[i] end
  end
  return lookup
end

-- Small menu of a tool's modes. Returns the picked mode id, or nil.
function M.show_mode_menu(id)
  local tool = M.TOOLS_BY_ID[id]
  local current = M.current_mode(id)
  local items = { "#" .. menu_escape(tool.label) .. " modes", "" }
  local actions = { false, false }
  for _, mode in ipairs(tool.modes) do
    items[#items + 1] = (mode.id == current and "!" or "") .. menu_escape(mode.label)
    actions[#actions + 1] = mode.id
  end
  return menu_lookup(items, actions)[show_menu_at_mouse(table.concat(items, "|"))] or nil
end

function M.show_menu()
  local current = M.current_tool()
  local items = { "#" .. M.NAME, "" }
  local actions = { false, false }
  for _, tool in ipairs(M.TOOLS) do
    local active = tool.id == current
    if #tool.modes > 1 then
      -- tool with modes: a submenu listing them
      items[#items + 1] = ">" .. menu_escape(tool.label) .. (active and "  (active)" or "")
      actions[#actions + 1] = false
      local current_mode = M.current_mode(tool.id)
      for i, mode in ipairs(tool.modes) do
        items[#items + 1] = (i == #tool.modes and "<" or "") ..
          ((active and mode.id == current_mode) and "!" or "") .. menu_escape(mode.label)
        actions[#actions + 1] = { tool.id, mode.id }
      end
    else
      items[#items + 1] = (active and "!" or "") .. menu_escape(tool.label)
      actions[#actions + 1] = { tool.id }
    end
  end
  items[#items + 1] = ""
  actions[#actions + 1] = false
  items[#items + 1] = (M.autoclose_enabled() and "!" or "") .. "Close floating toolbar after picking a tool"
  actions[#actions + 1] = "@autoclose"
  items[#items + 1] = "What does the current tool do?"
  actions[#actions + 1] = "@help"
  items[#items + 1] = "Troubleshooting report (prints to console)"
  actions[#actions + 1] = "@diagnostics"

  local choice = show_menu_at_mouse(table.concat(items, "|"))
  local picked = menu_lookup(items, actions)[choice]
  if not picked then return M.no_undo() end

  if picked == "@help" then
    local t = M.TOOLS_BY_ID[current]
    local mode = t.modes_by_id[M.current_mode(current)]
    local text = full_label(t, mode) .. "\n\n" .. (mode.help or t.help)
    if #t.modes > 1 and t.help then text = text .. "\n\n" .. t.help end
    r.ShowMessageBox(text, M.NAME, 0)
    return M.no_undo()
  elseif picked == "@autoclose" then
    M.set_autoclose(not M.autoclose_enabled())
    return M.no_undo()
  elseif picked == "@diagnostics" then
    M.diagnostics()
    return M.no_undo()
  end
  M.set_tool(picked[1], picked[2])
end

---------------------------------------------------------------------------
-- Public: install (register every script in the Action List)
---------------------------------------------------------------------------
function M.install()
  local registered, failed = 0, {}

  local function add(section, path, commit)
    if not r.file_exists(path) then
      failed[#failed + 1] = path
      return nil
    end
    local cmd = r.AddRemoveReaScript(true, section, path, commit)
    if cmd and cmd ~= 0 then registered = registered + 1 else failed[#failed + 1] = path end
    return cmd
  end

  for _, section in ipairs({ M.SECTION_MAIN, M.SECTION_MIDI }) do
    add(section, M.root_dir .. "Right-Click Toolbox - Show tool menu.lua", false)
    for _, tool in ipairs(M.TOOLS) do
      local cmd = add(section, M.root_dir .. M.tool_file(tool), false)
      M.remember_script(tool.id, section, cmd)
      if #tool.modes > 1 then
        for _, mode in ipairs(tool.modes) do
          cmd = add(section, M.root_dir .. M.mode_file(tool, mode), false)
          M.remember_script(tool.id .. ":" .. mode.id, section, cmd)
        end
      end
    end
  end
  for helper in pairs(M.HELPERS) do
    del("helper_" .. helper)   -- re-registered below / on first use
  end
  local helper_names = {}
  for helper in pairs(M.HELPERS) do helper_names[#helper_names + 1] = helper end
  table.sort(helper_names)
  for i, helper in ipairs(helper_names) do
    local cmd = add(M.SECTION_MAIN, M.lib_dir .. M.HELPERS[helper], i == #helper_names)
    local named = cmd and cmd ~= 0 and r.ReverseNamedCommandLookup(cmd)
    if named and named ~= "" then set("helper_" .. helper, named) end
  end

  M.refresh_toggle_states()
  return registered, failed
end

---------------------------------------------------------------------------
-- Public: troubleshooting report
---------------------------------------------------------------------------
function M.diagnostics()
  local lines = {}
  local function add(s) lines[#lines + 1] = s end
  add("==== " .. M.NAME .. " troubleshooting report ====")
  add("REAPER version: " .. r.GetAppVersion())
  add("Current tool: " .. M.current_tool() .. ", mode: " .. tostring(M.current_mode(M.current_tool())))
  add("Script folder: " .. M.root_dir)
  for _, letter in ipairs({ "A", "B", "C", "D" }) do
    local cmd = M.find_override_action(letter)
    add(("Arrange override %s action: %s%s"):format(letter,
      cmd and (cmd .. " '" .. action_name(0, cmd) .. "'") or "NOT FOUND",
      cmd and (" (currently " .. (r.GetToggleCommandState(cmd) == 1 and "on" or "off") .. ")") or ""))
  end
  add("Close floating toolbar after picking a tool: " .. (M.autoclose_enabled() and "on" or "off"))
  for _, tb in ipairs(M.find_tool_toolbars()) do
    local section = tb.midi and M.SECTION_MIDI or M.SECTION_MAIN
    local cmd = toolbar_toggle_action(section, tb.n, tb.midi)
    add(("Tools found on %s toolbar %d, open/close action: %s"):format(tb.midi and "MIDI floating" or "floating",
      tb.n, cmd and (cmd .. " '" .. action_name(section, cmd) .. "'") or "NOT FOUND"))
  end
  add(("Split item action: %s"):format(tostring(M.find_action(SPLIT_ITEM))))
  add(("Split notes action (MIDI editor): %s"):format(tostring(M.find_action(SPLIT_NOTES))))
  for helper in pairs(M.HELPERS) do
    add(("Helper '%s': %s"):format(helper, tostring(get("helper_" .. helper))))
  end
  for _, name in ipairs(config_list()) do
    local _, now = r.get_config_var_string(name)
    add(("Preference '%s' changed by the toolbox: your value %s, now %s"):format(name, tostring(get("cfg|" .. name)), tostring(now)))
  end
  add("Settings currently changed by the toolbox (context | modifier = your original):")
  local list = backup_list()
  if #list == 0 then add("  (none - REAPER is using your normal settings)") end
  for _, key in ipairs(list) do
    local ctx, mod = key:match("^(.*)|(%-?%d+)$")
    add(("  %s = %s, now %s"):format(key, tostring(get("bk|" .. key)),
      tostring(r.GetMouseModifier(ctx, tonumber(mod)))))
  end
  r.ShowConsoleMsg(table.concat(lines, "\n") .. "\n")
end

---------------------------------------------------------------------------
-- Helpers used by the helper scripts
---------------------------------------------------------------------------
function M.item_under_mouse()
  local x, y = r.GetMousePosition()
  return (r.GetItemFromPoint(x, y, false))
end

-- Time position (seconds) under the mouse in the arrange view.
-- With snap = true it follows the grid when snapping is switched on.
function M.mouse_time(snap)
  local cmd = M.find_action({ section = 0, id = 40514, words = { "edit cursor to mouse cursor", "no snap" } })
  if not cmd then return nil end
  local old = r.GetCursorPosition()
  r.Main_OnCommand(cmd, 0)
  local t = r.GetCursorPosition()
  r.SetEditCurPos(old, false, false)
  if snap then
    local snap_toggle = M.find_action({ section = 0, id = 1157, words = { "toggle snapping" } })
    if snap_toggle and r.GetToggleCommandState(snap_toggle) == 1 then t = r.SnapToGrid(0, t) end
  end
  return t
end

local function item_bounds(item)
  local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  return pos, pos + r.GetMediaItemInfo_Value(item, "D_LENGTH")
end

local function edit(desc, fn)
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  fn()
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock(M.NAME .. ": " .. desc, -1)
end

-- Eraser: delete the clicked item.
function M.erase_item_under_mouse()
  local item = M.item_under_mouse()
  if not item then return M.no_undo() end
  edit("Erase item", function()
    r.DeleteTrackMediaItem(r.GetMediaItem_Track(item), item)
  end)
end

-- Mute: toggle mute on the clicked item. If it is part of the current
-- selection, all selected items follow it (like Cubase).
function M.mute_item_under_mouse()
  local item = M.item_under_mouse()
  if not item then return M.no_undo() end
  local new_state = r.GetMediaItemInfo_Value(item, "B_MUTE") == 1 and 0 or 1
  edit(new_state == 1 and "Mute item" or "Unmute item", function()
    if r.IsMediaItemSelected(item) then
      for i = 0, r.CountSelectedMediaItems(0) - 1 do
        r.SetMediaItemInfo_Value(r.GetSelectedMediaItem(0, i), "B_MUTE", new_state)
      end
    else
      r.SetMediaItemInfo_Value(item, "B_MUTE", new_state)
    end
  end)
end

local function is_midi(item)
  local take = r.GetActiveTake(item)
  return take ~= nil and r.TakeIsMIDI(take)
end

-- Glue: join the clicked item to the next item on the same track.
--   MIDI + MIDI : glued into one MIDI item (no audio is rendered).
--   Audio       : pieces that came from a split are healed back together
--                 (no new audio file). If that isn't possible, the two items
--                 are grouped so they move together - still no bounce.
function M.glue_item_under_mouse()
  local item = M.item_under_mouse()
  if not item then return M.no_undo() end
  local track = r.GetMediaItem_Track(item)
  local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")

  local next_item, next_pos
  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local it = r.GetTrackMediaItem(track, i)
    local p = r.GetMediaItemInfo_Value(it, "D_POSITION")
    if it ~= item and p > pos and (not next_pos or p < next_pos) then
      next_item, next_pos = it, p
    end
  end
  if not next_item then
    return show_tooltip("Glue: there is no item to the right of this one")
  end

  edit("Glue", function()
    r.SelectAllMediaItems(0, false)
    r.SetMediaItemSelected(item, true)
    r.SetMediaItemSelected(next_item, true)

    if is_midi(item) and is_midi(next_item) then
      local glue = M.find_action({ section = 0, id = 40362, words = { "glue items" }, without = { "time selection" } })
               or M.find_action({ section = 0, id = 40362, words = { "glue items" } })
      if glue then r.Main_OnCommand(glue, 0) end
      return
    end

    local before = r.CountTrackMediaItems(track)
    local heal = M.find_action({ section = 0, id = 40548, words = { "heal splits" } })
    if heal then r.Main_OnCommand(heal, 0) end
    if r.CountTrackMediaItems(track) == before then
      local group = M.find_action({ section = 0, id = 40032, words = { "group items" }, without = { "remove", "un" } })
      if group then r.Main_OnCommand(group, 0) end
    end
  end)
end

-- Object "Select Events Under Cursor": select every item at the mouse
-- position, on all tracks.
function M.select_at_mouse()
  local t = M.mouse_time(false)
  if not t then return M.no_undo() end
  edit("Select items under cursor", function()
    for i = 0, r.CountMediaItems(0) - 1 do
      local item = r.GetMediaItem(0, i)
      local s, e = item_bounds(item)
      r.SetMediaItemSelected(item, s <= t and t < e)
    end
  end)
end

-- Object "Select Objects Behind": clicking overlapping items selects the one
-- underneath; each further click goes one item deeper, then back to the top.
function M.select_behind()
  local item = M.item_under_mouse()
  local t = M.mouse_time(false)
  if not item or not t then return M.no_undo() end
  local track = r.GetMediaItem_Track(item)

  local stack, top, selected = {}, nil, nil
  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local it = r.GetTrackMediaItem(track, i)
    local s, e = item_bounds(it)
    if s <= t and t < e then
      stack[#stack + 1] = it
      if it == item then top = #stack end
      if not selected and r.IsMediaItemSelected(it) then selected = #stack end
    end
  end
  if #stack == 0 then return M.no_undo() end

  local pick
  if selected then
    pick = stack[selected % #stack + 1]           -- one further down (wraps round)
  else
    pick = stack[(top or 0) % #stack + 1]         -- the one behind the visible item
  end
  edit("Select item behind", function()
    r.SelectAllMediaItems(0, false)
    r.SetMediaItemSelected(pick, true)
  end)
end

-- Scissors "Split All Selected Items": split the clicked item and every
-- selected item at the mouse position.
function M.split_selected_at_mouse()
  local clicked = M.item_under_mouse()
  local t = M.mouse_time(true)
  if not clicked or not t then return M.no_undo() end
  local targets = { clicked }
  for i = 0, r.CountSelectedMediaItems(0) - 1 do
    local it = r.GetSelectedMediaItem(0, i)
    if it ~= clicked then targets[#targets + 1] = it end
  end
  edit("Split selected items", function()
    for _, it in ipairs(targets) do
      local s, e = item_bounds(it)
      if s < t and t < e then r.SplitMediaItem(it, t) end
    end
  end)
end

-- Scissors Alt+click: cut the item into repeated pieces as long as the
-- distance from its start to the click.
function M.split_repeat_at_mouse()
  local item = M.item_under_mouse()
  local t = M.mouse_time(true)
  if not item or not t then return M.no_undo() end
  local s, e = item_bounds(item)
  local piece = t - s
  if piece < 0.001 then return M.no_undo() end
  edit("Split into repeated pieces", function()
    local current, pos = item, t
    while current and pos < e - 0.0001 do
      current = r.SplitMediaItem(current, pos)
      pos = pos + piece
    end
  end)
end

-- Play "Play From Click": click to play from the mouse, click again to stop.
function M.play_from_mouse()
  if r.GetPlayState() & 1 == 1 then
    r.OnStopButton()
    return M.no_undo()
  end
  local t = M.mouse_time(false)
  if t then
    r.SetEditCurPos(t, false, false)
    r.OnPlayButton()
  end
  M.no_undo()
end

-- Zoom: zoom in/out horizontally, centred on the mouse.
function M.zoom_at_mouse(factor)
  local level = r.GetHZoomLevel() * factor
  r.adjustZoom(level, 1, true, 3)   -- forceset=1: absolute pixels/second, centermode 3 = mouse
  M.no_undo()
end

-- Time Warp: add a tempo marker at the grid line nearest the mouse.
function M.tempo_marker_at_mouse()
  local t = M.mouse_time()
  if not t then return M.no_undo() end
  t = r.SnapToGrid(0, t)

  for i = 0, r.CountTempoTimeSigMarkers(0) - 1 do
    local _, mpos = r.GetTempoTimeSigMarker(0, i)
    if math.abs(mpos - t) < 0.001 then return M.no_undo() end   -- already one here
  end

  local bpm = r.Master_GetTempo()
  local prev = r.FindTempoTimeSigMarker(0, t)
  if prev >= 0 then
    local _, _, _, _, prev_bpm = r.GetTempoTimeSigMarker(0, prev)
    bpm = prev_bpm
  end

  edit("Insert tempo marker", function()
    r.SetTempoTimeSigMarker(0, -1, t, -1, -1, bpm, 0, 0, false)
  end)
  r.UpdateTimeline()
end

return M
