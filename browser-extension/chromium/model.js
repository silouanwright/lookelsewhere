function aggregateFrameStates(frameStates, tabId) {
  let videoState = "none";
  let videoVisible = false;
  let pictureInPicture = false;
  for (const [key, value] of frameStates) {
    if (!key.startsWith(`${tabId}:`)) continue;
    pictureInPicture ||= value.picture_in_picture;
    videoVisible ||= value.video_visible;
    if (value.video_state === "playing") videoState = "playing";
    else if (value.video_state === "buffering" && videoState !== "playing") videoState = "buffering";
    else if (value.video_state === "paused" && videoState === "none") videoState = "paused";
  }
  return { video_state: videoState, video_visible: videoVisible, picture_in_picture: pictureInPicture };
}

function mediaElementState(videos, documentVisible, pipElement, visible) {
  let videoState = videos.length ? "paused" : "none";
  let videoVisible = false;
  for (const video of videos) {
    videoVisible ||= documentVisible && visible(video);
    if (video.paused || video.ended) continue;
    if (video.readyState >= 3) {
      videoState = "playing";
      break;
    }
    videoState = "buffering";
  }
  return {
    video_state: videoState,
    video_visible: videoVisible,
    picture_in_picture: videos.includes(pipElement)
  };
}

if (typeof module !== "undefined") module.exports = { aggregateFrameStates, mediaElementState };
