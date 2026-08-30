importScripts("model.js");

const HOST = "io.github.silouanwright.look_elsewhere";
const HEARTBEAT_MS = 5_000;
const PROTOCOL_VERSION = 1;
const sessionId = crypto.randomUUID();

let sequence = 0;
let port;
let reconnectTimer;
let reconnectDelayMs = 1_000;
const frameStates = new Map();

function connect() {
  if (port) return;
  try {
    port = chrome.runtime.connectNative(HOST);
  } catch (error) {
    console.error("LookElsewhere native host connection failed", error);
    scheduleReconnect();
    return;
  }
  port.onDisconnect.addListener(() => {
    const message = chrome.runtime.lastError?.message;
    if (message) console.error("LookElsewhere native host disconnected", message);
    port = undefined;
    scheduleReconnect();
  });
  reconnectDelayMs = 1_000;
  report();
}

function scheduleReconnect() {
  if (reconnectTimer) return;
  reconnectTimer = setTimeout(() => {
    reconnectTimer = undefined;
    connect();
  }, reconnectDelayMs);
  reconnectDelayMs = Math.min(reconnectDelayMs * 2, 30_000);
}

function clearTab(tabId) {
  for (const key of frameStates.keys()) {
    if (key.startsWith(`${tabId}:`)) frameStates.delete(key);
  }
}

function anyPictureInPicture() {
  for (const value of frameStates.values()) {
    if (value.picture_in_picture && value.video_state === "playing") return true;
  }
  return false;
}

async function currentState() {
  const window = await chrome.windows.getLastFocused();
  const browserFocused = window.id !== chrome.windows.WINDOW_ID_NONE && window.focused === true;
  const [tab] = browserFocused
    ? await chrome.tabs.query({ active: true, windowId: window.id }) : [];
  const media = tab?.id === undefined
    ? aggregateFrameStates(frameStates, -1) : aggregateFrameStates(frameStates, tab.id);

  return {
    version: PROTOCOL_VERSION,
    session_id: sessionId,
    sequence: ++sequence,
    browser: "chromium",
    browser_focused: browserFocused,
    video_state: media.video_state,
    video_visible: browserFocused && media.video_visible,
    picture_in_picture: media.picture_in_picture || anyPictureInPicture()
  };
}

async function report() {
  if (!port) return;
  try {
    port.postMessage(await currentState());
  } catch (error) {
    console.error("LookElsewhere could not sample browser video context", error);
  }
}

chrome.runtime.onMessage.addListener((message, sender) => {
  if (message?.type !== "lookelsewhere-media-state" || sender.tab?.id === undefined) return;
  frameStates.set(`${sender.tab.id}:${sender.frameId}`, {
    video_state: message.video_state,
    video_visible: message.video_visible === true,
    picture_in_picture: message.picture_in_picture === true
  });
  report();
});
chrome.tabs.onActivated.addListener(report);
chrome.tabs.onRemoved.addListener(clearTab);
chrome.tabs.onUpdated.addListener((tabId, change) => {
  if (change.status === "loading") clearTab(tabId);
  if (change.status || change.audible !== undefined || change.url) report();
});
chrome.windows.onFocusChanged.addListener(report);
chrome.runtime.onStartup.addListener(connect);
chrome.runtime.onInstalled.addListener(connect);
connect();
setInterval(report, HEARTBEAT_MS);

importScripts("model.js");
