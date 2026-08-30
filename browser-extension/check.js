const assert = require("node:assert/strict");
const { aggregateFrameStates, mediaElementState } = require("./chromium/model.js");

const frameStates = new Map([
  ["7:0", { video_state: "paused", video_visible: true, picture_in_picture: false }],
  ["7:2", { video_state: "playing", video_visible: false, picture_in_picture: true }]
]);
assert.deepEqual(aggregateFrameStates(frameStates, 7), {
  video_state: "playing", video_visible: true, picture_in_picture: true
});
assert.deepEqual(aggregateFrameStates(frameStates, 8), {
  video_state: "none", video_visible: false, picture_in_picture: false
});

const playingMuted = { paused: false, ended: false, readyState: 4, muted: true };
assert.deepEqual(mediaElementState([playingMuted], true, null, () => true), {
  video_state: "playing", video_visible: true, picture_in_picture: false
});
assert.equal(mediaElementState([
  { paused: false, ended: false, readyState: 2 }
], true, null, () => true).video_state, "buffering");
assert.equal(mediaElementState([
  { paused: true, ended: false, readyState: 4 }
], true, null, () => true).video_state, "paused");
assert.equal(mediaElementState([playingMuted], false, playingMuted, () => true).picture_in_picture, true);

console.log("Browser context aggregation passed.");
