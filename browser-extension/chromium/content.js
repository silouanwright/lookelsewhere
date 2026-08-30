(() => {
  const MEDIA_EVENTS = [
    "play", "playing", "pause", "waiting", "stalled", "ended", "emptied"
  ];
  let lastSignature = "";

  function visible(video) {
    if (document.visibilityState !== "visible") return false;
    const style = getComputedStyle(video);
    const rect = video.getBoundingClientRect();
    return style.display !== "none" && style.visibility !== "hidden"
      && Number(style.opacity) > 0 && rect.width > 0 && rect.height > 0;
  }

  function state() {
    const videos = Array.from(document.querySelectorAll("video"));
    return Object.assign({
      type: "lookelsewhere-media-state",
    }, mediaElementState(videos, document.visibilityState === "visible",
      document.pictureInPictureElement, visible));
  }

  function report() {
    const next = state();
    const signature = JSON.stringify(next);
    if (signature === lastSignature) return;
    lastSignature = signature;
    chrome.runtime.sendMessage(next).catch(() => {});
  }

  function observeVideo(video) {
    if (video.dataset.lookelsewhereObserved === "1") return;
    video.dataset.lookelsewhereObserved = "1";
    for (const event of MEDIA_EVENTS) video.addEventListener(event, report, { passive: true });
    video.addEventListener("enterpictureinpicture", report, { passive: true });
    video.addEventListener("leavepictureinpicture", report, { passive: true });
  }

  function reconcile() {
    document.querySelectorAll("video").forEach(observeVideo);
    report();
  }

  document.addEventListener("visibilitychange", report, { passive: true });
  new MutationObserver(reconcile).observe(document, { childList: true, subtree: true });
  reconcile();

  if (typeof module !== "undefined") module.exports = { state, visible };
})();
