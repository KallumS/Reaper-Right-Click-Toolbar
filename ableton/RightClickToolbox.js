/* Right-Click Toolbox - built by ableton/kit/build.py from ableton/device.json. Do not edit; edit the sources and rebuild. */
var DEVICE = {"title": "Right-Click Toolbox"};
DEVICE.files = {};

/* ---- kit/palette.js ---- */
/* The devices' colours in Live: after Ableton Live 8's default theme.
 *
 * The scheme is Starting Blocks' own experiment of 18 September 2026
 * (commit 2765b0a3, "theme the window after Live 8"): a neutral grey chrome
 * meant to sit quietly under brightly coloured clips, controls raised off it,
 * and one warm amber spent where Live spends its accent, on what is switched
 * on. It was built from the theme's described character, not Live's own
 * files, so it is a likeness, not a match.
 *
 * Two changes from that experiment, both for the family's rules (every word
 * 7:1 on what it sits on, ink on every button, marks and edges 3:1):
 *   - the chrome is #3E3E3E, a step darker than its #4A4A4A, because on
 *     #4A4A4A a secondary word cannot reach 7:1 and still look secondary;
 *   - buttons are a light grey with dark ink, as the house scheme's are,
 *     because light words on its #5E5E5E buttons reach only 5:1.
 * The greys are neutral (R = G = B), as Live's are: the house rule that
 * every grey leans blue is the yellow scheme's, and Live's look is not that.
 *
 * Palette.tone(r, g, b) is how the REAPER windows (the JSFX and Lua scripts,
 * drawn through gfx.js) take the scheme without a line of theirs changing:
 *   - the house scheme's own colours map one for one (HOUSE below), each
 *     chosen so the pairs the scripts rely on stay 7:1 for words and 3:1
 *     for edges;
 *   - the house yellow, and the shades the scripts make of it, become the
 *     amber, shaded the same way;
 *   - any other grey loses its tint at the same brightness, so a script
 *     with a palette of its own keeps every contrast it had;
 *   - every other colour (a material, an engine, a part) is left alone.
 */
var Palette = (function () {
  'use strict';
  var C = {
    ground: 0x3E3E3E,     // the chrome: Live 8's #4A4A4A, a step darker (see above)
    raised: 0x484848,     // a control that is off
    sunken: 0x2E2E2E,     // lists, fields, a roll or a page: Live 8's roll ground
    deep: 0x262626,       // a roll's own ground under a sunken frame
    popup: 0x333333,      // menus
    rule: 0x555555,       // separators: they group, they do not act
    edge: 0x8C8C8C,       // the edge of anything that acts: 3.2:1 on the chrome
    control: 0xB4B4B4,    // buttons, with ink on them
    controlHover: 0xC4C4C4,
    controlHeld: 0xAAAAAA,
    accent: 0xD7A93C,     // Live 8's warm amber: what is on
    accentHeld: 0xCDA139,  // held: ink on it still 7.2:1
    ink: 0x1A1A1A,        // words on a button, grey or amber; also a window's darkest ground
                          // (AutoCC paints its window in the ink), so words are 7:1 on it too
    text: 0xF0F0F0,       // 9.4:1 on the chrome
    label: 0xD8D8D8,      // 7.5:1
    dim: 0xD4D4D4,        // secondary words, 7.2:1
    mark: 0xA8A8A8,       // a mark that is not a word, or a control that is off
    note: 0xA8D8E8,       // Live 8's cool note colour, for a roll
    ring: 0xFAFAFA,       // the keyboard's place
    warn: 0xF0605A,       // a warning's mark, never its words: 3.3:1 on the chrome
    warnText: 0xFFC8C2    // a warning's words, 7.3:1
  };
  // The house scheme (HousePalette, every family repo's docs/COLOUR.md) to this one.
  var HOUSE = {
    0x111419: C.deep, 0x14171C: C.ink, 0x1A1D23: C.sunken, 0x1B1F25: C.popup, 0x1E2228: 0x343434,
    0x22262D: 0x363636, 0x23272E: C.ground, 0x2A2F37: C.raised, 0x3A404A: C.rule, 0x585F6B: 0x707070,
    0x646B77: 0x7A7A7A, 0x6D7581: C.edge, 0x8A919C: C.mark, 0x8F96A2: C.controlHeld, 0xA9AFBA: C.control,
    0xB0B6C0: C.dim, 0xB6BCC6: C.dim, 0xBFC5CE: C.label, 0xC0C6CF: C.controlHover, 0xDDE1E7: C.text,
    0xF2F4F7: C.ring, 0xFFF200: C.accent, 0xD1C600: C.accentHeld, 0xFF9E96: C.warnText, 0xFFA6A0: C.warnText, 0xD2483F: C.warn
  };
  function rgb(hex, a) {
    return [((hex >> 16) & 255) / 255, ((hex >> 8) & 255) / 255, (hex & 255) / 255, a === undefined ? 1 : a];
  }
  function lin(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
  function unlin(l) { return l <= 0.0031308 ? l * 12.92 : 1.055 * Math.pow(l, 1 / 2.4) - 0.055; }
  function luminance(r, g, b) { return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b); }
  function contrast(a, b) {
    var la = luminance(a[0], a[1], a[2]), lb = luminance(b[0], b[1], b[2]);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
  }
  function clamp(x) { return x < 0 ? 0 : x > 1 ? 1 : x; }
  var AMBER = rgb(C.accent);
  // r, g, b from 0 to 1; returns [r, g, b].
  function tone(r, g, b) {
    r = clamp(r); g = clamp(g); b = clamp(b);
    var R = Math.round(r * 255), G = Math.round(g * 255), B = Math.round(b * 255);
    var hex = (R << 16) | (G << 8) | B;
    if (HOUSE[hex] !== undefined) { var t = rgb(HOUSE[hex]); return [t[0], t[1], t[2]]; }
    // The house yellow and its shades: lighter ones mix in white (blue rises
    // from 0), darker ones scale down (red and green fall together).
    if (R >= 120 && G >= 110 && Math.abs(R - G) <= 40 && B <= Math.min(R, G) - 90) {
      var w = B / 255, k = Math.max(R, G) / 255;
      return [0, 1, 2].map(function (i) { return clamp(AMBER[i] * k + (1 - AMBER[i] * k) * w); });
    }
    // A grey with a tint, from any palette: neutral at the same brightness.
    var hi = Math.max(R, G, B), lo = Math.min(R, G, B);
    if (hi - lo <= 28) { var n = unlin(luminance(r, g, b)); return [n, n, n]; }
    return [r, g, b];
  }
  return { C: C, HOUSE: HOUSE, rgb: rgb, tone: tone, luminance: luminance, contrast: contrast };
})();


/* ---- kit/ui.js ---- */
/* The family's look, drawn with Max's mgraphics in a [v8ui].
 *
 * Colours are Palette's (palette.js), after Ableton Live 8: neutral greys,
 * the amber accent for what is on, every word 7:1 on its surface. A control
 * registers its rectangle while it is painted, so a click goes to whatever
 * was drawn under it last paint - no layout is kept twice.
 */
var UI = (function () {
  'use strict';
  function rgb(hex, a) {
    return [((hex >> 16) & 255) / 255, ((hex >> 8) & 255) / 255, (hex & 255) / 255, a === undefined ? 1 : a];
  }
  // The colours are Palette's (palette.js): Live 8's neutral greys and amber.
  var P = Palette.C;
  var C = {
    accent: rgb(P.accent), accentHeld: rgb(P.accentHeld), control: rgb(P.control), controlHeld: rgb(P.controlHeld),
    ground: rgb(P.ground), raised: rgb(P.raised), sunken: rgb(P.sunken), rule: rgb(P.rule),
    edge: rgb(P.edge), ink: rgb(P.ink), text: rgb(P.text), dim: rgb(P.dim),
    label: rgb(P.label), warn: rgb(P.warn), warnText: rgb(P.warnText), mark: rgb(P.mark), note: rgb(P.note)
  };

  var g = null, hits = [], drag = null, FONT = 'Arial';

  function begin(graphics) {
    g = graphics;
    hits = [];
    g.select_font_face(FONT);
  }
  function fill(c) { g.set_source_rgba(c[0], c[1], c[2], c[3]); }
  function rect(x, y, w, h, c) { fill(c); g.rectangle(x, y, w, h); g.fill(); }
  function round(x, y, w, h, r, c) { fill(c); g.rectangle_rounded(x, y, w, h, r, r); g.fill(); }
  function frame(x, y, w, h, c) { fill(c); g.set_line_width(1); g.rectangle(x + 0.5, y + 0.5, w - 1, h - 1); g.stroke(); }
  function measure(s, size) { g.set_font_size(size || 10); var m = g.text_measure(String(s)); return m[0]; }

  // Text cut to fit, with an ellipsis, so a long name never runs into the next control.
  function fit(s, w, size) {
    s = String(s);
    if (measure(s, size) <= w) return s;
    while (s.length > 1 && measure(s + '…', size) > w) s = s.slice(0, -1);
    return s + '…';
  }
  // align: 0 left, 1 centre, 2 right; y is the box top, h its height.
  function text(s, x, y, w, h, c, size, align, bold) {
    size = size || 10;
    g.select_font_face(FONT, 'normal', bold ? 'bold' : 'normal');
    g.set_font_size(size);
    var t = fit(s, w, size), tw = measure(t, size);
    var tx = align === 1 ? x + (w - tw) / 2 : align === 2 ? x + w - tw : x;
    fill(c);
    g.move_to(tx, y + h / 2 + size * 0.36);
    g.show_text(t);
    g.select_font_face(FONT, 'normal', 'normal');
  }

  function hit(x, y, w, h, handler) { hits.push({ x: x, y: y, w: w, h: h, fn: handler }); }
  function find(px, py) {
    for (var i = hits.length - 1; i >= 0; i--) {
      var r = hits[i];
      if (px >= r.x && px < r.x + r.w && py >= r.y && py < r.y + r.h) return r;
    }
    return null;
  }

  // A push button: title-style words, ink on the control grey, accent when on.
  function button(label, x, y, w, h, on, handler, enabled) {
    var off = enabled === false;
    round(x, y, w, h, 3, off ? C.raised : on ? C.accent : C.control);
    text(label, x + 4, y, w - 8, h, off ? C.dim : C.ink, 10, 1, true);
    if (!off) hit(x, y, w, h, { click: handler });
  }

  // A value chosen from a list: click the left third for the one before, the
  // rest for the one after, or drag up and down through them.
  function stepper(label, names, index, x, y, w, onChange) {
    text(label, x, y, w, 12, C.label, 9, 0);
    var by = y + 13, bh = 18;
    round(x, by, w, bh, 3, C.sunken);
    frame(x, by, w, bh, C.rule);
    text('‹', x + 3, by, 8, bh, C.dim, 11, 1);
    text('›', x + w - 11, by, 8, bh, C.dim, 11, 1);
    text(names[index - 1] === undefined ? '' : names[index - 1], x + 12, by, w - 24, bh, C.text, 10, 1);
    var n = names.length;
    var last = index;
    function to(i) { i = Math.max(1, Math.min(n, i)); if (i !== last) { last = i; onChange(i); } }
    hit(x, by, w, bh, {
      click: function (px) { to(px < x + w / 3 ? index - 1 : index + 1); },
      drag: function (dy) { to(index - Math.round(dy / 8)); }
    });
  }

  // The same, in one line for a small panel (a MIDI Tool's): the label at
  // the left, the value at the right, the arrows at the ends.
  function row(label, names, index, x, y, w, h, onChange) {
    round(x, y, w, h, 3, C.sunken);
    frame(x, y, w, h, C.rule);
    text('‹', x + 1, y, 8, h, C.dim, 10, 1);
    text('›', x + w - 9, y, 8, h, C.dim, 10, 1);
    var lw = Math.round((w - 18) * 0.42);
    text(label, x + 10, y, lw - 2, h, C.label, 9, 0);
    text(names[index - 1] === undefined ? '' : names[index - 1], x + 10 + lw, y, w - 20 - lw, h, C.text, 9, 2);
    var n = names.length, last = index;
    function to(i) { i = Math.max(1, Math.min(n, i)); if (i !== last) { last = i; onChange(i); } }
    hit(x, y, w, h, {
      click: function (px) { to(px < x + w / 3 ? index - 1 : index + 1); },
      drag: function (dy) { to(index - Math.round(dy / 8)); }
    });
  }

  function toggle(label, on, x, y, w, h, onChange) {
    round(x, y, w, h, 3, on ? C.accent : C.control);
    text(label, x + 4, y, w - 8, h, C.ink, 10, 1, true);
    hit(x, y, w, h, { click: function () { onChange(!on); } });
  }

  // Mouse, as [v8ui] delivers it: onclick then ondrag until the button is up.
  function click(px, py) {
    var r = find(px, py);
    drag = null;
    if (!r) return false;
    if (r.fn.drag) drag = { r: r, y0: py, moved: false };
    else if (r.fn.click) r.fn.click(px, py);
    return true;
  }
  function dragTo(px, py, down) {
    if (!drag) return;
    var dy = drag.y0 - py;
    if (down) {
      if (Math.abs(dy) >= 4) drag.moved = true;
      if (drag.moved) drag.r.fn.drag(dy);
    } else {
      if (!drag.moved && drag.r.fn.click) drag.r.fn.click(px, py);
      drag = null;
    }
  }

  return { C: C, begin: begin, rect: rect, round: round, frame: frame, text: text, fit: fit, measure: measure,
           hit: hit, button: button, stepper: stepper, row: row, toggle: toggle, click: click, dragTo: dragTo, find: find };
})();


/* ---- kit/live.js ---- */
/* The Live set, as the family's devices need it: the song's tempo, meter and
 * scale, the notes of the clip being edited, somewhere to put new notes, and
 * a way to hear notes before they are used.
 *
 * Everything goes through the Live Object Model (LiveAPI). Times are beats,
 * which in Live are quarter notes - the unit every family engine already
 * speaks - so nothing is converted but the field names.
 */
var Live = (function () {
  'use strict';
  function api(path) { return new LiveAPI(null, path); }
  function one(a, prop) { var v = a.get(prop); return Array.isArray(v) ? v[0] : v; }
  function exists(a) { return a && Number(a.id) !== 0; }
  function json(v) {
    if (typeof v === 'string') return JSON.parse(v);
    if (Array.isArray(v) && typeof v[0] === 'string' && v.length === 1) return JSON.parse(v[0]);
    return v;
  }

  // Live 12's scale names, as ScaleView numbers its scales (1-16). A scale
  // ScaleView has no name for is left out: the device keeps its own key.
  var SCALE = {
    'Major': 1, 'Minor': 2, 'Harmonic Minor': 3, 'Dorian': 5, 'Phrygian': 6, 'Lydian': 7,
    'Mixolydian': 8, 'Major Pentatonic': 10, 'Minor Pentatonic': 11, 'Minor Blues': 13,
    'Whole Tone': 14, 'Whole-half Dim.': 15, 'Half-whole Dim.': 16
  };
  // ScaleView's eighteen roots, and the spelling a key on each pitch class
  // takes: flats for the major side, sharps where a minor key has them.
  var ROOTS = ['C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B', 'Cb'];
  var MAJOR_SIDE = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
  var MINOR_SIDE = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B'];
  var MINORISH = { 2: 1, 3: 1, 5: 1, 6: 1, 11: 1, 13: 1 };
  var SCALE_NAMES = ['Major', 'Minor (Natural)', 'Harmonic Minor', 'Ionian', 'Dorian', 'Phrygian', 'Lydian',
                     'Mixolydian', 'Aeolian', 'Major Pentatonic', 'Minor Pentatonic', 'Major Blues', 'Minor Blues',
                     'Whole Tone', 'Diminished Whole-Half', 'Diminished Half-Whole'];

  // Live's scale (a root pitch class and a name) as the family's key, or
  // null for a scale ScaleView does not have.
  function keyOf(pc, name) {
    var sc = SCALE[String(name)];
    if (!sc) return null;
    return { root: ROOTS.indexOf((MINORISH[sc] ? MINOR_SIDE : MAJOR_SIDE)[((+pc % 12) + 12) % 12]) + 1, scale: sc };
  }

  function song() {
    var s = api('live_set');
    var out = { tempo: +one(s, 'tempo') || 120, num: +one(s, 'signature_numerator') || 4,
                den: +one(s, 'signature_denominator') || 4, playing: !!+one(s, 'is_playing'),
                position: +one(s, 'current_song_time') || 0, key: null };
    var mode = s.get('scale_mode');
    if (mode !== undefined && mode !== null) {
      var name = String(one(s, 'scale_name')), pc = +one(s, 'root_note');
      out.liveScale = { on: !!+(Array.isArray(mode) ? mode[0] : mode), name: name, root: pc };
      out.key = keyOf(pc, name);
    }
    return out;
  }

  function detailClip() {
    var c = api('live_set view detail_clip');
    if (!exists(c) || !+one(c, 'is_midi_clip')) return null;
    return c;
  }

  // The clip being edited: its selected notes if any are selected, else every
  // note in its loop. Starts are from the start of what was taken.
  function clipNotes() {
    var c = detailClip();
    if (!c) return null;
    var from = +one(c, 'loop_start') || 0, to = +one(c, 'loop_end') || 0;
    var raw = null, selected = false;
    try { raw = json(c.call('get_selected_notes_extended')); selected = raw && raw.notes && raw.notes.length > 0; } catch (e) { raw = null; }
    if (!selected) raw = json(c.call('get_notes_extended', 0, 128, from, Math.max(0, to - from)));
    var notes = ((raw && raw.notes) || []).filter(function (n) { return !n.mute; }).map(function (n) {
      return { start: n.start_time, len: n.duration, pitch: n.pitch, vel: Math.round(n.velocity) };
    });
    var first = selected && notes.length ? Math.min.apply(null, notes.map(function (n) { return n.start; })) : from;
    var beats = to - from;
    if (selected) {
      var bar = 4, end = 0;
      notes.forEach(function (n) { end = Math.max(end, n.start + n.len); });
      first = Math.floor(first / bar) * bar;
      beats = Math.ceil((end - first) / bar) * bar;
    }
    notes.forEach(function (n) { n.start -= first; });
    notes.sort(function (a, b) { return a.start - b.start || a.pitch - b.pitch; });
    return { notes: notes, beats: beats, name: String(one(c, 'name') || ''), selected: selected, drums: drumTrack() };
  }

  // A track whose instrument is a Drum Rack plays drums: its note numbers name
  // drums, not pitches, and the engines treat them that way.
  function drumTrack() {
    try {
      var track = api('this_device canonical_parent'), n = track.getcount('devices');
      for (var i = 0; i < n; i++) if (+one(api(track.unquotedpath + ' devices ' + i), 'can_have_drum_pads')) return true;
    } catch (e) { /* not known: not drums */ }
    return false;
  }

  function liveNotes(notes) {
    return { notes: notes.map(function (n) {
      return { pitch: Math.max(0, Math.min(127, Math.round(n.pitch))), start_time: Math.max(0, n.start),
               duration: Math.max(1 / 128, n.len), velocity: Math.max(1, Math.min(127, Math.round(n.vel || 100))), mute: 0 };
    }) };
  }

  function undoable(fn) {
    var s = api('live_set');
    try { s.call('begin_undo_step'); } catch (e) { /* Live before 11.1 */ }
    try { return fn(); } finally { try { s.call('end_undo_step'); } catch (e2) { /* as above */ } }
  }

  function show(clip) {
    try { api('live_set view').set('detail_clip', 'id', Number(clip.id)); } catch (e) { /* the clip is made either way */ }
  }

  function selectedScene() {
    var scene = api('live_set view selected_scene'), n = api('live_set').getcount('scenes');
    for (var i = 0; i < n; i++) if (Number(api('live_set scenes ' + i).id) === Number(scene.id)) return i;
    return 0;
  }
  function thisTrack() {
    var track = api('this_device canonical_parent');
    if (!exists(track) || !+one(track, 'has_midi_input')) return null;
    return track;
  }
  // Where this device's track is in the set, for putting new tracks beside it.
  function trackIndex(track) {
    var n = api('live_set').getcount('tracks');
    for (var i = 0; i < n; i++) if (Number(api('live_set tracks ' + i).id) === Number(track.id)) return i;
    return n - 1;
  }
  function clipInSlot(slot, notes, beats, name) {
    slot.call('create_clip', Math.max(1, beats));
    var clip = api(slot.unquotedpath + ' clip');
    if (name) clip.set('name', name);
    clip.call('add_new_notes', liveNotes(notes));
    return clip;
  }
  function freeSlot(track, from) {
    var n = track.getcount('clip_slots');
    for (var k = 0; k < n; k++) {
      var at = (from + k) % n, slot = api(track.unquotedpath + ' clip_slots ' + at);
      if (!+one(slot, 'has_clip')) return { slot: slot, at: at };
    }
    return null;
  }
  function arrangementClipOn(track, notes, beats, name, at) {
    var before = track.getcount('arrangement_clips');
    try { track.call('create_midi_clip', at, Math.max(1, beats)); } catch (e) { /* checked below */ }
    var count = track.getcount('arrangement_clips');
    if (!(count > before)) return false;
    for (var i = 0; i < count; i++) {
      var clip = api(track.unquotedpath + ' arrangement_clips ' + i);
      if (Math.abs((+one(clip, 'start_time') || 0) - at) < 1e-6) {
        if (name) clip.set('name', name);
        clip.call('add_new_notes', liveNotes(notes));
        return true;
      }
    }
    return false;
  }

  // New notes, as a new clip in the first free slot on this device's track,
  // from the selected scene down. `more` are further parts ({name, notes}),
  // each on a new MIDI track after this one, in the same scene. Returns what
  // happened, for the status line.
  function newClip(notes, beats, name, more) {
    var track = thisTrack();
    if (!track) return { ok: false, message: 'This device needs to be on a MIDI track.' };
    var free = freeSlot(track, selectedScene());
    if (!free) return { ok: false, message: 'Every clip slot on this track is full. Add a scene, then try again.' };
    return undoable(function () {
      var clip = clipInSlot(free.slot, notes, beats, name);
      var made = newTracks(track, more, function (t) {
        clipInSlot(api(t.unquotedpath + ' clip_slots ' + free.at), this.notes, beats, this.name);
      });
      show(clip);
      return { ok: true, message: 'Added a clip in scene ' + (free.at + 1) + (made ? ', and ' + made + ' on new tracks beside it.' : '.') };
    });
  }

  // New notes on a new MIDI track beside this one, in the selected scene:
  // a suggestion goes with the music it was made for, not over it.
  function newTrackClip(notes, beats, name, more) {
    var track = thisTrack();
    if (!track) return { ok: false, message: 'This device needs to be on a MIDI track.' };
    var scene = selectedScene();
    return undoable(function () {
      var parts = [{ name: name, notes: notes }].concat(more || []);
      newTracks(track, parts, function (t) { show(clipInSlot(api(t.unquotedpath + ' clip_slots ' + scene), this.notes, beats, this.name)); });
      return { ok: true, message: parts.length === 1 ? 'Added a track beside this one, with the clip in scene ' + (scene + 1) + '.'
                                                     : 'Added ' + parts.length + ' tracks beside this one, with the clips in scene ' + (scene + 1) + '.' };
    });
  }

  // Each further part on a new MIDI track, in order, after this one.
  function newTracks(track, more, put) {
    if (!more || !more.length) return '';
    var at = trackIndex(track), song = api('live_set');
    more.forEach(function (part, k) {
      song.call('create_midi_track', at + 1 + k);
      var t = api('live_set tracks ' + (at + 1 + k));
      t.set('name', part.name);
      put.call(part, t);
    });
    return more.length === 1 ? 'one more part' : more.length + ' more parts';
  }

  // New notes in place of the notes of the clip being edited, from its loop start.
  function replaceInClip(notes, beats) {
    var c = detailClip();
    if (!c) return { ok: false, message: 'No MIDI clip is open. Open one in Detail View, then try again.' };
    var from = +one(c, 'loop_start') || 0;
    return undoable(function () {
      var span = Math.max(beats, (+one(c, 'loop_end') || 0) - from);
      c.call('remove_notes_extended', 0, 128, from, span);
      c.call('add_new_notes', liveNotes(notes.map(function (n) {
        return { start: n.start + from, len: n.len, pitch: n.pitch, vel: n.vel };
      })));
      if ((+one(c, 'loop_end') || 0) < from + beats) c.set('loop_end', from + beats);
      return { ok: true, message: 'Replaced the notes in “' + (String(one(c, 'name') || '') || 'the clip') + '”.' };
    });
  }

  // New notes in the Arrangement at the insert marker, on this device's track
  // (Track.create_midi_clip, Live 12.2 and later); further parts as above.
  function arrangementClip(notes, beats, name, more) {
    var track = thisTrack();
    if (!track) return { ok: false, message: 'This device needs to be on a MIDI track.' };
    var at = +one(api('live_set'), 'current_song_time') || 0;
    return undoable(function () {
      if (!arrangementClipOn(track, notes, beats, name, at)) {
        return { ok: false, message: 'This version of Live can\u2019t add Arrangement clips from a device. Choose New Clip instead.' };
      }
      var made = newTracks(track, more, function (t) { arrangementClipOn(t, this.notes, beats, this.name, at); });
      return { ok: true, message: 'Added a clip to the Arrangement at beat ' + (Math.round(at * 100) / 100 + 1) +
               (made ? ', and ' + made + ' on new tracks beside it.' : '.') };
    });
  }

  // ------------------------------------------------------------ player ---
  // Notes heard through this device's MIDI out: the instrument after it on
  // the track plays them. A Task ticks every few milliseconds and sends what
  // is due; nothing waits on the transport.
  function Player(send) {
    this.send = send; this.events = []; this.pos = 0; this.t0 = 0; this.task = null; this.sounding = {};
    this.onEnd = null;
  }
  Player.prototype.play = function (notes, tempo, onEnd) {
    this.stop();
    var ms = 60000 / (tempo || 120), ev = [];
    notes.forEach(function (n) {
      ev.push({ t: n.start * ms, on: true, pitch: n.pitch, vel: n.vel || 100 });
      ev.push({ t: (n.start + n.len) * ms - 1, on: false, pitch: n.pitch });
    });
    ev.sort(function (a, b) { return a.t - b.t || (a.on === b.on ? 0 : a.on ? 1 : -1); });
    this.events = ev; this.pos = 0; this.t0 = Date.now(); this.onEnd = onEnd || null;
    var self = this;
    this.task = new Task(function () { self.tick(); }, this);
    this.task.interval = 4;
    this.task.repeat();
    this.tick();
  };
  Player.prototype.tick = function () {
    var now = Date.now() - this.t0;
    while (this.pos < this.events.length && this.events[this.pos].t <= now) {
      var e = this.events[this.pos++];
      if (e.on) { this.sounding[e.pitch] = (this.sounding[e.pitch] || 0) + 1; this.send([0x90, e.pitch, Math.max(1, Math.min(127, Math.round(e.vel)))]); }
      else if (this.sounding[e.pitch]) { this.sounding[e.pitch]--; this.send([0x80, e.pitch, 0]); }
    }
    if (this.pos >= this.events.length) {
      var end = this.onEnd;
      this.stop();
      if (end) end();
    }
  };
  Player.prototype.playing = function () { return !!this.task; };
  Player.prototype.stop = function () {
    if (this.task) { this.task.cancel(); this.task.freepeer && this.task.freepeer(); this.task = null; }
    var self = this;
    Object.keys(this.sounding).forEach(function (p) {
      for (var i = 0; i < self.sounding[p]; i++) self.send([0x80, +p, 0]);
    });
    this.sounding = {};
    this.onEnd = null;
  };

  return { song: song, clipNotes: clipNotes, newClip: newClip, newTrackClip: newTrackClip, replaceInClip: replaceInClip,
           arrangementClip: arrangementClip, drumTrack: drumTrack, Player: Player, ROOTS: ROOTS, SCALE_NAMES: SCALE_NAMES,
           keyOf: keyOf };
})();


/* ---- toolbox.js ---- */
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

