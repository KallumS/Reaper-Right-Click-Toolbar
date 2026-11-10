/* The Max for Live device, run in Node on a pretend Max and a pretend Live.
 *   python3 ableton/kit/build.py ableton/device.json && node --test ableton/tests/ */
'use strict';
const test = require('node:test');
const assert = require('node:assert');
const path = require('node:path');
const { load, liveSet } = require('../kit/test/max.js');

const BUNDLE = path.join(__dirname, '..', 'RightClickToolbox.js');
const TOOLS = ['Object Selection', 'Range Selection', 'Split', 'Glue', 'Eraser', 'Zoom', 'Mute', 'Draw', 'Line', 'Play Scrub', 'Hand', 'Drumstick', 'Time Warp'];

// A set with a MIDI clip in the first slot, open in Detail View.
function withClip() {
  const set = liveSet();
  const slot = set.slots[0];
  slot.fns.create_clip(4);
  const c = slot.kids.clip;
  c.props.name = 'Riff'; c.props.muted = 0;
  c.kids.canonical_parent = slot;
  slot.fns.delete_clip = () => { delete slot.kids.clip; slot.props.has_clip = 0; set.open(null); };
  c.fns.duplicate_loop = () => { c.props.loop_end *= 2; };
  c.fns.quantize = (grid, amount) => { c.quantized = [grid, amount]; };
  set.open(c);
  return { set, slot, c };
}
function device(set) { const d = load(BUNDLE, { set: set || liveSet(), width: 520 }); d.send('bang'); return d; }
function status(d) { return d.texts()[0]; }

test('the thirteen tools are there, in the toolbox’s order', () => {
  const t = device().texts();
  let at = -1;
  for (const name of TOOLS) { const i = t.indexOf(name); assert.ok(i > at, name); at = i; }
});

test('Draw turns on Live’s Draw Mode and Object Selection turns it off', () => {
  const set = liveSet();
  const d = device(set);
  d.click('Draw');
  assert.strictEqual(set.view.props.draw_mode, 1);
  d.click('Object Selection');
  assert.strictEqual(set.view.props.draw_mode, 0);
});

test('Mute and Eraser act on the clip open in Detail View', () => {
  const { set, slot, c } = withClip();
  const d = device(set);
  d.click('Mute');
  assert.strictEqual(c.props.muted, 1);
  assert.strictEqual(status(d), 'Mute: “Riff” is muted.');
  d.click('Eraser');
  assert.strictEqual(slot.props.has_clip, 0);
  assert.strictEqual(status(d), 'Eraser: deleted “Riff”.');
});

test('Glue doubles a MIDI clip’s loop, and Drumstick quantizes it', () => {
  const { set, c } = withClip();
  const d = device(set);
  d.click('Glue');
  assert.strictEqual(c.props.loop_end, 8);
  d.click('Drumstick');
  assert.deepStrictEqual(c.quantized, [5, 1]);
});

test('a tool with no clip to act on says what to do', () => {
  const d = device();
  d.click('Mute');
  assert.strictEqual(status(d), 'No clip is open. Open one in Detail View, then try again.');
});

test('what a device cannot do is answered with Live’s own key', () => {
  const d = device();
  d.click('Split');
  assert.ok(/⌘E/.test(status(d)), status(d));
});
