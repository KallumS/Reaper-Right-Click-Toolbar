--[[
  Cubase Toolbox for REAPER - core library
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

M.NAME = "Cubase Toolbox"
M.EXT  = "CubaseToolbox"          -- ExtState section used for all saved data

M.SECTION_MAIN = 0
M.SECTION_MIDI = 32060

M.lib_dir  = debug.getinfo(1, "S").source:match("^@?(.*[/\\])")
M.root_dir = M.lib_dir:match("^(.*[/\\])[^/\\]+[/\\]$")

-- Modifier-key flags used by SetMouseModifier
local NONE, ALT = 0, 4

---------------------------------------------------------------------------
-- Tool definitions
---------------------------------------------------------------------------
-- Each slot is one mouse-modifier assignment:
--   ctx   = mouse context (see reaper-mouse.ini)
--   mod   = modifier flag (0 = no modifier key held)
--   one of:
--     id / name  = built-in mouse behaviour. The name is tried first, the id
--                  (" m") is the fallback.
--     helper     = one of this package's helper scripts (see HELPERS below)
--     action     = a built-in REAPER action, checked/found by name at runtime
--
-- override = letter of a REAPER 7 "arrange view override" set (A-D). When set,
--            left-drag anywhere in the arrange view (items or empty space)
--            uses that set instead of the normal contexts.
-- fallback = slots used only if the override action can't be found.

local SPLIT_ITEM   = { section = 0,     id = 40746, words = { "split", "item", "mouse" } }
local SPLIT_NOTES  = { section = 32060,             words = { "split", "note", "mouse" } }

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

M.TOOLS = {
  {
    id = "select", label = "Object Selection", file = "01 Object Selection",
    help = "Normal REAPER behaviour: select, move, resize, copy and trim.",
    slots = {},
  },
  {
    id = "stretch", label = "Object Selection - Sizing Applies Time Stretch", file = "02 Sizing Applies Time Stretch",
    help = "Like Object Selection, but dragging an item edge time-stretches the audio.",
    slots = {
      { ctx = "MM_CTX_ITEMEDGE", mod = NONE, id = 2, name = "Stretch item" },
    },
  },
  {
    id = "range", label = "Range Selection", file = "03 Range Selection",
    help = "Drag to select a time range across tracks (REAPER razor edit).",
    override = "B",
    slots = {},
    fallback = {
      { ctx = "MM_CTX_ITEM",  mod = NONE, id = 62, name = "Select razor edit area" },
      { ctx = "MM_CTX_TRACK", mod = NONE,          name = "Select razor edit area" },
    },
  },
  {
    id = "split", label = "Split (Scissors)", file = "04 Split",
    help = "Click an item (or MIDI note) to split it at the mouse.",
    slots = with(ITEM_NO_DRAG, {
      { ctx = "MM_CTX_ITEM_CLK",      mod = NONE, action = SPLIT_ITEM },
      { ctx = "MM_CTX_MIDI_NOTE_CLK", mod = NONE, action = SPLIT_NOTES },
      { ctx = "MM_CTX_MIDI_NOTE",     mod = NONE, id = 0, name = "No action" },
    }),
  },
  {
    id = "glue", label = "Glue", file = "05 Glue",
    help = "Click an item to join it to the next item on the same track.",
    slots = with(ITEM_NO_DRAG, {
      { ctx = "MM_CTX_ITEM_CLK", mod = NONE, helper = "glue" },
    }),
  },
  {
    id = "erase", label = "Eraser", file = "06 Eraser",
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
    id = "zoom", label = "Zoom", file = "07 Zoom",
    help = "Drag a box to zoom into it. Click to zoom in, Alt+click to zoom out.",
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
  },
  {
    id = "mute", label = "Mute", file = "08 Mute",
    help = "Click items or MIDI notes to mute/unmute them.",
    slots = with(ITEM_NO_DRAG, {
      { ctx = "MM_CTX_ITEM_CLK",      mod = NONE, helper = "mute" },
      { ctx = "MM_CTX_MIDI_NOTE_CLK", mod = NONE, id = 7, name = "Toggle note mute" },
      { ctx = "MM_CTX_MIDI_NOTE",     mod = NONE, id = 0, name = "No action" },
    }),
  },
  {
    id = "draw", label = "Draw (Pencil)", file = "09 Draw",
    help = "Draw empty MIDI items, automation, MIDI notes and CC data.",
    slots = {
      { ctx = "MM_CTX_TRACK",          mod = NONE, id = 5, name = "Draw an empty MIDI item" },
      { ctx = "MM_CTX_ENVSEG",         mod = NONE, id = 3, name = "Freehand draw envelope" },
      { ctx = "MM_CTX_ENVPT",          mod = NONE, id = 3, name = "Freehand draw envelope" },
      { ctx = "MM_CTX_MIDI_PIANOROLL", mod = NONE, id = 1, name = "Insert note, drag to extend or change pitch" },
      { ctx = "MM_CTX_MIDI_CCLANE",    mod = NONE, id = 1, name = "Draw/edit CC events ignoring selection" },
      { ctx = "MM_CTX_MIDI_CCEVT",     mod = NONE, id = 18, name = "Draw/edit CC events ignoring selection" },
    },
  },
  {
    id = "line", label = "Line", file = "10 Line",
    help = "Draw straight ramps: MIDI CC/velocity, rows of notes, envelope points.",
    slots = {
      { ctx = "MM_CTX_ENVSEG",         mod = NONE, id = 2, name = "Insert envelope point, drag to move" },
      { ctx = "MM_CTX_MIDI_PIANOROLL", mod = NONE, id = 23, name = "Paint a straight line of notes" },
      { ctx = "MM_CTX_MIDI_CCLANE",    mod = NONE, id = 5, name = "Linear ramp CC events" },
      { ctx = "MM_CTX_MIDI_CCEVT",     mod = NONE, id = 24, name = "Linear ramp CC events" },
    },
  },
  {
    id = "play", label = "Play / Scrub", file = "11 Play Scrub",
    help = "Drag to scrub audio like tape. In the MIDI editor, drag to preview notes.",
    override = "D",
    slots = {
      { ctx = "MM_CTX_ARRANGE_D",      mod = NONE, id = 10, name = "Scrub audio" },
      { ctx = "MM_CTX_MIDI_PIANOROLL", mod = NONE, id = 16, name = "Scrub preview MIDI" },
    },
  },
  {
    id = "hand", label = "Hand (Scroll)", file = "12 Hand",
    help = "Drag to scroll around the project without changing the zoom.",
    override = "D",
    slots = {
      { ctx = "MM_CTX_ARRANGE_D", mod = NONE, id = 8, name = "Hand scroll" },
    },
  },
  {
    id = "drumstick", label = "Drumstick (MIDI editor)", file = "13 Drumstick",
    help = "MIDI editor: click or drag to paint drum hits, click a hit to remove it.",
    slots = {
      { ctx = "MM_CTX_MIDI_PIANOROLL",     mod = NONE, id = 22, name = "Paint notes" },
      { ctx = "MM_CTX_MIDI_PIANOROLL_CLK", mod = NONE, id = 4,  name = "Insert note" },
      { ctx = "MM_CTX_MIDI_NOTE_CLK",      mod = NONE, id = 6,  name = "Erase note" },
    },
  },
  {
    id = "timewarp", label = "Time Warp", file = "14 Time Warp",
    help = "Click to add a tempo marker at the nearest grid line, then drag tempo markers in the ruler to line the grid up with the audio.",
    slots = with(ITEM_NO_DRAG, {
      { ctx = "MM_CTX_ITEM_CLK",     mod = NONE, helper = "tempo_marker" },
      { ctx = "MM_CTX_TRACK_CLK",    mod = NONE, helper = "tempo_marker" },
      { ctx = "MM_CTX_TEMPOMARKER",  mod = NONE, id = 3, name = "Move project tempo/time signature marker, adjusting previous tempo" },
    }),
  },
}

M.TOOLS_BY_ID = {}
for i, t in ipairs(M.TOOLS) do
  t.index = i
  M.TOOLS_BY_ID[t.id] = t
end

-- Helper scripts (live next to this file), used for click behaviours REAPER
-- doesn't have built in.
M.HELPERS = {
  erase        = "Cubase Toolbox helper - Erase item under mouse.lua",
  mute         = "Cubase Toolbox helper - Mute item under mouse.lua",
  glue         = "Cubase Toolbox helper - Glue item under mouse to next.lua",
  zoom_in      = "Cubase Toolbox helper - Zoom in at mouse.lua",
  zoom_out     = "Cubase Toolbox helper - Zoom out at mouse.lua",
  tempo_marker = "Cubase Toolbox helper - Insert tempo marker at mouse.lua",
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

-- Put back every mouse setting we changed, and switch off any override set
-- that we switched on.
function M.restore_all()
  for _, key in ipairs(backup_list()) do restore_slot(key) end
  del("backup_list")
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
-- Scripts call this so their toolbar button can light up.
function M.remember_script(tool_id, section, cmd)
  if not cmd or cmd == 0 then return end
  local named = r.ReverseNamedCommandLookup(cmd)
  if named and named ~= "" then
    set("cmd|" .. tool_id .. "|" .. section, named)
  end
end

function M.refresh_toggle_states()
  local current = M.current_tool()
  for _, tool in ipairs(M.TOOLS) do
    for _, section in ipairs({ M.SECTION_MAIN, M.SECTION_MIDI }) do
      local named = get("cmd|" .. tool.id .. "|" .. section)
      if named then
        local cmd = r.NamedCommandLookup("_" .. named)
        if cmd ~= 0 then
          r.SetToggleCommandState(section, cmd, tool.id == current and 1 or 0)
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

function M.set_tool(id)
  local tool = M.TOOLS_BY_ID[id]
  if not tool then
    M.log("Unknown tool: " .. tostring(id))
    return
  end

  local problems = {}
  M.restore_all()

  for _, slot in ipairs(tool.slots) do apply_slot(slot, problems) end

  if tool.override and not enable_override(tool.override, problems) then
    for _, slot in ipairs(tool.fallback or {}) do apply_slot(slot, problems) end
  end

  set("current_tool", tool.id)
  M.refresh_toggle_states()

  if #problems > 0 then
    M.log("Tool '" .. tool.label .. "' is only partly active:\n  - " ..
          table.concat(problems, "\n  - ") ..
          "\nEverything else about this tool is working.")
  end
  show_tooltip("Tool: " .. tool.label)
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
  for _, tool in ipairs(M.TOOLS) do
    for _, section in ipairs({ M.SECTION_MAIN, M.SECTION_MIDI }) do
      local named = get("cmd|" .. tool.id .. "|" .. section)
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

-- Called by the "Cubase Toolbox - Tool ..." actions.
function M.run_tool_action(id, section, cmd)
  M.remember_script(id, section, cmd)
  M.set_tool(id)
  if M.autoclose_enabled() then
    -- wait until the button click has finished before closing its toolbar
    r.defer(M.close_tool_toolbars)
  end
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

function M.show_menu()
  local current = M.current_tool()
  local items = { "#" .. M.NAME, "" }
  local actions = { false, false }
  for _, tool in ipairs(M.TOOLS) do
    items[#items + 1] = (tool.id == current and "!" or "") .. menu_escape(tool.label)
    actions[#actions + 1] = tool.id
  end
  items[#items + 1] = ""
  actions[#actions + 1] = false
  items[#items + 1] = (M.autoclose_enabled() and "!" or "") .. "Close floating toolbar after picking a tool"
  actions[#actions + 1] = "@autoclose"
  items[#items + 1] = "What does the current tool do?"
  actions[#actions + 1] = "@help"
  items[#items + 1] = "Troubleshooting report (prints to console)"
  actions[#actions + 1] = "@diagnostics"

  -- gfx.showmenu numbers every item including the grey title line, but not
  -- separators, so build a lookup from menu number to action.
  local lookup = {}
  for i, item in ipairs(items) do
    if item ~= "" then lookup[#lookup + 1] = actions[i] end
  end

  local choice = show_menu_at_mouse(table.concat(items, "|"))
  local picked = lookup[choice]
  if not picked then return M.no_undo() end

  if picked == "@help" then
    local t = M.TOOLS_BY_ID[current]
    r.ShowMessageBox(t.label .. "\n\n" .. t.help, M.NAME, 0)
    return M.no_undo()
  elseif picked == "@autoclose" then
    M.set_autoclose(not M.autoclose_enabled())
    return M.no_undo()
  elseif picked == "@diagnostics" then
    M.diagnostics()
    return M.no_undo()
  end
  M.set_tool(picked)
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
    add(section, M.root_dir .. "Cubase Toolbox - Show tool menu.lua", false)
    for _, tool in ipairs(M.TOOLS) do
      local cmd = add(section, M.root_dir .. "Cubase Toolbox - Tool " .. tool.file .. ".lua", false)
      M.remember_script(tool.id, section, cmd)
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
  add("Current tool: " .. M.current_tool())
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
function M.mouse_time()
  local cmd = M.find_action({ section = 0, id = 40514, words = { "edit cursor to mouse cursor", "no snap" } })
  if not cmd then return nil end
  local old = r.GetCursorPosition()
  r.Main_OnCommand(cmd, 0)
  local t = r.GetCursorPosition()
  r.SetEditCurPos(old, false, false)
  return t
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
