.pragma library

var State = {
  Disabled: "disabled",
  Paused: "paused",
  Working: "working",
  DueSoon: "due-soon",
  Protected: "protected-context",
  Waiting: "waiting-for-pause",
  Warning: "warning",
  Final: "final-countdown",
  Breaking: "breaking"
}

function clamp(value, low, high) {
  return Math.max(low, Math.min(high, Number(value)))
}

function defaultConfig() {
  return {
    version: 1,
    enabled: true,
    focusMs: 20 * 60 * 1000,
    breakMs: 20 * 1000,
    dueSoonMs: 60 * 1000,
    warningMs: 25 * 1000,
    finalMs: 3 * 1000,
    cooldownMs: 60 * 1000,
    maximumDelayMs: 15 * 60 * 1000,
    enforcement: "balanced",
    snoozeBudget: 3,
    reducedMotion: false,
    soundEnabled: true,
    soundVolume: 65,
    startSoundEnabled: true,
    completionSoundEnabled: true,
    startSoundPath: "",
    completionSoundPath: "",
    outputMode: "all",
    officeHours: { enabled: false, startMinute: 8 * 60, endMinute: 18 * 60 },
    detectors: { idle: true, fullscreen: true, media: true, microphone: true, dictation: true }
  }
}

function normalizeConfig(input) {
  var base = defaultConfig()
  var value = input || {}
  base.enabled = value.enabled === undefined ? base.enabled : value.enabled === true
  base.focusMs = clamp(value.focusMs === undefined ? base.focusMs : value.focusMs, 60 * 1000, 12 * 60 * 60 * 1000)
  base.breakMs = clamp(value.breakMs === undefined ? base.breakMs : value.breakMs, 5 * 1000, 60 * 60 * 1000)
  base.dueSoonMs = clamp(value.dueSoonMs === undefined ? base.dueSoonMs : value.dueSoonMs, 0, base.focusMs)
  base.warningMs = clamp(value.warningMs === undefined ? base.warningMs : value.warningMs, 3 * 1000, 5 * 60 * 1000)
  base.finalMs = clamp(value.finalMs === undefined ? base.finalMs : value.finalMs, 1 * 1000, base.warningMs)
  base.cooldownMs = clamp(value.cooldownMs === undefined ? base.cooldownMs : value.cooldownMs, 0, 60 * 60 * 1000)
  base.maximumDelayMs = clamp(value.maximumDelayMs === undefined ? base.maximumDelayMs : value.maximumDelayMs, 0, 12 * 60 * 60 * 1000)
  base.enforcement = ["gentle", "balanced", "focused"].indexOf(value.enforcement) >= 0 ? value.enforcement : base.enforcement
  base.snoozeBudget = Math.round(clamp(value.snoozeBudget === undefined ? base.snoozeBudget : value.snoozeBudget, 0, 20))
  base.reducedMotion = value.reducedMotion === true
  base.soundEnabled = value.soundEnabled === true
  base.soundVolume = Math.round(clamp(value.soundVolume === undefined ? base.soundVolume : value.soundVolume, 0, 100))
  base.startSoundEnabled = value.startSoundEnabled === undefined ? base.startSoundEnabled : value.startSoundEnabled === true
  base.completionSoundEnabled = value.completionSoundEnabled === undefined ? base.completionSoundEnabled : value.completionSoundEnabled === true
  base.startSoundPath = String(value.startSoundPath || "").trim()
  base.completionSoundPath = String(value.completionSoundPath || "").trim()
  base.outputMode = ["all", "focused"].indexOf(value.outputMode) >= 0 ? value.outputMode : base.outputMode
  if (value.officeHours) {
    base.officeHours.enabled = value.officeHours.enabled === true
    base.officeHours.startMinute = clamp(value.officeHours.startMinute === undefined ? base.officeHours.startMinute : value.officeHours.startMinute, 0, 1439)
    base.officeHours.endMinute = clamp(value.officeHours.endMinute === undefined ? base.officeHours.endMinute : value.officeHours.endMinute, 0, 1439)
  }
  if (value.detectors) {
    for (var key in base.detectors)
      if (value.detectors[key] !== undefined) base.detectors[key] = value.detectors[key] === true
  }
  return base
}

function parseClockMinute(value, fallback) {
  var match = /^(\d{1,2}):(\d{2})$/.exec(String(value || "").trim())
  if (!match) return fallback
  var hour = Number(match[1])
  var minute = Number(match[2])
  return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 ? hour * 60 + minute : fallback
}

function finiteNumber(value, fallback) {
  var number = Number(value)
  return isFinite(number) ? number : fallback
}

// Omarchy injects only the values present on the widget's shell.json entry;
// it does not merge manifest defaults. Rebuild from defaults every time so
// deleting an override reliably restores the documented default.
function configFromSettings(settings) {
  var incoming = settings || {}
  var next = defaultConfig()
  if (incoming.focusMinutes !== undefined) next.focusMs = finiteNumber(incoming.focusMinutes, next.focusMs / 60000) * 60000
  if (incoming.breakSeconds !== undefined) next.breakMs = finiteNumber(incoming.breakSeconds, next.breakMs / 1000) * 1000
  if (incoming.enforcement !== undefined) next.enforcement = String(incoming.enforcement)
  if (incoming.maximumDelayMinutes !== undefined) next.maximumDelayMs = finiteNumber(incoming.maximumDelayMinutes, next.maximumDelayMs / 60000) * 60000
  if (incoming.snoozeBudget !== undefined) next.snoozeBudget = finiteNumber(incoming.snoozeBudget, next.snoozeBudget)
  if (incoming.reducedMotion !== undefined) next.reducedMotion = incoming.reducedMotion === true
  if (incoming.soundEnabled !== undefined) next.soundEnabled = incoming.soundEnabled === true
  if (incoming.soundVolume !== undefined) next.soundVolume = finiteNumber(incoming.soundVolume, next.soundVolume)
  if (incoming.startSoundEnabled !== undefined) next.startSoundEnabled = incoming.startSoundEnabled === true
  if (incoming.completionSoundEnabled !== undefined) next.completionSoundEnabled = incoming.completionSoundEnabled === true
  if (incoming.startSoundPath !== undefined) next.startSoundPath = String(incoming.startSoundPath)
  if (incoming.completionSoundPath !== undefined) next.completionSoundPath = String(incoming.completionSoundPath)
  if (incoming.outputMode !== undefined) next.outputMode = String(incoming.outputMode)
  if (incoming.officeHoursEnabled !== undefined) next.officeHours.enabled = incoming.officeHoursEnabled === true
  if (incoming.officeStart !== undefined) next.officeHours.startMinute = parseClockMinute(incoming.officeStart, next.officeHours.startMinute)
  if (incoming.officeEnd !== undefined) next.officeHours.endMinute = parseClockMinute(incoming.officeEnd, next.officeHours.endMinute)
  var detectorKeys = ["idle", "fullscreen", "media", "microphone", "dictation"]
  for (var i = 0; i < detectorKeys.length; i++) {
    var detector = detectorKeys[i]
    var settingKey = detector + "Detection"
    if (incoming[settingKey] !== undefined) next.detectors[detector] = incoming[settingKey] === true
  }
  return normalizeConfig(next)
}

function defaultSnapshot(nowMs) {
  return {
    version: 1,
    state: State.Working,
    accumulatedActiveMs: 0,
    stateEnteredAtMs: Number(nowMs || 0),
    lastObservedAtMs: Number(nowMs || 0),
    dueAtMs: 0,
    postponedUntilMs: 0,
    cooldownUntilMs: 0,
    warningEndsAtMs: 0,
    breakEndsAtMs: 0,
    protectedCategory: "",
    pauseReason: "",
    snoozesUsed: 0,
    totals: { prompted: 0, completed: 0, postponed: 0, skipped: 0, delayed: 0 }
  }
}

function minuteOfDay(date) {
  return date.getHours() * 60 + date.getMinutes()
}

function inOfficeHours(date, officeHours) {
  if (!officeHours || officeHours.enabled !== true) return true
  var now = minuteOfDay(date)
  var start = Number(officeHours.startMinute)
  var end = Number(officeHours.endMinute)
  if (start === end) return true
  if (start < end) return now >= start && now < end
  return now >= start || now < end
}

function strongestEvidence(evidence, config) {
  var enabled = config && config.detectors ? config.detectors : defaultConfig().detectors
  var priority = ["dictation", "meeting", "microphone", "media", "fullscreen"]
  var best = null
  for (var i = 0; i < (evidence || []).length; i++) {
    var item = evidence[i] || {}
    var category = String(item.category || "")
    var detectorKey = category === "meeting" ? "microphone" : category
    if (enabled[detectorKey] !== true || item.active !== true) continue
    var confidence = clamp(item.confidence === undefined ? 0 : item.confidence, 0, 1)
    if (confidence < 0.6) continue
    if (!best || confidence > best.confidence || (confidence === best.confidence && priority.indexOf(category) < priority.indexOf(best.category)))
      best = { category: category, confidence: confidence }
  }
  return best
}

function copySnapshot(snapshot) {
  var value = snapshot || defaultSnapshot(0)
  var totals = value.totals || {}
  return {
    version: Number(value.version || 1),
    state: String(value.state || State.Working),
    accumulatedActiveMs: Number(value.accumulatedActiveMs || 0),
    stateEnteredAtMs: Number(value.stateEnteredAtMs || 0),
    lastObservedAtMs: Number(value.lastObservedAtMs || 0),
    dueAtMs: Number(value.dueAtMs || 0),
    postponedUntilMs: Number(value.postponedUntilMs || 0),
    cooldownUntilMs: Number(value.cooldownUntilMs || 0),
    warningEndsAtMs: Number(value.warningEndsAtMs || 0),
    breakEndsAtMs: Number(value.breakEndsAtMs || 0),
    protectedCategory: String(value.protectedCategory || ""),
    pauseReason: String(value.pauseReason || ""),
    snoozesUsed: Number(value.snoozesUsed || 0),
    totals: {
      prompted: Number(totals.prompted || 0),
      completed: Number(totals.completed || 0),
      postponed: Number(totals.postponed || 0),
      skipped: Number(totals.skipped || 0),
      delayed: Number(totals.delayed || 0)
    }
  }
}

function observe(snapshot, input, config) {
  var cfg = config && config.version === 1 ? config : normalizeConfig(config)
  var next = copySnapshot(snapshot || defaultSnapshot(input.nowMs))
  var now = Number(input.nowMs)
  var previous = Number(next.lastObservedAtMs || now)
  var elapsed = clamp(now - previous, 0, 5 * 60 * 1000)
  next.lastObservedAtMs = now

  if (!cfg.enabled) {
    next.state = State.Disabled
    return next
  }
  if (!inOfficeHours(new Date(now), cfg.officeHours)) {
    next.state = State.Paused
    next.pauseReason = "outside-office-hours"
    return next
  }
  if (next.state === State.Disabled || (next.state === State.Paused && next.pauseReason === "outside-office-hours")) {
    next.state = State.Working
    next.pauseReason = ""
    next.stateEnteredAtMs = now
    // The interval since the last paused observation belongs to the closed
    // schedule. Begin active accounting at the reopening observation rather
    // than crediting paused time after a delayed tick, suspend, or restart.
    elapsed = 0
  }

  if (next.state === State.Breaking) {
    if (now >= next.breakEndsAtMs) return completeBreak(next, now)
    return next
  }
  if (next.state === State.Final) {
    if (now >= next.warningEndsAtMs) return startBreak(next, now, cfg)
    return next
  }
  if (next.state === State.Warning) {
    if (now >= next.warningEndsAtMs - cfg.finalMs) next.state = State.Final
    return next
  }
  if (next.state === State.Waiting && next.pauseReason === "manual") return next
  if (next.postponedUntilMs > now) {
    next.state = State.Waiting
    return next
  }

  if (input.active === true && input.idle !== true) next.accumulatedActiveMs += elapsed
  var remaining = Math.max(0, cfg.focusMs - next.accumulatedActiveMs)
  // The pre-break warning is part of the focus interval, not an additional
  // countdown after it. Enter it as soon as the configured warning window is
  // reached and end it at the original due moment.
  if (remaining > 0 && remaining <= cfg.warningMs) {
    return startWarning(next, now, cfg, remaining)
  }
  if (remaining > cfg.dueSoonMs) {
    next.state = State.Working
    return next
  }
  if (remaining > 0) {
    next.state = State.DueSoon
    return next
  }

  if (!next.dueAtMs) next.dueAtMs = now
  var protection = strongestEvidence(input.evidence || [], cfg)
  if (protection && now - next.dueAtMs < cfg.maximumDelayMs) {
    if (next.state !== State.Protected) next.totals.delayed++
    next.state = State.Protected
    next.protectedCategory = protection.category
    return next
  }
  if (next.state === State.Protected) {
    next.cooldownUntilMs = now + cfg.cooldownMs
    next.protectedCategory = ""
  }
  if (now < next.cooldownUntilMs && now - next.dueAtMs < cfg.maximumDelayMs) {
    next.state = State.Waiting
    return next
  }
  // A due break should arrive at a transition in the user's activity, not in
  // the middle of a burst of typing or pointer work. The service supplies a
  // short Wayland idle signal here; maximumDelayMs remains the hard bound so
  // continuous interaction can never suppress a break indefinitely.
  if (input.naturalPause === false && now - next.dueAtMs < cfg.maximumDelayMs) {
    next.state = State.Waiting
    return next
  }
  return startWarning(next, now, cfg)
}

function startWarning(snapshot, nowMs, config, durationMs) {
  var next = copySnapshot(snapshot)
  next.state = State.Warning
  next.stateEnteredAtMs = nowMs
  next.warningEndsAtMs = nowMs + Math.max(0, Number(durationMs === undefined ? config.warningMs : durationMs))
  next.totals.prompted++
  return next
}

function startBreak(snapshot, nowMs, config) {
  var next = copySnapshot(snapshot)
  next.state = State.Breaking
  next.stateEnteredAtMs = nowMs
  next.breakEndsAtMs = nowMs + config.breakMs
  return next
}

function completeBreak(snapshot, nowMs) {
  var next = copySnapshot(snapshot)
  next.state = State.Working
  next.stateEnteredAtMs = nowMs
  next.accumulatedActiveMs = 0
  next.dueAtMs = 0
  next.postponedUntilMs = 0
  next.cooldownUntilMs = 0
  next.warningEndsAtMs = 0
  next.breakEndsAtMs = 0
  next.protectedCategory = ""
  next.snoozesUsed = 0
  next.totals.completed++
  return next
}

function postpone(snapshot, nowMs, durationMs, config) {
  if (!canPostpone(snapshot, config)) return copySnapshot(snapshot)
  var next = copySnapshot(snapshot)
  next.state = State.Waiting
  next.stateEnteredAtMs = nowMs
  next.postponedUntilMs = nowMs + Math.max(0, Number(durationMs || 0))
  next.warningEndsAtMs = 0
  next.snoozesUsed++
  next.totals.postponed++
  return next
}

function delayNextBreak(snapshot, nowMs, durationMs, config) {
  if (!canPostpone(snapshot, config)) return copySnapshot(snapshot)
  var state = snapshot && snapshot.state
  if (state !== State.Working && state !== State.DueSoon)
    return postpone(snapshot, nowMs, durationMs, config)

  var next = copySnapshot(snapshot)
  next.state = State.Working
  next.stateEnteredAtMs = nowMs
  next.lastObservedAtMs = nowMs
  next.accumulatedActiveMs = Math.max(0,
    next.accumulatedActiveMs - Math.max(0, Number(durationMs || 0)))
  next.dueAtMs = 0
  next.postponedUntilMs = 0
  next.warningEndsAtMs = 0
  next.snoozesUsed++
  next.totals.postponed++
  return next
}

function canPostpone(snapshot, config) {
  var cfg = config && config.version === 1 ? config : normalizeConfig(config)
  if (cfg.enforcement === "focused") return false
  return Number(snapshot && snapshot.snoozesUsed || 0) < cfg.snoozeBudget
}

function canSkipBreak(config) {
  var cfg = config && config.version === 1 ? config : normalizeConfig(config)
  return cfg.enforcement !== "focused"
}

function soundCueForTransition(beforeState, afterState) {
  if (beforeState !== State.Breaking && afterState === State.Breaking) return "start"
  if (beforeState === State.Breaking && afterState === State.Working) return "complete"
  return ""
}

function shouldLeadCompletionCue(state, remainingMs, leadMs) {
  var remaining = Number(remainingMs || 0)
  return state === State.Breaking && remaining > 0 && remaining <= Number(leadMs || 0)
}

function resetTotals(snapshot) {
  var next = copySnapshot(snapshot)
  next.totals = { prompted: 0, completed: 0, postponed: 0, skipped: 0, delayed: 0 }
  return next
}

function formatBarDuration(milliseconds) {
  var remaining = Math.max(0, Number(milliseconds || 0))
  var seconds = Math.ceil(remaining / 1000)
  if (remaining < 60000) return seconds + "s"
  return Math.floor(remaining / 60000) + "m"
}

function formatDuration(milliseconds) {
  var totalSeconds = Math.max(0, Math.ceil(Number(milliseconds || 0) / 1000))
  if (totalSeconds < 60) return totalSeconds + "s"
  var minutes = Math.floor(totalSeconds / 60)
  var seconds = totalSeconds % 60
  if (minutes < 60) return seconds ? minutes + "m " + seconds + "s" : minutes + "m"
  var hours = Math.floor(minutes / 60)
  minutes %= 60
  return minutes ? hours + "h " + minutes + "m" : hours + "h"
}

function stateLabel(snapshot) {
  var state = snapshot ? snapshot.state : ""
  if (state === State.Protected) return "Waiting until " + (snapshot.protectedCategory || "protected work") + " ends"
  if (state === State.Waiting && snapshot.pauseReason === "manual") return "Breaks paused"
  if (state === State.Waiting) return "Waiting for a natural pause"
  if (state === State.Warning) return "Break starting soon"
  if (state === State.Final) return "Starting break"
  if (state === State.Breaking) return "Look elsewhere"
  if (state === State.Paused) return "Breaks paused"
  if (state === State.Disabled) return "Look Elsewhere is off"
  if (state === State.DueSoon) return "Break due soon"
  return "Break starts in"
}

function protectedExplanation(category) {
  var labels = {
    meeting: "your meeting is active",
    microphone: "your microphone is active",
    media: "media is playing",
    fullscreen: "fullscreen work is active",
    dictation: "dictation is active"
  }
  return "Held quietly while " + (labels[String(category || "")] || "protected work is active") + "."
}
