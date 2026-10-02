"""Shared, privacy-minimized browser context schema."""

VIDEO_STATES = {"none", "paused", "buffering", "playing"}


def normalize(value):
    if not isinstance(value, dict) or type(value.get("version")) is not int or value["version"] != 1:
        raise ValueError("unsupported browser-context protocol")
    session_id = value.get("session_id")
    sequence = value.get("sequence")
    video_state = value.get("video_state")
    if not isinstance(session_id, str) or not 1 <= len(session_id) <= 64:
        raise ValueError("invalid session id")
    if len(session_id.encode("utf-16-le")) > 128:
        raise ValueError("session id exceeds 64 UTF-16 units")
    if not isinstance(sequence, int) or isinstance(sequence, bool) or not 0 < sequence <= 2**53 - 1:
        raise ValueError("invalid sequence")
    if (value.get("browser") != "chromium" or not isinstance(video_state, str)
            or video_state not in VIDEO_STATES):
        raise ValueError("invalid browser context")
    for key in ("browser_focused", "video_visible", "picture_in_picture"):
        if not isinstance(value.get(key), bool):
            raise ValueError(f"invalid {key}")
    return {
        "version": 1,
        "session_id": session_id,
        "sequence": sequence,
        "browser": "chromium",
        "browser_focused": value["browser_focused"],
        "video_state": video_state,
        "video_visible": value["video_visible"],
        "picture_in_picture": value["picture_in_picture"],
    }
