.pragma library

var State = {
  Disabled: "disabled",
  Paused: "paused",
  Working: "working",
  DueSoon: "due-soon",
  Protected: "protected-context",
  Waiting: "waiting-for-pause",
  PlannedReady: "planned-ready",
  Warning: "warning",
  Final: "final-countdown",
  Breaking: "breaking"
}

var ValidStates = Object.keys(State).map(function(key) { return State[key] })
var MaximumPersistedFutureMs = 24 * 60 * 60 * 1000
var NaturalBreakReviewMs = 5 * 60 * 1000
var SessionResetInactivityMs = 60 * 60 * 1000
var NaturalBreakUndoMs = 60 * 1000
var MaximumStatisticMs = 48 * 60 * 60 * 1000
var MaximumStatisticCount = 10000
var MaximumStatisticDays = 7
var MaximumSessionsPerDay = 12
var MaximumPlannedBreaks = 8
var MaximumPlannedNameLength = 40
var MinimumPlannedDurationMs = 60 * 1000
var MaximumPlannedDurationMs = 2 * 60 * 60 * 1000
var PlannedCoalescingMs = 10 * 60 * 1000
var PlannedMinimumLateWindowMs = 30 * 60 * 1000
var PlannedMaximumLateWindowMs = 2 * 60 * 60 * 1000
var MaximumHandledPlannedOccurrences = 32

function clamp(value, low, high) {
  return Math.max(low, Math.min(high, Number(value)))
}

function defaultConfig() {
  return {
    version: 1,
    enabled: true,
    focusMs: 20 * 60 * 1000,
    breakMs: 20 * 1000,
    longBreakEvery: 4,
    longBreakMs: 3 * 60 * 1000,
    dueSoonMs: 60 * 1000,
    warningMs: 60 * 1000,
    finalMs: 3 * 1000,
    cooldownMs: 60 * 1000,
    maximumDelayMs: 15 * 60 * 1000,
    enforcement: "balanced",
    snoozeBudget: 3,
    breakTitle: "Look elsewhere",
    breakSubtitle: "Let your eyes settle on something distant. Breathe. The screen will still be here.",
    longBreakTitle: "Look elsewhere",
    longBreakSubtitle: "Stand up, stretch, and leave the screen for a few minutes.",
    reducedMotion: false,
    reducedTransparency: false,
    soundEnabled: true,
    soundVolume: 65,
    startSoundEnabled: true,
    completionSoundEnabled: true,
    startSoundPath: "",
    completionSoundPath: "",
    outputMode: "all",
    panelPattern: "off",
    pauseDuringSteamGames: true,
    protectedApps: ["steam"],
    plannedBreaks: [],
    officeHours: { enabled: false, startMinute: 8 * 60, endMinute: 18 * 60 },
    detectors: { idle: true, recentInput: true, fullscreen: true, media: true, microphone: true, screenSharing: true, dictation: true, applications: true }
  }
}

function normalizeConfig(input) {
  var base = defaultConfig()
  var value = input || {}
  base.enabled = value.enabled === undefined ? base.enabled : value.enabled === true
  base.focusMs = clamp(value.focusMs === undefined ? base.focusMs : value.focusMs, 60 * 1000, 12 * 60 * 60 * 1000)
  base.breakMs = clamp(value.breakMs === undefined ? base.breakMs : value.breakMs, 5 * 1000, 60 * 60 * 1000)
  base.longBreakEvery = Math.round(clamp(value.longBreakEvery === undefined ? base.longBreakEvery : value.longBreakEvery, 0, 20))
  base.longBreakMs = clamp(value.longBreakMs === undefined ? base.longBreakMs : value.longBreakMs, 5 * 1000, 60 * 60 * 1000)
  base.dueSoonMs = clamp(value.dueSoonMs === undefined ? base.dueSoonMs : value.dueSoonMs, 0, base.focusMs)
  base.warningMs = clamp(value.warningMs === undefined ? base.warningMs : value.warningMs, 3 * 1000, 5 * 60 * 1000)
  base.finalMs = clamp(value.finalMs === undefined ? base.finalMs : value.finalMs, 1 * 1000, base.warningMs)
  base.cooldownMs = clamp(value.cooldownMs === undefined ? base.cooldownMs : value.cooldownMs, 0, 60 * 60 * 1000)
  base.maximumDelayMs = clamp(value.maximumDelayMs === undefined ? base.maximumDelayMs : value.maximumDelayMs, 0, 12 * 60 * 60 * 1000)
  var enforcement = String(value.enforcement || "")
  if (enforcement === "gentle") enforcement = "casual"
  else if (enforcement === "focused") enforcement = "hardcore"
  base.enforcement = ["casual", "balanced", "hardcore"].indexOf(enforcement) >= 0 ? enforcement : base.enforcement
  base.snoozeBudget = Math.round(clamp(value.snoozeBudget === undefined ? base.snoozeBudget : value.snoozeBudget, 0, 20))
  base.breakTitle = String(value.breakTitle === undefined ? base.breakTitle : value.breakTitle).trim()
  base.breakSubtitle = String(value.breakSubtitle === undefined ? base.breakSubtitle : value.breakSubtitle).trim()
  base.longBreakTitle = String(value.longBreakTitle === undefined ? base.longBreakTitle : value.longBreakTitle).trim()
  base.longBreakSubtitle = String(value.longBreakSubtitle === undefined ? base.longBreakSubtitle : value.longBreakSubtitle).trim()
  base.reducedMotion = value.reducedMotion === true
  base.reducedTransparency = value.reducedTransparency === true
  base.soundEnabled = value.soundEnabled === true
  base.soundVolume = Math.round(clamp(value.soundVolume === undefined ? base.soundVolume : value.soundVolume, 0, 100))
  base.startSoundEnabled = value.startSoundEnabled === undefined ? base.startSoundEnabled : value.startSoundEnabled === true
  base.completionSoundEnabled = value.completionSoundEnabled === undefined ? base.completionSoundEnabled : value.completionSoundEnabled === true
  base.startSoundPath = String(value.startSoundPath || "").trim()
  base.completionSoundPath = String(value.completionSoundPath || "").trim()
  base.outputMode = ["all", "focused"].indexOf(value.outputMode) >= 0 ? value.outputMode : base.outputMode
  base.panelPattern = ["off", "topography", "graph-paper", "wiggle", "bank-note", "diagonal-lines"].indexOf(value.panelPattern) >= 0
    ? value.panelPattern : base.panelPattern
  base.pauseDuringSteamGames = value.pauseDuringSteamGames === undefined
    ? base.pauseDuringSteamGames : value.pauseDuringSteamGames === true
  var protectedApps = value.protectedApps === undefined ? base.protectedApps : value.protectedApps
  if (!Array.isArray(protectedApps)) protectedApps = String(protectedApps || "").split(",")
  base.protectedApps = protectedApps.map(function(app) {
    return String(app || "").trim().toLowerCase().replace(/\.desktop$/, "")
  }).filter(function(app) { return app !== "" })
  base.plannedBreaks = normalizePlannedBreaks(value.plannedBreaks)
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

function normalizePlannedDays(value) {
  var days = Array.isArray(value) ? value : []
  var result = []
  for (var i = 0; i < days.length; i++) {
    var day = Math.round(Number(days[i]))
    if (day >= 0 && day <= 6 && result.indexOf(day) < 0) result.push(day)
  }
  result.sort(function(left, right) { return left - right })
  return result.length ? result : [1, 2, 3, 4, 5]
}

function normalizePlannedId(value, index, usedIds) {
  var id = String(value || "").trim().toLowerCase()
    .replace(/[^a-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 64)
  if (!id) id = "planned-" + (index + 1)
  var base = id
  var suffix = 2
  while (usedIds[id]) id = (base.slice(0, 60) + "-" + suffix++).slice(0, 64)
  usedIds[id] = true
  return id
}

function plannedBreaksOverlap(left, right) {
  if (!left || !right || left.enabled !== true || right.enabled !== true) return false
  var weekMinutes = 7 * 24 * 60
  var leftDuration = left.durationMs / 60000
  var rightDuration = right.durationMs / 60000
  for (var i = 0; i < left.days.length; i++) {
    var leftStart = left.days[i] * 1440 + left.startMinute
    var leftEnd = leftStart + leftDuration
    for (var j = 0; j < right.days.length; j++) {
      var rightStart = right.days[j] * 1440 + right.startMinute
      for (var shift = -weekMinutes; shift <= weekMinutes; shift += weekMinutes) {
        var shiftedStart = rightStart + shift
        if (leftStart < shiftedStart + rightDuration && shiftedStart < leftEnd) return true
      }
    }
  }
  return false
}

function normalizePlannedBreaks(value) {
  var source = value
  if (!Array.isArray(source)) {
    try { source = JSON.parse(String(value || "[]")) }
    catch (error) { source = [] }
  }
  if (!Array.isArray(source)) source = []
  var result = []
  var usedIds = {}
  for (var i = 0; i < source.length && result.length < MaximumPlannedBreaks; i++) {
    var item = source[i] || {}
    var name = String(item.name || "Planned break").trim().slice(0, MaximumPlannedNameLength)
    if (!name) name = "Planned break"
    var routine = {
      id: normalizePlannedId(item.id, i, usedIds),
      name: name,
      startMinute: Math.round(clamp(item.startMinute === undefined ? 12 * 60 : item.startMinute, 0, 1439)),
      durationMs: Math.round(clamp(item.durationMs === undefined ? 15 * 60 * 1000 : item.durationMs,
        MinimumPlannedDurationMs, MaximumPlannedDurationMs)),
      days: normalizePlannedDays(item.days),
      enabled: item.enabled !== false
    }
    for (var existing = 0; existing < result.length; existing++)
      if (plannedBreaksOverlap(result[existing], routine)) routine.enabled = false
    result.push(routine)
  }
  return result
}

function plannedOccurrenceForDay(routine, dayMs) {
  var date = new Date(Number(dayMs))
  date.setHours(0, 0, 0, 0)
  if (!routine || routine.enabled !== true || routine.days.indexOf(date.getDay()) < 0) return null
  var scheduledAtMs = date.getTime() + routine.startMinute * 60000
  var lateWindowMs = Math.min(PlannedMaximumLateWindowMs,
    Math.max(PlannedMinimumLateWindowMs, routine.durationMs * 2))
  return {
    key: routine.id + "@" + localDayKey(scheduledAtMs),
    routineId: routine.id,
    name: routine.name,
    scheduledAtMs: scheduledAtMs,
    durationMs: routine.durationMs,
    expiresAtMs: scheduledAtMs + lateWindowMs
  }
}

function copyPlannedOccurrence(value) {
  if (!value) return null
  var key = String(value.key || "").slice(0, 80)
  var routineId = String(value.routineId || "").slice(0, 64)
  if (!routineId || !key) return null
  function bounded(value, maximum) {
    var number = Number(value)
    return isFinite(number) ? Math.max(0, Math.min(maximum, number)) : 0
  }
  return {
    key: key,
    routineId: routineId,
    name: String(value.name || "Planned break").slice(0, MaximumPlannedNameLength),
    scheduledAtMs: bounded(value.scheduledAtMs, Number.MAX_SAFE_INTEGER),
    durationMs: bounded(value.durationMs, MaximumPlannedDurationMs),
    expiresAtMs: bounded(value.expiresAtMs, Number.MAX_SAFE_INTEGER),
    creditedAwayMs: bounded(value.creditedAwayMs, MaximumPlannedDurationMs),
    idleStartedAtMs: bounded(value.idleStartedAtMs, Number.MAX_SAFE_INTEGER),
    intervalDueAtMs: bounded(value.intervalDueAtMs, Number.MAX_SAFE_INTEGER),
    deferred: value.deferred === true,
    snoozesUsed: bounded(value.snoozesUsed, 20)
  }
}

function beginPlannedOccurrence(snapshot, occurrence, nowMs, config) {
  var next = copySnapshot(snapshot)
  var cfg = config && config.version === 1 ? config : normalizeConfig(config)
  var planned = copyPlannedOccurrence(occurrence)
  if (!planned) return next
  planned.creditedAwayMs = 0
  planned.idleStartedAtMs = 0
  planned.snoozesUsed = 0
  planned.intervalDueAtMs = next.dueAtMs > 0 ? next.dueAtMs
    : Number(nowMs) + Math.max(0, cfg.focusMs - Number(next.accumulatedActiveMs || 0))
  planned.deferred = Number(nowMs) > planned.scheduledAtMs
  next.activePlannedOccurrence = planned
  if (!(next.state === State.Waiting && next.pauseReason === "manual")) {
    next.state = State.Working
    next.stateEnteredAtMs = Number(nowMs)
    next.postponedUntilMs = 0
    next.cooldownUntilMs = 0
    next.warningEndsAtMs = 0
    next.protectedCategory = ""
    next.pauseReason = ""
  }
  return next
}

function reconcilePlannedAway(snapshot, nowMs, idle) {
  var next = copySnapshot(snapshot)
  var planned = next.activePlannedOccurrence
  if (!planned || Number(nowMs) < planned.scheduledAtMs) return next
  if (idle === true) {
    if (!planned.idleStartedAtMs)
      planned.idleStartedAtMs = Math.max(planned.scheduledAtMs, Number(next.lastActiveAtMs || planned.scheduledAtMs))
  } else if (planned.idleStartedAtMs) {
    planned.creditedAwayMs = Math.min(planned.durationMs,
      planned.creditedAwayMs + Math.max(0, Number(nowMs) - planned.idleStartedAtMs))
    planned.idleStartedAtMs = 0
  }
  next.activePlannedOccurrence = planned
  return next
}

function plannedAwayCredit(snapshot, nowMs) {
  var planned = snapshot && snapshot.activePlannedOccurrence
  if (!planned) return 0
  var liveCredit = planned.idleStartedAtMs
    ? Math.max(0, Number(nowMs) - planned.idleStartedAtMs) : 0
  return Math.min(planned.durationMs, planned.creditedAwayMs + liveCredit)
}

function rememberPlannedOccurrence(snapshot, occurrenceKey) {
  var next = copySnapshot(snapshot)
  var key = String(occurrenceKey || "")
  if (key && next.handledPlannedOccurrences.indexOf(key) < 0)
    next.handledPlannedOccurrences.unshift(key)
  next.handledPlannedOccurrences = next.handledPlannedOccurrences.slice(0, MaximumHandledPlannedOccurrences)
  return next
}

function clearPlannedPresentation(snapshot, nowMs) {
  var next = copySnapshot(snapshot)
  next.activePlannedOccurrence = null
  next.activeBreakIsPlanned = false
  next.state = State.Working
  next.stateEnteredAtMs = Number(nowMs)
  next.dueAtMs = 0
  next.postponedUntilMs = 0
  next.cooldownUntilMs = 0
  next.warningEndsAtMs = 0
  next.breakEndsAtMs = 0
  next.activeBreakDurationMs = 0
  next.activeBreakIsLong = false
  next.protectedCategory = ""
  next.pauseReason = ""
  return next
}

function coalesceIntervalForPlanned(snapshot, occurrence, nowMs, config) {
  var next = snapshot
  var remaining = Math.max(0, config.focusMs - Number(next.accumulatedActiveMs || 0))
  var intervalDueAtMs = occurrence.intervalDueAtMs > 0
    ? occurrence.intervalDueAtMs : Number(nowMs) + remaining
  if (Math.abs(intervalDueAtMs - occurrence.scheduledAtMs) <= PlannedCoalescingMs) {
    next.accumulatedActiveMs = 0
    next.dueAtMs = 0
    next.postponedUntilMs = 0
    next.cooldownUntilMs = 0
    next.warningEndsAtMs = 0
  }
  return next
}

function finishPlannedOccurrence(snapshot, nowMs, config, outcome) {
  var next = copySnapshot(snapshot)
  var planned = next.activePlannedOccurrence
  if (!planned) return next
  if (outcome === "completed") {
    next = closeStatisticsSession(next, nowMs, "planned-break")
    next.statistics.today.completed++
    next.statistics.today.plannedBreaks++
    next.totals.completed++
  } else if (outcome === "skipped") {
    next.statistics.today.skipped++
    next.statistics.today.plannedSkipped++
    next.totals.skipped++
  } else {
    next.statistics.today.plannedIgnored++
  }
  next = rememberPlannedOccurrence(next, planned.key)
  next = coalesceIntervalForPlanned(next, planned, nowMs, config)
  return clearPlannedPresentation(next, nowMs)
}

function startPlannedBreak(snapshot, nowMs, config) {
  var next = copySnapshot(snapshot)
  var planned = next.activePlannedOccurrence
  if (!planned) return startBreak(next, nowMs, config)
  var duration = Math.max(0, planned.durationMs - plannedAwayCredit(next, nowMs))
  if (duration <= 0) return finishPlannedOccurrence(next, nowMs, config, "completed")
  next.state = State.Breaking
  next.stateEnteredAtMs = Number(nowMs)
  next.activeBreakDurationMs = duration
  next.activeBreakIsLong = false
  next.activeBreakIsPlanned = true
  next.breakEndsAtMs = Number(nowMs) + duration
  next.postponedUntilMs = 0
  next.warningEndsAtMs = 0
  return next
}

function postponePlanned(snapshot, nowMs, durationMs, config) {
  var next = copySnapshot(snapshot)
  var planned = next.activePlannedOccurrence
  if (!planned || planned.snoozesUsed >= config.snoozeBudget) return next
  planned.snoozesUsed++
  planned.deferred = true
  next.activePlannedOccurrence = planned
  next.state = State.Waiting
  next.stateEnteredAtMs = Number(nowMs)
  next.postponedUntilMs = Number(nowMs) + Math.max(0, Number(durationMs || 0))
  next.warningEndsAtMs = 0
  next.statistics.today.snoozed++
  next.totals.postponed++
  return next
}

function skipPlannedOccurrence(snapshot, nowMs, config) {
  return finishPlannedOccurrence(snapshot, nowMs, config, "skipped")
}

function plannedOccurrencesNear(config, nowMs) {
  var cfg = config && config.version === 1 ? config : normalizeConfig(config)
  var now = new Date(Number(nowMs))
  now.setHours(0, 0, 0, 0)
  var offsets = [-1, 0, 1]
  var result = []
  for (var i = 0; i < cfg.plannedBreaks.length; i++) {
    for (var j = 0; j < offsets.length; j++) {
      var day = new Date(now.getTime())
      day.setDate(day.getDate() + offsets[j])
      var occurrence = plannedOccurrenceForDay(cfg.plannedBreaks[i], day.getTime())
      if (occurrence) result.push(occurrence)
    }
  }
  result.sort(function(left, right) { return left.scheduledAtMs - right.scheduledAtMs })
  return result
}

function nextActionablePlannedOccurrence(config, nowMs, handledKeys) {
  var cfg = config && config.version === 1 ? config : normalizeConfig(config)
  var handled = Array.isArray(handledKeys) ? handledKeys : []
  var occurrences = plannedOccurrencesNear(cfg, nowMs)
  for (var i = 0; i < occurrences.length; i++) {
    var occurrence = occurrences[i]
    if (handled.indexOf(occurrence.key) >= 0) continue
    if (nowMs < occurrence.scheduledAtMs - cfg.warningMs) continue
    if (nowMs <= occurrence.expiresAtMs) return occurrence
  }
  return null
}

// Omarchy injects only the values present on the widget's shell.json entry;
// it does not merge manifest defaults. Rebuild from defaults every time so
// deleting an override reliably restores the documented default.
function configFromSettings(settings) {
  var incoming = settings || {}
  var next = defaultConfig()
  if (incoming.focusMinutes !== undefined) next.focusMs = finiteNumber(incoming.focusMinutes, next.focusMs / 60000) * 60000
  if (incoming.breakSeconds !== undefined) next.breakMs = finiteNumber(incoming.breakSeconds, next.breakMs / 1000) * 1000
  if (incoming.longBreakEvery !== undefined) next.longBreakEvery = finiteNumber(incoming.longBreakEvery, next.longBreakEvery)
  if (incoming.longBreakSeconds !== undefined) next.longBreakMs = finiteNumber(incoming.longBreakSeconds, next.longBreakMs / 1000) * 1000
  if (incoming.enforcement !== undefined) next.enforcement = String(incoming.enforcement)
  if (incoming.maximumDelayMinutes !== undefined) next.maximumDelayMs = finiteNumber(incoming.maximumDelayMinutes, next.maximumDelayMs / 60000) * 60000
  if (incoming.snoozeBudget !== undefined) next.snoozeBudget = finiteNumber(incoming.snoozeBudget, next.snoozeBudget)
  if (incoming.breakTitle !== undefined) next.breakTitle = String(incoming.breakTitle)
  if (incoming.breakSubtitle !== undefined) next.breakSubtitle = String(incoming.breakSubtitle)
  if (incoming.longBreakTitle !== undefined) next.longBreakTitle = String(incoming.longBreakTitle)
  if (incoming.longBreakSubtitle !== undefined) next.longBreakSubtitle = String(incoming.longBreakSubtitle)
  if (incoming.reducedMotion !== undefined) next.reducedMotion = incoming.reducedMotion === true
  if (incoming.reducedTransparency !== undefined) next.reducedTransparency = incoming.reducedTransparency === true
  if (incoming.soundEnabled !== undefined) next.soundEnabled = incoming.soundEnabled === true
  if (incoming.soundVolume !== undefined) next.soundVolume = finiteNumber(incoming.soundVolume, next.soundVolume)
  if (incoming.startSoundEnabled !== undefined) next.startSoundEnabled = incoming.startSoundEnabled === true
  if (incoming.completionSoundEnabled !== undefined) next.completionSoundEnabled = incoming.completionSoundEnabled === true
  if (incoming.startSoundPath !== undefined) next.startSoundPath = String(incoming.startSoundPath)
  if (incoming.completionSoundPath !== undefined) next.completionSoundPath = String(incoming.completionSoundPath)
  if (incoming.outputMode !== undefined) next.outputMode = String(incoming.outputMode)
  if (incoming.panelPattern !== undefined) next.panelPattern = String(incoming.panelPattern)
  if (incoming.pauseDuringSteamGames !== undefined) next.pauseDuringSteamGames = incoming.pauseDuringSteamGames === true
  if (incoming.protectedApps !== undefined) next.protectedApps = String(incoming.protectedApps)
  if (incoming.plannedBreaks !== undefined) next.plannedBreaks = incoming.plannedBreaks
  if (incoming.officeHoursEnabled !== undefined) next.officeHours.enabled = incoming.officeHoursEnabled === true
  if (incoming.officeStart !== undefined) next.officeHours.startMinute = parseClockMinute(incoming.officeStart, next.officeHours.startMinute)
  if (incoming.officeEnd !== undefined) next.officeHours.endMinute = parseClockMinute(incoming.officeEnd, next.officeHours.endMinute)
  var detectorKeys = ["idle", "recentInput", "fullscreen", "media", "microphone", "screenSharing", "dictation"]
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
    lastActiveAtMs: Number(nowMs || 0),
    dueAtMs: 0,
    postponedUntilMs: 0,
    cooldownUntilMs: 0,
    warningEndsAtMs: 0,
    breakEndsAtMs: 0,
    activeBreakDurationMs: 0,
    activeBreakIsLong: false,
    activeBreakIsPlanned: false,
    activePlannedOccurrence: null,
    handledPlannedOccurrences: [],
    breaksSinceLong: 0,
    protectedCategory: "",
    pauseReason: "",
    snoozesUsed: 0,
    naturalBreakDecision: null,
    statistics: defaultStatistics(nowMs),
    totals: { prompted: 0, completed: 0, postponed: 0, skipped: 0, delayed: 0 }
  }
}

function localDayKey(nowMs) {
  var date = new Date(Number(nowMs || 0))
  function pad(value) { return value < 10 ? "0" + value : String(value) }
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
}

function defaultStatisticDay(dayKey) {
  return {
    dateKey: String(dayKey || ""),
    activeMs: 0,
    completed: 0,
    skipped: 0,
    snoozed: 0,
    shortBreaks: 0,
    longBreaks: 0,
    plannedBreaks: 0,
    plannedSkipped: 0,
    plannedIgnored: 0,
    longestSessionMs: 0,
    sessionDurationsMs: [],
    sessions: []
  }
}

function defaultStatistics(nowMs) {
  return { today: defaultStatisticDay(localDayKey(nowMs)), days: [], currentSessionActiveMs: 0 }
}

function boundedStatisticNumber(value, maximum) {
  var number = Number(value)
  return isFinite(number) ? Math.max(0, Math.min(maximum, number)) : 0
}

function copyStatisticDay(value, fallbackDayKey) {
  value = value || {}
  var dayKey = /^\d{4}-\d{2}-\d{2}$/.test(String(value.dateKey || ""))
    ? String(value.dateKey) : String(fallbackDayKey || "")
  var durations = Array.isArray(value.sessionDurationsMs) ? value.sessionDurationsMs : []
  durations = durations.slice(0, MaximumSessionsPerDay).map(function(duration) {
    return boundedStatisticNumber(duration, MaximumStatisticMs)
  })
  var sessions = Array.isArray(value.sessions) ? value.sessions : []
  sessions = sessions.slice(0, MaximumSessionsPerDay).map(function(session) {
    session = session || {}
    var outcome = ["break", "long-break", "planned-break", "away"].indexOf(String(session.outcome || "")) >= 0
      ? String(session.outcome) : "break"
    return {
      endedAtMs: boundedStatisticNumber(session.endedAtMs, Number.MAX_SAFE_INTEGER),
      durationMs: boundedStatisticNumber(session.durationMs, MaximumStatisticMs),
      outcome: outcome
    }
  })
  return {
    dateKey: dayKey,
    activeMs: boundedStatisticNumber(value.activeMs, MaximumStatisticMs),
    completed: boundedStatisticNumber(value.completed, MaximumStatisticCount),
    skipped: boundedStatisticNumber(value.skipped, MaximumStatisticCount),
    snoozed: boundedStatisticNumber(value.snoozed, MaximumStatisticCount),
    shortBreaks: boundedStatisticNumber(value.shortBreaks, MaximumStatisticCount),
    longBreaks: boundedStatisticNumber(value.longBreaks, MaximumStatisticCount),
    plannedBreaks: boundedStatisticNumber(value.plannedBreaks, MaximumStatisticCount),
    plannedSkipped: boundedStatisticNumber(value.plannedSkipped, MaximumStatisticCount),
    plannedIgnored: boundedStatisticNumber(value.plannedIgnored, MaximumStatisticCount),
    longestSessionMs: boundedStatisticNumber(value.longestSessionMs, MaximumStatisticMs),
    sessionDurationsMs: durations,
    sessions: sessions
  }
}

function copyStatistics(value, nowMs) {
  value = value || {}
  var todayKey = localDayKey(nowMs)
  var today = copyStatisticDay(value.today, todayKey)
  var days = Array.isArray(value.days) ? value.days : []
  days = days.slice(0, MaximumStatisticDays).map(function(day) {
    return copyStatisticDay(day, "")
  }).filter(function(day) { return day.dateKey !== "" && day.dateKey !== today.dateKey })
  return {
    today: today,
    days: days,
    currentSessionActiveMs: boundedStatisticNumber(value.currentSessionActiveMs, MaximumStatisticMs)
  }
}

function ensureStatisticsDay(snapshot, nowMs) {
  var next = snapshot
  var todayKey = localDayKey(nowMs)
  var statistics = next.statistics
  if (statistics.today.dateKey !== todayKey) {
    var previous = statistics.today
    var hasPreviousData = previous.activeMs > 0 || previous.completed > 0
      || previous.skipped > 0 || previous.snoozed > 0 || previous.plannedBreaks > 0
      || previous.plannedSkipped > 0 || previous.plannedIgnored > 0 || previous.sessions.length > 0
    statistics.days = (hasPreviousData ? [previous] : []).concat(statistics.days.filter(function(day) {
      return day.dateKey !== previous.dateKey && day.dateKey !== todayKey
    })).slice(0, MaximumStatisticDays)
    statistics.today = defaultStatisticDay(todayKey)
  }
  next.statistics = statistics
  return next
}

function recordActiveStatistics(snapshot, elapsedMs, nowMs) {
  var next = snapshot
  var elapsed = boundedStatisticNumber(elapsedMs, 5 * 60 * 1000)
  next.statistics.today.activeMs = Math.min(MaximumStatisticMs, next.statistics.today.activeMs + elapsed)
  next.statistics.currentSessionActiveMs = Math.min(MaximumStatisticMs,
    next.statistics.currentSessionActiveMs + elapsed)
  next.statistics.today.longestSessionMs = Math.max(next.statistics.today.longestSessionMs,
    next.statistics.currentSessionActiveMs)
  return next
}

function closeStatisticsSession(snapshot, nowMs, outcome) {
  var next = ensureStatisticsDay(snapshot, nowMs)
  var duration = next.statistics.currentSessionActiveMs
  if (duration > 0) {
    next.statistics.today.sessionDurationsMs.unshift(duration)
    next.statistics.today.sessionDurationsMs = next.statistics.today.sessionDurationsMs.slice(0, MaximumSessionsPerDay)
    next.statistics.today.sessions.unshift({ endedAtMs: Number(nowMs), durationMs: duration, outcome: outcome })
    next.statistics.today.sessions = next.statistics.today.sessions.slice(0, MaximumSessionsPerDay)
  }
  next.statistics.currentSessionActiveMs = 0
  return next
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
  var priority = ["dictation", "screen-sharing", "meeting", "camera", "microphone", "game", "application", "video", "media", "fullscreen"]
  var best = null
  for (var i = 0; i < (evidence || []).length; i++) {
    var item = evidence[i] || {}
    var category = String(item.category || "")
    var detectorKey = category === "meeting" || category === "camera" ? "microphone"
      : category === "screen-sharing" ? "screenSharing"
      : category === "video" ? "media"
      : category === "application" || category === "game" ? "applications" : category
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
  var state = String(value.state || State.Working)
  if (ValidStates.indexOf(state) < 0) state = State.Working
  function nonnegative(number) {
    number = Number(number)
    return isFinite(number) ? Math.max(0, number) : 0
  }
  var decision = value.naturalBreakDecision || null
  if (decision && ["resumed", "reset"].indexOf(String(decision.kind || "")) < 0) decision = null
  if (decision) {
    var before = decision.before || {}
    decision = {
      kind: String(decision.kind),
      awayMs: nonnegative(decision.awayMs),
      decidedAtMs: nonnegative(decision.decidedAtMs),
      undoUntilMs: nonnegative(decision.undoUntilMs),
      before: {
        state: [State.Working, State.DueSoon].indexOf(String(before.state || "")) >= 0
          ? String(before.state) : State.Working,
        accumulatedActiveMs: nonnegative(before.accumulatedActiveMs),
        currentSessionActiveMs: boundedStatisticNumber(before.currentSessionActiveMs, MaximumStatisticMs),
        breaksSinceLong: nonnegative(before.breaksSinceLong),
        snoozesUsed: nonnegative(before.snoozesUsed)
      }
    }
  }
  var planned = copyPlannedOccurrence(value.activePlannedOccurrence)
  var handledPlanned = Array.isArray(value.handledPlannedOccurrences)
    ? value.handledPlannedOccurrences : []
  handledPlanned = handledPlanned.slice(0, MaximumHandledPlannedOccurrences).map(function(key) {
    return String(key || "").slice(0, 80)
  }).filter(function(key) { return /^[a-z0-9._-]+@\d{4}-\d{2}-\d{2}$/.test(key) })
  return {
    version: 1,
    state: state,
    accumulatedActiveMs: nonnegative(value.accumulatedActiveMs),
    stateEnteredAtMs: nonnegative(value.stateEnteredAtMs),
    lastObservedAtMs: nonnegative(value.lastObservedAtMs),
    lastActiveAtMs: nonnegative(value.lastActiveAtMs === undefined
      ? value.lastObservedAtMs : value.lastActiveAtMs),
    dueAtMs: nonnegative(value.dueAtMs),
    postponedUntilMs: nonnegative(value.postponedUntilMs),
    cooldownUntilMs: nonnegative(value.cooldownUntilMs),
    warningEndsAtMs: nonnegative(value.warningEndsAtMs),
    breakEndsAtMs: nonnegative(value.breakEndsAtMs),
    activeBreakDurationMs: nonnegative(value.activeBreakDurationMs),
    activeBreakIsLong: value.activeBreakIsLong === true,
    activeBreakIsPlanned: value.activeBreakIsPlanned === true,
    activePlannedOccurrence: planned,
    handledPlannedOccurrences: handledPlanned,
    breaksSinceLong: nonnegative(value.breaksSinceLong),
    protectedCategory: String(value.protectedCategory || ""),
    pauseReason: String(value.pauseReason || ""),
    snoozesUsed: nonnegative(value.snoozesUsed),
    naturalBreakDecision: decision,
    statistics: copyStatistics(value.statistics, value.lastObservedAtMs || 0),
    totals: {
      prompted: nonnegative(totals.prompted),
      completed: nonnegative(totals.completed),
      postponed: nonnegative(totals.postponed),
      skipped: nonnegative(totals.skipped),
      delayed: nonnegative(totals.delayed)
    }
  }
}

function recoverSnapshot(snapshot, nowMs) {
  var next = copySnapshot(snapshot)
  var latest = Number(nowMs) + MaximumPersistedFutureMs
  var timestamps = [
    "stateEnteredAtMs", "lastObservedAtMs", "lastActiveAtMs", "dueAtMs", "postponedUntilMs",
    "cooldownUntilMs", "warningEndsAtMs", "breakEndsAtMs"
  ]
  for (var i = 0; i < timestamps.length; i++)
    if (next[timestamps[i]] > latest) return null
  if (next.naturalBreakDecision
      && (next.naturalBreakDecision.decidedAtMs > latest
        || next.naturalBreakDecision.undoUntilMs > latest)) return null
  if (next.activePlannedOccurrence) {
    var plannedTimestamps = ["scheduledAtMs", "expiresAtMs", "idleStartedAtMs", "intervalDueAtMs"]
    for (var plannedIndex = 0; plannedIndex < plannedTimestamps.length; plannedIndex++)
      if (next.activePlannedOccurrence[plannedTimestamps[plannedIndex]] > latest) return null
  }
  var statisticDays = [next.statistics.today].concat(next.statistics.days)
  for (var dayIndex = 0; dayIndex < statisticDays.length; dayIndex++)
    for (var sessionIndex = 0; sessionIndex < statisticDays[dayIndex].sessions.length; sessionIndex++)
      if (statisticDays[dayIndex].sessions[sessionIndex].endedAtMs > latest) return null
  return next
}

function resetSession(snapshot, nowMs) {
  var previous = copySnapshot(snapshot)
  var next = defaultSnapshot(nowMs)
  next.totals = previous.totals
  next.statistics = previous.statistics
  next.handledPlannedOccurrences = previous.handledPlannedOccurrences
  return next
}

function observePlannedOccurrence(snapshot, input, config, nowMs, protection) {
  var next = copySnapshot(snapshot)
  var planned = next.activePlannedOccurrence
  if (!planned) return next

  if (Number(nowMs) > planned.expiresAtMs)
    return finishPlannedOccurrence(next, nowMs, config, "ignored")

  next = reconcilePlannedAway(next, nowMs, input.idle === true)
  planned = next.activePlannedOccurrence
  var awayCredit = plannedAwayCredit(next, nowMs)
  if (awayCredit >= planned.durationMs)
    return finishPlannedOccurrence(next, nowMs, config, "completed")

  if (input.idle === true) {
    if (Number(nowMs) >= planned.scheduledAtMs) planned.deferred = true
    next.activePlannedOccurrence = planned
    next.state = State.Waiting
    next.pauseReason = "planned-away"
    return next
  }

  if (next.state === State.Waiting && next.pauseReason === "manual") {
    if (Number(nowMs) >= planned.scheduledAtMs) planned.deferred = true
    next.activePlannedOccurrence = planned
    return next
  }
  if (next.postponedUntilMs > Number(nowMs)) {
    next.state = State.Waiting
    next.pauseReason = "planned-snooze"
    return next
  }

  var delayAge = Math.max(0, Number(nowMs) - planned.scheduledAtMs)
  if (protection && delayAge < config.maximumDelayMs) {
    if (Number(nowMs) >= planned.scheduledAtMs) planned.deferred = true
    next.activePlannedOccurrence = planned
    if (next.state !== State.Protected) next.totals.delayed++
    next.state = State.Protected
    next.protectedCategory = protection.category
    return next
  }
  if (next.state === State.Protected) {
    next.cooldownUntilMs = Number(nowMs) + config.cooldownMs
    next.protectedCategory = ""
  }
  if (Number(nowMs) < next.cooldownUntilMs && delayAge < config.maximumDelayMs) {
    if (Number(nowMs) >= planned.scheduledAtMs) planned.deferred = true
    next.activePlannedOccurrence = planned
    next.state = State.Waiting
    next.pauseReason = "planned-cooldown"
    return next
  }

  if (Number(nowMs) < planned.scheduledAtMs) {
    var remaining = planned.scheduledAtMs - Number(nowMs)
    next.pauseReason = ""
    if (next.state === State.Final) return next
    if (next.state === State.Warning) {
      if (remaining <= config.finalMs) next.state = State.Final
      return next
    }
    return startWarning(next, nowMs, config, remaining)
  }

  if (next.state === State.Final && !planned.deferred
      && input.typingActive !== true && input.naturalPause !== false)
    return startPlannedBreak(next, nowMs, config)

  if (!planned.deferred && Number(nowMs) <= planned.scheduledAtMs + 1000
      && input.typingActive !== true && input.naturalPause !== false)
    return startPlannedBreak(next, nowMs, config)

  planned.deferred = true
  next.activePlannedOccurrence = planned
  next.state = State.PlannedReady
  next.stateEnteredAtMs = Number(nowMs)
  next.pauseReason = ""
  next.warningEndsAtMs = 0
  return next
}

function observe(snapshot, input, config) {
  var cfg = config && config.version === 1 ? config : normalizeConfig(config)
  var next = copySnapshot(snapshot || defaultSnapshot(input.nowMs))
  var now = Number(input.nowMs)
  var previous = Number(next.lastObservedAtMs || now)
  var elapsed = clamp(now - previous, 0, 5 * 60 * 1000)
  var activeNow = input.active === true && input.idle !== true
  var accumulationPaused = input.accumulationPaused === true
  next = ensureStatisticsDay(next, now)
  var plannedCandidate = next.activePlannedOccurrence ? null
    : nextActionablePlannedOccurrence(cfg, now, next.handledPlannedOccurrences)
  var manuallyPaused = next.state === State.Waiting && next.pauseReason === "manual"
  if (next.naturalBreakDecision && now > next.naturalBreakDecision.undoUntilMs)
    next.naturalBreakDecision = null
  var awayMs = now - Number(next.lastActiveAtMs || previous)
  var stableWork = (next.state === State.Working || next.state === State.DueSoon)
    && !next.activePlannedOccurrence && !plannedCandidate
  if (activeNow && !accumulationPaused && !manuallyPaused && stableWork
      && awayMs >= NaturalBreakReviewMs) {
    var before = {
      state: next.state,
      accumulatedActiveMs: next.accumulatedActiveMs,
      currentSessionActiveMs: next.statistics.currentSessionActiveMs,
      breaksSinceLong: next.breaksSinceLong,
      snoozesUsed: next.snoozesUsed
    }
    var kind = awayMs >= SessionResetInactivityMs ? "reset" : "resumed"
    if (kind === "reset") {
      next = closeStatisticsSession(next, now, "away")
      next = resetSession(next, now)
    }
    next.naturalBreakDecision = {
      kind: kind,
      awayMs: awayMs,
      decidedAtMs: now,
      undoUntilMs: now + NaturalBreakUndoMs,
      before: before
    }
    elapsed = 0
  }
  next.lastObservedAtMs = now

  if (!cfg.enabled) {
    next.state = State.Disabled
    return next
  }

  if (next.state === State.Breaking) {
    if (activeNow) next.lastActiveAtMs = now
    if (now >= next.breakEndsAtMs) return completeBreak(next, now, cfg)
    return next
  }

  var protection = strongestEvidence(input.evidence || [], cfg)
  if (!next.activePlannedOccurrence) {
    if (plannedCandidate) next = beginPlannedOccurrence(next, plannedCandidate, now, cfg)
  }
  if (next.activePlannedOccurrence) {
    var plannedWasManuallyPaused = next.state === State.Waiting && next.pauseReason === "manual"
    if (activeNow && !accumulationPaused && !plannedWasManuallyPaused
        && inOfficeHours(new Date(now), cfg.officeHours))
      next = recordActiveStatistics(next, elapsed, now)
    next = observePlannedOccurrence(next, input, cfg, now, protection)
    if (activeNow) next.lastActiveAtMs = now
    return next
  }

  if (activeNow) next.lastActiveAtMs = now
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

  if (activeNow && !accumulationPaused && !manuallyPaused && next.state !== State.Breaking)
    next = recordActiveStatistics(next, elapsed, now)

  if ((next.state === State.Warning || next.state === State.Final) && protection) {
    if (!next.dueAtMs) next.dueAtMs = next.warningEndsAtMs
    if (now - next.dueAtMs < cfg.maximumDelayMs) {
      next.state = State.Protected
      next.protectedCategory = protection.category
      next.totals.delayed++
      return next
    }
  }
  if ((next.state === State.Warning || next.state === State.Final)
      && input.typingActive === true
      && now >= next.warningEndsAtMs - 10000) {
    if (!next.dueAtMs) next.dueAtMs = next.warningEndsAtMs
    if (now - next.dueAtMs < cfg.maximumDelayMs) {
      next.warningEndsAtMs = now + 10000
      next.state = State.Warning
      return next
    }
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

  if (activeNow && !accumulationPaused) next.accumulatedActiveMs += elapsed
  var remaining = Math.max(0, cfg.focusMs - next.accumulatedActiveMs)
  if (remaining <= cfg.warningMs && protection) {
    if (!next.dueAtMs) next.dueAtMs = now + remaining
    if (now - next.dueAtMs < cfg.maximumDelayMs) {
      if (next.state !== State.Protected) next.totals.delayed++
      next.state = State.Protected
      next.protectedCategory = protection.category
      return next
    }
  }
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

function undoNaturalBreak(snapshot, nowMs) {
  var next = copySnapshot(snapshot)
  var decision = next.naturalBreakDecision
  if (!decision || Number(nowMs) > decision.undoUntilMs) {
    next.naturalBreakDecision = null
    return next
  }
  if (decision.kind === "reset") {
    next.state = decision.before.state
    next.accumulatedActiveMs = decision.before.accumulatedActiveMs
    next.breaksSinceLong = decision.before.breaksSinceLong
    next.snoozesUsed = decision.before.snoozesUsed
    var sessions = next.statistics.today.sessions
    if (sessions.length && sessions[0].outcome === "away"
        && sessions[0].endedAtMs === decision.decidedAtMs) {
      sessions.shift()
      next.statistics.today.sessionDurationsMs.shift()
    }
    next.statistics.currentSessionActiveMs = decision.before.currentSessionActiveMs
  } else {
    next = resetSession(next, nowMs)
  }
  next.stateEnteredAtMs = Number(nowMs)
  next.lastObservedAtMs = Number(nowMs)
  next.lastActiveAtMs = Number(nowMs)
  next.naturalBreakDecision = null
  return next
}

function naturalBreakMessage(snapshot) {
  var decision = snapshot && snapshot.naturalBreakDecision
  if (!decision) return ""
  var away = formatDuration(decision.awayMs)
  return decision.kind === "reset"
    ? "Fresh session after " + away + " away"
    : "Timer resumed after " + away + " away"
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
  var longBreak = isNextBreakLong(next, config)
  var duration = longBreak ? config.longBreakMs : config.breakMs
  next.state = State.Breaking
  next.stateEnteredAtMs = nowMs
  next.activeBreakDurationMs = duration
  next.activeBreakIsLong = longBreak
  next.breakEndsAtMs = nowMs + duration
  return next
}

function isNextBreakLong(snapshot, config) {
  return config.longBreakEvery > 0
    && Number((snapshot || {}).breaksSinceLong || 0) + 1 >= config.longBreakEvery
}

function completeBreak(snapshot, nowMs, config) {
  var next = copySnapshot(snapshot)
  if (next.activeBreakIsPlanned && next.activePlannedOccurrence)
    return finishPlannedOccurrence(next, nowMs,
      config && config.version === 1 ? config : normalizeConfig(config), "completed")
  next = closeStatisticsSession(next, nowMs, next.activeBreakIsLong ? "long-break" : "break")
  next.statistics.today.completed++
  if (next.activeBreakIsLong) next.statistics.today.longBreaks++
  else next.statistics.today.shortBreaks++
  next.breaksSinceLong = next.activeBreakIsLong ? 0 : next.breaksSinceLong + 1
  next.state = State.Working
  next.stateEnteredAtMs = nowMs
  next.accumulatedActiveMs = 0
  next.dueAtMs = 0
  next.postponedUntilMs = 0
  next.cooldownUntilMs = 0
  next.warningEndsAtMs = 0
  next.breakEndsAtMs = 0
  next.activeBreakDurationMs = 0
  next.activeBreakIsLong = false
  next.protectedCategory = ""
  next.snoozesUsed = 0
  next.totals.completed++
  return next
}

function skipBreak(snapshot, nowMs, config) {
  var previous = copySnapshot(snapshot)
  if (previous.activePlannedOccurrence)
    return skipPlannedOccurrence(previous, nowMs,
      config && config.version === 1 ? config : normalizeConfig(config))
  var statistics = previous.statistics
  var next = completeBreak(previous, nowMs)
  next.statistics = statistics
  next = ensureStatisticsDay(next, nowMs)
  next.statistics.today.skipped++
  next.totals.completed = Math.max(0, next.totals.completed - 1)
  next.totals.skipped++
  return next
}

function postpone(snapshot, nowMs, durationMs, config) {
  if (!canPostpone(snapshot, config)) return copySnapshot(snapshot)
  if (snapshot && snapshot.activePlannedOccurrence)
    return postponePlanned(snapshot, nowMs, durationMs, config)
  var next = copySnapshot(snapshot)
  next.state = State.Waiting
  next.stateEnteredAtMs = nowMs
  next.postponedUntilMs = nowMs + Math.max(0, Number(durationMs || 0))
  next.warningEndsAtMs = 0
  next.snoozesUsed++
  next.totals.postponed++
  next = ensureStatisticsDay(next, nowMs)
  next.statistics.today.snoozed++
  return next
}

function delayNextBreak(snapshot, nowMs, durationMs, config) {
  if (!canPostpone(snapshot, config)) return copySnapshot(snapshot)
  var state = snapshot && snapshot.state
  if (state !== State.Working && state !== State.DueSoon
      && state !== State.Warning && state !== State.Final)
    return postpone(snapshot, nowMs, durationMs, config)

  var next = copySnapshot(snapshot)
  var delay = Math.max(0, Number(durationMs || 0))
  var remaining = state === State.Warning || state === State.Final
    ? Math.max(0, Number(next.warningEndsAtMs || 0) - Number(nowMs || 0))
    : Math.max(0, config.focusMs - next.accumulatedActiveMs)
  next.state = State.Working
  next.stateEnteredAtMs = nowMs
  next.lastObservedAtMs = nowMs
  next.accumulatedActiveMs = Math.max(0, config.focusMs - remaining - delay)
  next.dueAtMs = 0
  next.postponedUntilMs = 0
  next.warningEndsAtMs = 0
  next.snoozesUsed++
  next.totals.postponed++
  next = ensureStatisticsDay(next, nowMs)
  next.statistics.today.snoozed++
  return next
}

function canPostpone(snapshot, config) {
  var cfg = config && config.version === 1 ? config : normalizeConfig(config)
  if (snapshot && snapshot.activePlannedOccurrence)
    return Number(snapshot.activePlannedOccurrence.snoozesUsed || 0) < cfg.snoozeBudget
  return Number(snapshot && snapshot.snoozesUsed || 0) < cfg.snoozeBudget
}

function canSkipBreak(config, snapshot) {
  var cfg = config && config.version === 1 ? config : normalizeConfig(config)
  if (snapshot && snapshot.activePlannedOccurrence) return true
  return cfg.enforcement !== "hardcore"
}

function canTogglePause(state) {
  return state !== State.Breaking
}

function pause(snapshot, nowMs, durationMs) {
  var next = copySnapshot(snapshot)
  next.state = State.Waiting
  next.pauseReason = "manual"
  next.postponedUntilMs = durationMs > 0 ? Number(nowMs) + Number(durationMs) : 0
  next.lastObservedAtMs = Number(nowMs)
  return next
}

function resume(snapshot, nowMs) {
  var next = copySnapshot(snapshot)
  next.state = State.Working
  next.pauseReason = ""
  next.postponedUntilMs = 0
  next.lastObservedAtMs = Number(nowMs)
  return next
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

function panelShortcutDefinitions() {
  return [
    { action: "breakNow", setting: "shortcutBreakNow", fallback: "B" },
    { action: "snooze1", setting: "shortcutSnooze1", fallback: "1" },
    { action: "snooze5", setting: "shortcutSnooze5", fallback: "2" },
    { action: "snooze15", setting: "shortcutSnooze15", fallback: "3" },
    { action: "skipToday", setting: "shortcutSkipToday", fallback: "S" },
    { action: "pause", setting: "shortcutPause", fallback: "P" },
    { action: "history", setting: "shortcutHistory", fallback: "H" },
    { action: "options", setting: "shortcutOptions", fallback: "O" },
    { action: "edit", setting: "shortcutEdit", fallback: "E" },
    { action: "generalTab", setting: "shortcutGeneralTab", fallback: "G" },
    { action: "breaksTab", setting: "shortcutBreaksTab", fallback: "R" },
    { action: "plansTab", setting: "shortcutPlansTab", fallback: "L" },
    { action: "contextTab", setting: "shortcutContextTab", fallback: "C" },
    { action: "experienceTab", setting: "shortcutExperienceTab", fallback: "X" },
    { action: "close", setting: "shortcutClose", fallback: "Q" },
    { action: "hints", setting: "shortcutHints", fallback: "?" }
  ]
}

function resetTotals(snapshot) {
  var next = copySnapshot(snapshot)
  next.totals = { prompted: 0, completed: 0, postponed: 0, skipped: 0, delayed: 0 }
  var currentSession = next.statistics.currentSessionActiveMs
  next.statistics = defaultStatistics(next.lastObservedAtMs)
  next.statistics.currentSessionActiveMs = currentSession
  return next
}

function medianSessionDuration(snapshot) {
  var values = snapshot && snapshot.statistics && snapshot.statistics.today
    ? snapshot.statistics.today.sessionDurationsMs.slice() : []
  if (!values.length) return 0
  values.sort(function(left, right) { return left - right })
  var middle = Math.floor(values.length / 2)
  return values.length % 2 ? values[middle] : (values[middle - 1] + values[middle]) / 2
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
  if (state === State.PlannedReady) return snapshot.activePlannedOccurrence
    ? snapshot.activePlannedOccurrence.name + " is ready" : "Planned break is ready"
  if (state === State.Breaking) return "Look elsewhere"
  if (state === State.Paused) return "Breaks paused"
  if (state === State.Disabled) return "LookElsewhere is off"
  if (state === State.DueSoon) return "Break due soon"
  return "Break starts in"
}

function protectedExplanation(category) {
  var labels = {
    "screen-sharing": "screen sharing or recording is active",
    meeting: "your meeting is active",
    camera: "your camera is active",
    microphone: "your microphone is active",
    game: "a Steam game is active",
    video: "video is playing",
    media: "media is playing",
    application: "a protected application is focused",
    fullscreen: "fullscreen work is active",
    dictation: "dictation is active"
  }
  return "Held quietly while " + (labels[String(category || "")] || "protected work is active") + "."
}

function contextShortLabel(category) {
  var labels = {
    dictation: "Dictation",
    "screen-sharing": "Sharing",
    meeting: "Meeting",
    camera: "Camera",
    microphone: "Mic",
    game: "Game",
    video: "Video",
    media: "Media",
    application: "Focus",
    fullscreen: "Fullscreen"
  }
  return labels[String(category || "")] || ""
}

function pipewireRoleEvidence(record, focused) {
  var value = record || {}
  var role = String(value.role || "").toLowerCase()
  if (role === "screen") return { category: "screen-sharing", confidence: 0.98, active: true }
  if (role === "communication") return { category: "meeting", confidence: 0.95, active: true }
  if (role === "camera") return { category: "camera", confidence: 0.9, active: true }
  if (role === "movie" && focused === true) return { category: "video", confidence: 0.9, active: true }
  if (value.captureAudio === true) return { category: "microphone", confidence: 0.85, active: true }
  return null
}

function browserContextEvidence(context) {
  var value = context || {}
  if (value.video_state !== "playing") return null
  if (value.picture_in_picture === true
      || (value.browser_focused === true && value.video_visible === true))
    return { category: "video", confidence: 1, active: true }
  return null
}

function parseSundownStatus(raw) {
  try {
    var text = String(raw || "")
    if (text.length < 1 || text.length > 64 * 1024) return null
    var value = JSON.parse(text)
    if (value.version !== 1 || !value.steam || typeof value.steam.active !== "boolean") return null
    var active = value.steam.active
    var sources = []
    if (value.games !== undefined) {
      if (!value.games || typeof value.games.active !== "boolean"
          || !Array.isArray(value.games.sources) || value.games.sources.length > 8) return null
      active = value.games.active
      for (var i = 0; i < value.games.sources.length; i++) {
        var source = String(value.games.sources[i] || "")
        if (!source || source.length > 64) return null
        sources.push(source)
      }
    } else {
      var sharedGroup = String(value.steam.shared_app_group || "").slice(0, 64)
      var groups = value.apps && Array.isArray(value.apps.groups) ? value.apps.groups : []
      for (var j = 0; !active && sharedGroup && j < Math.min(groups.length, 32); j++) {
        var group = groups[j] || {}
        if (String(group.name || "").slice(0, 64) === sharedGroup && group.active === true)
          active = true
      }
    }
    var sensor = value.runtime ? String(value.runtime.steam_sensor || "") : ""
    return { active: active, sources: sources, sensor: sensor.slice(0, 64) }
  } catch (error) {
    return null
  }
}

function pipewireNodeMatchesApp(record, appId) {
  var candidates = (record && Array.isArray(record.applications)) ? record.applications : []
  for (var i = 0; i < candidates.length; i++)
    if (appIdsMatch(candidates[i], appId)) return true
  return false
}

function appIdsMatch(left, right) {
  var a = String(left || "").toLowerCase().replace(/\.desktop$/, "")
  var b = String(right || "").toLowerCase().replace(/\.desktop$/, "")
  if (!a || !b) return false
  return a === b || a.indexOf(b + ".") === 0 || b.indexOf(a + ".") === 0
}

function matchesProtectedApp(appId, protectedApps) {
  var active = String(appId || "").toLowerCase().replace(/\.desktop$/, "")
  for (var i = 0; i < (protectedApps || []).length; i++) {
    var configured = String(protectedApps[i] || "").toLowerCase().replace(/\.desktop$/, "")
    if (appIdsMatch(active, configured)) return true
    if (configured === "steam" && /^steam_app_[0-9]+$/.test(active)) return true
  }
  return false
}

function toggleProtectedApp(protectedApps, appId) {
  var configured = (protectedApps || []).map(function(value) {
    return String(value || "").trim().toLowerCase().replace(/\.desktop$/, "")
  }).filter(function(value) { return value !== "" })
  var active = String(appId || "").trim().toLowerCase().replace(/\.desktop$/, "")
  if (!active) return configured.join(", ")
  if (matchesProtectedApp(active, configured)) return configured.filter(function(value) {
    return !appIdsMatch(active, value)
      && !(value === "steam" && /^steam_app_[0-9]+$/.test(active))
  }).join(", ")
  configured.push(active)
  return configured.join(", ")
}
