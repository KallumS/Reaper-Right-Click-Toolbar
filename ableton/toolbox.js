/* The Right-Click Toolbox as a Max for Live device.
 *
 * In REAPER the toolbox rewrites the mouse modifiers, so the left button
 * works like the Cubase tool chosen. Live keeps its mouse to itself: no
 * device can change what a click in the Arrangement does. So the device
 * keeps the toolbox - the same thirteen tools, in the same order - and each
 * does the nearest thing a device can do in Live: Draw turns on Live's own
 * Draw Mode and Object Selection turns it off; Eraser, Mute and Glue's
 * neighbours act on the clip open in Detail View; Zoom zooms the
 * Arrangement; Play plays. A tool Live has but a device cannot reach (Split,
 * Range) says Live's own key for it instead.
 *
 * Expects, before it: UI, Live. Outlets: 0 MIDI bytes (MIDI passes
 * through), 1 the state to [pattr] (unused: a toolbox has no settings).
 */
inlets = 1;
outlets = 2;
mgraphics.init();
mgraphics.relative_coords = 0;
mgraphics.autofill = 0;

var T = { status: '', draw: false, ready: false };
function say(s) { T.status = s || ''; mgraphics.redraw(); }
function api(path) { return new LiveAPI(null, path); }
function one(a, p) { var v = a.get(p); return Array.isArray(v) ? v[0] : v; }
function exists(a) { return a && Number(a.id) !== 0; }

// The clip open in Detail View, or why there is none.
function clip() {
  var c = api('live_set view detail_clip');
  if (!exists(c)) { say('No clip is open. Open one in Detail View, then try again.'); return null; }
  return c;
}
function named(c) { return '“' + (String(one(c, 'name') || '') || 'the clip') + '”'; }
function undoable(fn) {
  var s = api('live_set');
  try { s.call('begin_undo_step'); } catch (e) { /* Live before 11.1 */ }
  try { return fn(); } finally { try { s.call('end_undo_step'); } catch (e2) { /* as above */ } }
}

// [name, what it does in Live]. The order is the toolbox's: Tool 01 to 13.
var TOOLS = [
  ['Object Selection', function () { setDraw(false); say('Object Selection: Draw Mode is off, so clicks select.'); }],
  ['Range Selection', function () { say('Range Selection: drag across tracks in the Arrangement, as Live always does.'); }],
  ['Split', function () { say('Split: in Live, put the cursor where to split and press ⌘E.'); }],
  ['Glue', function () {
    var c = clip(); if (!c) return;
    if (+one(c, 'is_midi_clip')) { undoable(function () { c.call('duplicate_loop'); }); say('Glue: Live joins clips with ⌘J. Here the loop of ' + named(c) + ' was doubled.'); }
    else say('Glue: select the clips and press ⌘J (Consolidate).');
  }],
  ['Eraser', function () {
    var c = clip(); if (!c) return;
    var name = named(c), parent = api(c.unquotedpath + ' canonical_parent');
    undoable(function () {
      if (exists(parent) && one(parent, 'has_clip') !== undefined) parent.call('delete_clip');
      else { var track = api(c.unquotedpath + ' canonical_parent'); track.call('delete_clip', 'id', Number(c.id)); }
    });
    say('Eraser: deleted ' + name + '.');
  }],
  ['Zoom', function () {
    try { api('live_app view').call('zoom_view', 3, 'Arranger', 0); say('Zoom: zoomed the Arrangement in. Option-click Zoom to zoom out.'); }
    catch (e) { say('Zoom: press + and − in the Arrangement.'); }
  }],
  ['Mute', function () {
    var c = clip(); if (!c) return;
    var on = !+one(c, 'muted');
    undoable(function () { c.set('muted', on ? 1 : 0); });
    say('Mute: ' + named(c) + (on ? ' is muted.' : ' plays again.'));
  }],
  ['Draw', function () { setDraw(true); say('Draw: Draw Mode is on (B), so dragging draws notes and envelopes.'); }],
  ['Line', function () { say('Line: in Draw Mode, hold ⌘ while drawing an envelope to draw a straight line.'); }],
  ['Play Scrub', function () {
    var s = api('live_set');
    if (+one(s, 'is_playing')) { s.call('stop_playing'); say('Play: stopped.'); }
    else { s.call('continue_playing'); say('Play: playing from the insert marker. Click the ruler to scrub.'); }
  }],
  ['Hand', function () { say('Hand: drag the ruler or the overview to move around the Arrangement.'); }],
  ['Drumstick', function () {
    var c = clip(); if (!c) return;
    undoable(function () { c.call('quantize', 5, 1); });
    say('Drumstick: Live has no drumstick; the notes of ' + named(c) + ' were put on the sixteenths instead (⌘U).');
  }],
  ['Time Warp', function () { say('Time Warp: double-click the clip’s waveform to add Warp Markers.'); }]
];
var ZOOM_OUT = function () {
  try { api('live_app view').call('zoom_view', 2, 'Arranger', 0); say('Zoom: zoomed the Arrangement out.'); }
  catch (e) { say('Zoom: press + and − in the Arrangement.'); }
};

function setDraw(on) {
  try { api('live_set view').set('draw_mode', on ? 1 : 0); T.draw = on; } catch (e) { /* not in Live */ }
}
function readDraw() {
  try { T.draw = !!+one(api('live_set view'), 'draw_mode'); } catch (e) { /* not in Live */ }
}

function bang() { T.ready = true; readDraw(); mgraphics.redraw(); var t = new Task(function () { readDraw(); mgraphics.redraw(); }, this); t.interval = 500; t.repeat(); }
function restore() {}
function msg_int(b) { outlet(0, b); }

// --------------------------------------------------------------- paint --
function paint() {
  var sz = (typeof box !== 'undefined' && box.rect) ? [box.rect[2] - box.rect[0], box.rect[3] - box.rect[1]] : [520, 169];
  var W = sz[0], Ht = sz[1];
  UI.begin(mgraphics);
  UI.rect(0, 0, W, Ht, UI.C.ground);
  UI.text(T.status || 'Pick a tool: each does the nearest thing Live lets a device do.', 6, 1, W - 12, 16, UI.C.dim, 10, 0);
  var cols = 4, bw = Math.floor((W - 12 - (cols - 1) * 6) / cols), bh = 26;
  TOOLS.forEach(function (t, i) {
    var col = i % cols, row = Math.floor(i / cols), x = 6 + col * (bw + 6), y = 22 + row * (bh + 8);
    var on = (t[0] === 'Draw' && T.draw) || (t[0] === 'Object Selection' && !T.draw);
    UI.button(t[0], x, y, bw, bh, on, function (px, py) { t[1](); });
  });
}
function onclick(x, y, but, cmd, shift, caps, opt) {
  var r = UI.find(x, y);
  // Option-click Zoom zooms out, as the Zoom tool does with Option in Cubase
  if (opt && r && hitIs(r, 'Zoom')) { ZOOM_OUT(); return; }
  if (UI.click(x, y)) mgraphics.redraw();
}
function hitIs(r, name) {
  var i = TOOLS.map(function (t) { return t[0]; }).indexOf(name), cols = 4;
  var sz = (typeof box !== 'undefined' && box.rect) ? box.rect[2] - box.rect[0] : 520, bw = Math.floor((sz - 12 - (cols - 1) * 6) / cols);
  var x = 6 + (i % cols) * (bw + 6), y = 22 + Math.floor(i / cols) * 34;
  return r.x === x && r.y === y;
}
function ondrag(x, y, but) { UI.dragTo(x, y, !!but); }
