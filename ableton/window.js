// The picture in the README: `node ableton/window.js` redraws ableton/window.png.
// The Draw tool chosen.
require('./kit/test/picture.js')(__dirname, { bundle: 'RightClickToolbox.js', w: 520, h: 169,
  go(d) { d.ctx.TOOLS[7][1](); } });
