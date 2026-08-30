pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Wayland
// Quickshell 0.3 does not reliably re-export this optional submodule when a
// component is loaded dynamically as a third-party plugin.
import Quickshell.Wayland._IdleNotify
import "Model.js" as Model

Item {
  id: service

  property var shell: null
  readonly property string pluginId: "io.github.silouanwright.look-elsewhere"
  readonly property string configuredStateHome: Quickshell.env("XDG_STATE_HOME")
  readonly property string stateHome: configuredStateHome.indexOf("/") === 0
    ? configuredStateHome : Quickshell.env("HOME") + "/.local/state"
  readonly property string stateDir: stateHome + "/look-elsewhere"
  readonly property string statePath: stateDir + "/state.json"
  readonly property int stateReadLimit: 64 * 1024
  readonly property string boundedReaderPath: decodeURIComponent(
    String(Qt.resolvedUrl("vendor/qmlpack/bounded-read/bin/bounded-read")).replace(/^file:\/\//, ""))
  readonly property string pipewireEvidencePath: decodeURIComponent(
    String(Qt.resolvedUrl("tools/pipewire-evidence")).replace(/^file:\/\//, ""))
  readonly property string sundownStatusPath: "/run/sundown/status.json"
  readonly property string browserSocketPath: {
    var runtime = Quickshell.env("XDG_RUNTIME_DIR")
    if (!runtime) runtime = "/run/user/" + Quickshell.env("UID")
    return runtime + "/look-elsewhere-browser.sock"
  }

  property var config: Model.defaultConfig()
  property var snapshot: Model.defaultSnapshot(Date.now())
  property bool stateStorageReady: false
  property bool stateLoaded: false
  property bool dictationActive: false
  property bool dictationAvailable: false
  property var pipewireEvidenceRecords: []
  property int pipewireEvidenceGeneration: 0
  property string probedActiveAppId: ""
  property bool probedFullscreenActive: false
  property bool probedActiveWindowAvailable: false
  property int activeWindowGeneration: 0
  property bool startSoundAvailable: true
  property bool completionSoundAvailable: true
  property bool completionCuePlayed: false
  property string recoveryWarning: ""
  property bool persistenceBlocked: false
  property bool demoMode: false
  property bool demoIdle: false
  property bool demoNaturalPause: true
  property bool demoTypingProbe: false
  property bool demoGame: false
  property var demoEvidence: []
  property var preDemoSnapshot: null
  property var preDemoConfig: null
  property string preDemoRecoveryWarning: ""
  property bool preDemoPersistenceBlocked: false
  property int demoSequenceIndex: -1
  property string demoFixture: ""
  property real lastObserveStartedAtMs: 0
  property int lastObserveGapMs: 0
  property int maximumObserveGapMs: 0
  property int lastObserveDurationMs: 0
  property int maximumObserveDurationMs: 0
  property bool browserContextSeen: false
  property bool browserContextConnected: false
  property real browserContextReceivedAtMs: 0
  property string browserContextSessionId: ""
  property real browserContextSequence: 0
  property var browserContext: ({})
  readonly property string browserIntegrationStatus: browserContextConnected
    ? "Enhanced" : browserContextSeen ? "Unavailable" : "Standard"
  property bool sundownSeen: false
  property bool sundownConnected: false
  property bool sundownSteamActive: false
  property string sundownSteamSensor: ""
  readonly property string sundownIntegrationStatus: sundownConnected
    ? "Connected" : sundownSeen ? "Unavailable" : "Not installed"
  readonly property var demoSequence: [
    "idle", "typing", "meeting", "microphone", "camera", "screen-sharing",
    "video", "media", "fullscreen", "game", "dictation", "due", "warning", "final",
    "planned-warning", "planned-ready", "planned-break", "casual-break",
    "balanced-break", "hardcore-break", "long-break", "stats", "paused", "postponed"
  ]

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var pipewireLinkGroups: Pipewire.linkGroups ? Pipewire.linkGroups.values : []
  readonly property var activePipewireNodeIds: {
    var ids = []
    for (var i = 0; i < pipewireLinkGroups.length; i++) {
      var group = pipewireLinkGroups[i]
      if (!group || group.state !== PwLinkState.Active) continue
      var nodes = [group.source, group.target]
      for (var j = 0; j < nodes.length; j++) {
        if (!nodes[j] || !nodes[j].isStream) continue
        var id = Number(nodes[j].id)
        if (id > 0 && ids.indexOf(id) < 0) ids.push(id)
      }
    }
    ids.sort(function(left, right) { return left - right })
    return ids.slice(0, 32)
  }
  readonly property var activeToplevel: Hyprland.activeToplevel
  readonly property string activeAppId: activeToplevel && activeToplevel.wayland
    ? String(activeToplevel.wayland.appId || "") : probedActiveAppId
  readonly property bool fullscreenAvailable: !activeToplevel
    || !!activeToplevel.wayland || probedActiveWindowAvailable
  readonly property bool fullscreenActive: config.detectors.fullscreen
    && !!(activeToplevel && (activeToplevel.wayland
      ? activeToplevel.wayland.fullscreen : probedFullscreenActive))
  readonly property bool mediaActive: {
    for (var i = 0; i < players.length; i++) {
      var player = players[i]
      if (player && player.isPlaying
          && (Model.appIdsMatch(player.desktopEntry, activeAppId)
            || Model.appIdsMatch(player.identity, activeAppId))) return true
    }
    return false
  }
  readonly property var pipewireEvidence: {
    var result = []
    for (var i = 0; i < pipewireEvidenceRecords.length; i++) {
      var record = pipewireEvidenceRecords[i]
      var focused = Model.pipewireNodeMatchesApp(record, activeAppId)
      var item = Model.pipewireRoleEvidence(record, focused)
      if (item) result.push(item)
    }
    return result
  }
  readonly property bool idle: demoMode ? demoIdle : idleMonitor.isIdle
  readonly property bool naturalPauseReady: demoMode ? demoNaturalPause : naturalPauseMonitor.isIdle
  // Must exceed the one-second scheduler interval so recent input cannot
  // expire between adjacent observations. Keep explicit for live calibration.
  readonly property int typingQuietSeconds: 2
  readonly property bool typingHoldActive: config.detectors.recentInput
    && (!demoMode || demoTypingProbe)
    && (phase === Model.State.Warning || phase === Model.State.Final)
    && remainingMs <= 10000
    && !typingPauseMonitor.isIdle
  readonly property bool idlePauseActive: config.detectors.idle && idle
  readonly property bool steamPauseActive: config.pauseDuringSteamGames
    && (demoMode ? demoGame : sundownConnected && sundownSteamActive)
  readonly property var currentProtection: Model.strongestEvidence(evidence(), config)
  readonly property string contextLabel: typingHoldActive ? "Active"
    : currentProtection ? Model.contextShortLabel(currentProtection.category) : ""
  readonly property string phase: snapshot.state || Model.State.Working
  readonly property bool plannedActive: !!snapshot.activePlannedOccurrence
  readonly property bool plannedReady: phase === Model.State.PlannedReady
  readonly property bool plannedDeferred: plannedActive && !plannedReady
    && snapshot.activePlannedOccurrence.deferred === true
  readonly property string plannedName: plannedActive
    ? String(snapshot.activePlannedOccurrence.name || qsTr("Planned break")) : ""
  readonly property string label: steamPauseActive ? "Paused during a Steam game"
    : idlePauseActive ? "Paused while you’re away" : Model.stateLabel(snapshot)
  readonly property string remainingText: Model.formatDuration(remainingMs)
  readonly property string naturalBreakMessage: Model.naturalBreakMessage(snapshot)
  readonly property bool naturalBreakUndoAvailable: snapshot.naturalBreakDecision
    && Date.now() <= Number(snapshot.naturalBreakDecision.undoUntilMs || 0)
  readonly property bool naturalBreakToastVisible: snapshot.naturalBreakDecision
    && Date.now() - Number(snapshot.naturalBreakDecision.decidedAtMs || 0) <= 6000
  readonly property real progress: {
    if (phase === Model.State.Breaking) {
      var duration = Number(snapshot.activeBreakDurationMs || config.breakMs)
      return duration > 0 ? 1 - remainingMs / duration : 1
    }
    return config.focusMs > 0 ? Math.max(0, Math.min(1, Number(snapshot.accumulatedActiveMs || 0) / config.focusMs)) : 0
  }
  readonly property string protectedSummary: phase === Model.State.Protected
    ? Model.protectedExplanation(snapshot.protectedCategory)
    : ""
  readonly property bool interrupting: phase === Model.State.Warning || phase === Model.State.Final
    || phase === Model.State.Breaking || phase === Model.State.PlannedReady
  readonly property bool canPostpone: Model.canPostpone(snapshot, config)
  readonly property bool canSkipBreak: (phase === Model.State.Breaking || phase === Model.State.PlannedReady)
    && Model.canSkipBreak(config, snapshot)
  readonly property bool nextBreakIsLong: Model.isNextBreakLong(snapshot, config)
  readonly property bool soundAvailable: startSoundAvailable && completionSoundAvailable
  readonly property string soundVolumeDb: {
    var level = Math.max(0, Math.min(100, Number(config.soundVolume || 0)))
    if (level <= 0) return "-10000.0"
    return (20 * Math.log(level / 100) / Math.LN10).toFixed(1)
  }
  readonly property string startSoundPath: resolvedSoundPath(config.startSoundPath, Qt.resolvedUrl("assets/sounds/break-start.ogg"))
  readonly property string completionSoundPath: resolvedSoundPath(config.completionSoundPath, Qt.resolvedUrl("assets/sounds/break-complete.ogg"))
  readonly property int remainingMs: {
    var now = Date.now()
    if (phase === Model.State.Breaking) return Math.max(0, Number(snapshot.breakEndsAtMs || 0) - now)
    if (phase === Model.State.Warning || phase === Model.State.Final) return Math.max(0, Number(snapshot.warningEndsAtMs || 0) - now)
    if (phase === Model.State.Waiting && snapshot.postponedUntilMs > now) return snapshot.postponedUntilMs - now
    if (snapshot.activePlannedOccurrence) {
      var untilStart = Number(snapshot.activePlannedOccurrence.scheduledAtMs || 0) - now
      if (untilStart > 0) return untilStart
      return Math.max(0, Number(snapshot.activePlannedOccurrence.durationMs || 0)
        - Model.plannedAwayCredit(snapshot, now))
    }
    return Math.max(0, config.focusMs - Number(snapshot.accumulatedActiveMs || 0))
  }

  function evidence() {
    if (demoMode) return demoEvidence
    var value = []
    if (dictationActive) value.push({ category: "dictation", confidence: 1, active: true })
    for (var i = 0; i < pipewireEvidence.length; i++) {
      var item = pipewireEvidence[i]
      value.push(item.category === "microphone" && fullscreenActive
        ? { category: "meeting", confidence: 0.9, active: true } : item)
    }
    var browserEvidence = config.detectors.media
      ? Model.browserContextEvidence(browserContextConnected ? browserContext : null) : null
    if (browserEvidence) value.push(browserEvidence)
    if (steamPauseActive) value.push({ category: "game", confidence: 1, active: true })
    if (mediaActive) value.push({ category: "media", confidence: 0.8, active: true })
    if (Model.matchesProtectedApp(activeAppId, config.protectedApps))
      value.push({ category: "application", confidence: 1, active: true })
    if (fullscreenActive) value.push({ category: "fullscreen", confidence: 0.65, active: true })
    return value
  }

  function acceptBrowserContext(line) {
    try {
      if (String(line).length > 16384) throw new Error("message exceeds 16 KiB")
      var value = JSON.parse(line)
      var session = String(value.session_id || "")
      var sequence = Number(value.sequence || 0)
      if (value.version !== 1 || value.browser !== "chromium"
          || session.length < 1 || session.length > 64
          || !isFinite(sequence) || Math.floor(sequence) !== sequence || sequence < 1
          || ["none", "paused", "buffering", "playing"].indexOf(value.video_state) < 0
          || typeof value.browser_focused !== "boolean"
          || typeof value.video_visible !== "boolean"
          || typeof value.picture_in_picture !== "boolean") throw new Error("invalid context")
      if (session === browserContextSessionId && sequence <= browserContextSequence) return
      browserContextSessionId = session
      browserContextSequence = sequence
      browserContext = value
      browserContextReceivedAtMs = Date.now()
      browserContextSeen = true
      browserContextConnected = true
    } catch (error) {
      console.warn("LookElsewhere rejected browser context: " + error)
    }
  }

  function acceptSundownStatus(raw) {
    var status = Model.parseSundownStatus(raw)
    if (!status) {
      sundownConnected = false
      sundownSteamActive = false
      sundownSteamSensor = ""
      console.warn("LookElsewhere rejected Sundown status")
      return
    }
    sundownSeen = true
    sundownConnected = true
    sundownSteamActive = status.active
    sundownSteamSensor = status.sensor
    sundownExpiry.restart()
  }

  function observe() {
    var startedAtMs = Date.now()
    if (lastObserveStartedAtMs > 0) {
      lastObserveGapMs = Math.max(0, startedAtMs - lastObserveStartedAtMs)
      if (lastObserveGapMs > maximumObserveGapMs) {
        maximumObserveGapMs = lastObserveGapMs
        if (lastObserveGapMs >= 1500)
          console.warn("LookElsewhere scheduler tick delayed by " + lastObserveGapMs + " ms")
      }
    }
    lastObserveStartedAtMs = startedAtMs
    var beforeState = snapshot.state
    var beforeDecision = JSON.stringify(snapshot.naturalBreakDecision || null)
    var effectiveIdle = config.detectors.idle && idle
    snapshot = Model.observe(snapshot, {
      nowMs: Date.now(),
      active: !effectiveIdle,
      idle: effectiveIdle,
      accumulationPaused: steamPauseActive,
      naturalPause: naturalPauseReady,
      typingActive: typingHoldActive,
      evidence: evidence()
    }, config)
    playTransitionSound(beforeState, snapshot.state)
    if (!demoMode && (snapshot.state !== beforeState
        || JSON.stringify(snapshot.naturalBreakDecision || null) !== beforeDecision)) scheduleSave()
    lastObserveDurationMs = Math.max(0, Date.now() - startedAtMs)
    if (lastObserveDurationMs > maximumObserveDurationMs) {
      maximumObserveDurationMs = lastObserveDurationMs
      if (lastObserveDurationMs >= 50)
        console.warn("LookElsewhere scheduler update took " + lastObserveDurationMs + " ms")
    }
  }

  onActiveToplevelChanged: {
    activeWindowGeneration++
    probedActiveAppId = ""
    probedFullscreenActive = false
    probedActiveWindowAvailable = false
    activeWindowRefresh.restart()
  }

  onActivePipewireNodeIdsChanged: {
    pipewireEvidenceGeneration++
    pipewireEvidenceRecords = []
    pipewireEvidenceProbe.retryCount = 0
    pipewireEvidenceRefresh.restart()
  }

  function configure(values) {
    var authoritative = Model.configFromSettings(values)
    if (demoMode) preDemoConfig = authoritative
    config = authoritative
  }

  function takeBreak() {
    var beforeState = snapshot.state
    snapshot = snapshot.activePlannedOccurrence
      ? Model.startPlannedBreak(snapshot, Date.now(), config)
      : Model.startBreak(snapshot, Date.now(), config)
    playTransitionSound(beforeState, snapshot.state)
    scheduleSave()
  }

  function postponeMinutes(minutes) {
    if (!canPostpone) return
    snapshot = Model.postpone(snapshot, Date.now(), Math.max(1, Number(minutes || 1)) * 60000, config)
    scheduleSave()
  }

  function delayNextBreakMinutes(minutes) {
    if (!canPostpone) return
    snapshot = Model.delayNextBreak(snapshot, Date.now(), Math.max(1, Number(minutes || 1)) * 60000, config)
    scheduleSave()
  }

  function resetHistory() {
    snapshot = Model.resetTotals(snapshot)
    scheduleSave()
  }

  function undoNaturalBreak() {
    snapshot = Model.undoNaturalBreak(snapshot, Date.now())
    scheduleSave()
  }

  function pauseMinutes(minutes) {
    snapshot = Model.pause(snapshot, Date.now(), Math.max(1, Number(minutes || 60)) * 60000)
    scheduleSave()
  }

  function pauseBreaks() {
    snapshot = Model.pause(snapshot, Date.now(), 0)
    scheduleSave()
  }

  function resume() {
    snapshot = Model.resume(snapshot, Date.now())
    scheduleSave()
  }

  function togglePause() {
    // A convenience binding must not become an alternate enforcement exit.
    if (!Model.canTogglePause(phase)) return
    if (phase === Model.State.Waiting && snapshot.pauseReason === "manual") resume()
    else pauseBreaks()
  }

  function skipBreak() {
    if (!canSkipBreak) return
    var beforeState = snapshot.state
    snapshot = Model.skipBreak(snapshot, Date.now(), config)
    playTransitionSound(beforeState, snapshot.state)
    scheduleSave()
  }

  function playTransitionSound(beforeState, afterState) {
    var cue = Model.soundCueForTransition(beforeState, afterState)
    if (cue === "start") completionCuePlayed = false
    if (demoMode || !config.soundEnabled) return
    if (cue === "start" && config.startSoundEnabled && !breakStartSound.running) breakStartSound.running = true
    else if (cue === "complete") playCompletionCue()
  }

  function playCompletionCue() {
    if (completionCuePlayed || demoMode || !config.soundEnabled || !config.completionSoundEnabled) return
    completionCuePlayed = true
    if (!breakCompletionSound.running) breakCompletionSound.running = true
  }

  function resolvedSoundPath(configuredPath, bundledUrl) {
    var value = String(configuredPath || "").trim()
    if (!value) value = String(bundledUrl)
    if (value.indexOf("~/") === 0) value = Quickshell.env("HOME") + value.substring(1)
    if (value.indexOf("file://") === 0) value = decodeURIComponent(value.substring(7))
    return value
  }

  function setDemo(name) {
    if (!demoMode) {
      // A plugin rescan can reconstruct this service while a fixture is open.
      // Persist the real snapshot first so the replacement service recovers
      // the user's schedule rather than an older periodic checkpoint.
      flushState()
      preDemoSnapshot = JSON.parse(JSON.stringify(snapshot))
      preDemoConfig = JSON.parse(JSON.stringify(config))
      preDemoRecoveryWarning = recoveryWarning
      preDemoPersistenceBlocked = persistenceBlocked
    } else if (preDemoConfig) {
      // Fixtures may temporarily alter timing or enforcement. Always derive
      // the next fixture from the real configuration so states cannot bleed.
      config = JSON.parse(JSON.stringify(preDemoConfig))
    }
    demoFixture = name
    demoSequenceIndex = demoSequence.indexOf(name)
    demoMode = true
    demoIdle = false
    demoNaturalPause = true
    demoTypingProbe = false
    demoGame = false
    demoEvidence = []
    recoveryWarning = ""
    persistenceBlocked = false
    var now = Date.now()
    var next = Model.defaultSnapshot(now)
    if (name === "working") next.accumulatedActiveMs = config.focusMs * 0.35
    else if (name === "idle") {
      next.accumulatedActiveMs = config.focusMs * 0.35
      demoIdle = true
    } else if (name === "flow") {
      var flowConfig = JSON.parse(JSON.stringify(config))
      // Keep every observable phase wide enough for the installed-shell
      // reliability harness to sample even during a brief compositor stall.
      flowConfig.warningMs = 6000
      flowConfig.finalMs = 3000
      flowConfig.breakMs = 4000
      config = Model.normalizeConfig(flowConfig)
      demoNaturalPause = false
      next = Model.startWarning(next, now, config, config.warningMs)
    }
    else if (name === "typing") {
      var typingConfig = JSON.parse(JSON.stringify(config))
      typingConfig.warningMs = 12000
      typingConfig.finalMs = 3000
      typingConfig.maximumDelayMs = 30000
      config = Model.normalizeConfig(typingConfig)
      demoTypingProbe = true
      next = Model.startWarning(next, now, config, 12000)
    }
    else if (name === "game") {
      next.accumulatedActiveMs = config.focusMs * 0.35
      demoGame = true
      demoEvidence = [{ category: "game", confidence: 1, active: true }]
    }
    else if (name === "due") next.accumulatedActiveMs = config.focusMs - 30000
    else if (name === "stats") {
      next.statistics.today.activeMs = 5 * 60 * 60 * 1000 + 24 * 60 * 1000
      next.statistics.today.completed = 8
      next.statistics.today.skipped = 1
      next.statistics.today.snoozed = 2
      next.statistics.today.shortBreaks = 7
      next.statistics.today.longBreaks = 1
      next.statistics.today.longestSessionMs = 42 * 60 * 1000
      next.statistics.today.sessionDurationsMs = [18, 24, 42, 16].map(function(minutes) { return minutes * 60000 })
      next.statistics.today.sessions = [
        { endedAtMs: now - 12 * 60000, durationMs: 18 * 60000, outcome: "break" },
        { endedAtMs: now - 58 * 60000, durationMs: 24 * 60000, outcome: "long-break" },
        { endedAtMs: now - 2 * 60 * 60000, durationMs: 42 * 60000, outcome: "away" }
      ]
      next.statistics.currentSessionActiveMs = 11 * 60000
      for (var dayOffset = 1; dayOffset <= 3; dayOffset++) {
        var day = Model.defaultStatisticDay(Model.localDayKey(now - dayOffset * 24 * 60 * 60000))
        day.activeMs = (4 + dayOffset / 2) * 60 * 60 * 1000
        day.completed = 9 - dayOffset
        next.statistics.days.push(day)
      }
    }
    else if (name === "long-break") {
      next.breaksSinceLong = Math.max(0, config.longBreakEvery - 1)
      next = Model.startBreak(next, now, config)
    }
    else if (name === "paused") {
      next.state = Model.State.Waiting
      next.pauseReason = "manual"
      next.postponedUntilMs = now + 60 * 60000
    } else if (name === "postponed") {
      next.state = Model.State.Waiting
      next.postponedUntilMs = now + 5 * 60000
      next.snoozesUsed = 1
    }
    else if (["protected", "meeting", "microphone", "camera", "screen-sharing",
              "video", "media", "fullscreen", "dictation"].indexOf(name) >= 0) {
      next.accumulatedActiveMs = config.focusMs
      next.dueAtMs = now
      demoEvidence = [{
        category: name === "protected" ? "meeting" : name,
        confidence: 0.95,
        active: true
      }]
    } else if (name === "warning" || name === "final") {
      next = Model.startWarning(next, now, config)
      if (name === "final") next.warningEndsAtMs = now + config.finalMs
    } else if (["planned-warning", "planned-ready", "planned-break"].indexOf(name) >= 0) {
      var plannedAt = name === "planned-warning" ? now + 30000 : now - 60000
      next = Model.beginPlannedOccurrence(next, {
        key: "demo-lunch@demo", routineId: "demo-lunch", name: "Lunch",
        scheduledAtMs: plannedAt, durationMs: 30 * 60000,
        expiresAtMs: now + 60 * 60000
      }, now, config)
      if (name === "planned-warning") next = Model.startWarning(next, now, config, 30000)
      else {
        next.activePlannedOccurrence.deferred = true
        next.state = Model.State.PlannedReady
        if (name === "planned-break") next = Model.startPlannedBreak(next, now, config)
      }
    } else if (["break", "casual-break", "balanced-break", "hardcore-break", "gentle-break", "focused-break"].indexOf(name) >= 0) {
      if (name !== "break") {
        var demoConfig = JSON.parse(JSON.stringify(config))
        var demoEnforcement = name.replace("-break", "")
        demoConfig.enforcement = demoEnforcement === "gentle" ? "casual"
          : demoEnforcement === "focused" ? "hardcore" : demoEnforcement
        config = Model.normalizeConfig(demoConfig)
      }
      next = Model.startBreak(next, now, config)
    } else if (name === "recovery") {
      recoveryWarning = "Saved state could not be read. The original file has been preserved."
      persistenceBlocked = true
    }
    snapshot = next
    observe()
  }

  function advanceDemo() {
    var nextIndex = demoSequenceIndex + 1
    if (nextIndex >= demoSequence.length) {
      clearDemo()
      return "off"
    }
    setDemo(demoSequence[nextIndex])
    return demoFixture
  }

  function clearDemo() {
    demoMode = false
    demoIdle = false
    demoNaturalPause = true
    demoTypingProbe = false
    demoGame = false
    demoEvidence = []
    snapshot = preDemoSnapshot || Model.defaultSnapshot(Date.now())
    config = preDemoConfig || config
    recoveryWarning = preDemoRecoveryWarning
    persistenceBlocked = preDemoPersistenceBlocked
    snapshot.lastObservedAtMs = Date.now()
    preDemoSnapshot = null
    preDemoConfig = null
    preDemoRecoveryWarning = ""
    preDemoPersistenceBlocked = false
    demoSequenceIndex = -1
    demoFixture = ""
  }

  function scheduleSave() {
    if (stateLoaded && !demoMode) saveTimer.restart()
  }

  function loadState(raw) {
    if (stateLoaded) return
    try {
      var parsed = raw ? JSON.parse(raw) : null
      if (parsed && Number(parsed.version || 0) !== 1) throw new Error("unsupported state version")
      if (parsed && !parsed.snapshot) throw new Error("state snapshot is missing")
      if (parsed && parsed.snapshot) {
        var recovered = Model.recoverSnapshot(parsed.snapshot, Date.now())
        if (!recovered) throw new Error("state timestamps are outside the recovery window")
        snapshot = recovered
      }
      // State files written before 0.1 may contain `config`. Ignore it:
      // Omarchy's shell.json entry is the sole configuration authority.
    } catch (error) {
      console.warn("look-elsewhere: state parse failed:", error)
      recoveryWarning = "Saved state could not be read. The original file has been preserved."
      persistenceBlocked = true
      snapshot = Model.defaultSnapshot(Date.now())
    }
    snapshot.lastObservedAtMs = Date.now()
    stateLoaded = true
  }

  function blockStateLoad(message) {
    recoveryWarning = message
    persistenceBlocked = true
    snapshot = Model.defaultSnapshot(Date.now())
    stateLoaded = true
  }

  function flushState() {
    if (persistenceBlocked || demoMode) return
    stateFile.setText(JSON.stringify({ version: 1, snapshot: snapshot }, null, 2) + "\n")
  }

  function resetLocalData() {
    snapshot = Model.defaultSnapshot(Date.now())
    recoveryWarning = ""
    persistenceBlocked = false
    flushState()
  }

  IdleMonitor {
    id: idleMonitor
    enabled: true
    timeout: 60
    respectInhibitors: true
  }

  // Link state is invalid until Quickshell tracks the link group. Tracking
  // groups does not materialize the application-controlled node dictionaries.
  PwObjectTracker {
    objects: service.pipewireLinkGroups
  }

  SocketServer {
    active: service.browserSocketPath.indexOf("/") === 0
    path: service.browserSocketPath
    handler: Socket {
      parser: SplitParser {
        onRead: function(line) { service.acceptBrowserContext(line) }
      }
    }
  }

  // Sundown owns this root-written, atomic, public status file. Watching it
  // avoids duplicating its /proc scanner or spawning a process every second.
  FileView {
    id: sundownStatusFile
    path: service.sundownStatusPath
    watchChanges: true
    printErrors: false
    onLoaded: service.acceptSundownStatus(text())
    onFileChanged: reload()
    onLoadFailed: {
      service.sundownConnected = false
      service.sundownSteamActive = false
      service.sundownSteamSensor = ""
    }
  }

  Timer {
    id: sundownExpiry
    interval: 5000
    onTriggered: {
      service.sundownConnected = false
      service.sundownSteamActive = false
      service.sundownSteamSensor = ""
    }
  }

  Timer {
    interval: 2000
    repeat: true
    running: true
    onTriggered: {
      if (service.browserContextConnected
          && Date.now() - service.browserContextReceivedAtMs > 12000) {
        service.browserContextConnected = false
        service.browserContext = ({})
      }
    }
  }

  // Quickshell's Wayland toplevel handle has no appId for XWayland games.
  // Reconcile once per focus change instead of polling continuously.
  Timer {
    id: activeWindowRefresh
    interval: 120
    repeat: false
    onTriggered: {
      if (activeWindowProbe.running) activeWindowRefresh.restart()
      else {
        activeWindowProbe.generation = service.activeWindowGeneration
        activeWindowProbe.running = true
      }
    }
  }

  Process {
    id: activeWindowProbe
    property int generation: 0
    // Bound and shape compositor output before it enters the long-lived QML
    // process. Window titles and every other unused field are dropped.
    command: ["bash", "-c", "LC_ALL=C; payload=$(hyprctl activewindow -j | head -c 65537); [ ${#payload} -le 65536 ] || exit 65; printf '%s' \"$payload\" | jq -c '{class: ((.class // .initialClass // \"\") | tostring | .[0:256]), fullscreen: ((.fullscreen // 0) != 0)}'", "lookelsewhere-active-window"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (activeWindowProbe.generation !== service.activeWindowGeneration) return
        try {
          var active = JSON.parse(text || "{}")
          service.probedActiveAppId = String(active.class || "")
          service.probedFullscreenActive = active.fullscreen === true
          service.probedActiveWindowAvailable = service.probedActiveAppId !== ""
        } catch (error) {
          service.probedActiveAppId = ""
          service.probedFullscreenActive = false
          service.probedActiveWindowAvailable = false
        }
      }
    }
  }

  // PipeWire node dictionaries are application-controlled and may contain
  // private titles or arbitrarily large values. The helper reads only active
  // numeric node IDs and emits a small allowlisted record for QML.
  Timer {
    id: pipewireEvidenceRefresh
    interval: 120
    repeat: false
    onTriggered: {
      if (pipewireEvidenceProbe.running) {
        pipewireEvidenceRefresh.restart()
      } else if (service.activePipewireNodeIds.length === 0) {
        service.pipewireEvidenceRecords = []
      } else {
        pipewireEvidenceProbe.generation = service.pipewireEvidenceGeneration
        pipewireEvidenceProbe.timedOut = false
        pipewireEvidenceProbe.command = [service.pipewireEvidencePath].concat(
          service.activePipewireNodeIds.map(function(id) { return String(id) }))
        pipewireEvidenceProbe.running = true
      }
    }
  }

  Process {
    id: pipewireEvidenceProbe
    property int generation: 0
    property int retryCount: 0
    property bool timedOut: false
    stdout: StdioCollector {
      id: pipewireEvidenceOutput
      waitForEnd: true
    }
    onExited: function(exitCode) {
      var didTimeOut = timedOut
      timedOut = false
      if (generation !== service.pipewireEvidenceGeneration) {
        pipewireEvidenceRefresh.restart()
        return
      }
      if (didTimeOut || exitCode !== 0) {
        service.pipewireEvidenceRecords = []
        if (retryCount < 1) {
          retryCount++
          pipewireEvidenceRefresh.restart()
        }
        return
      }
      try {
        var parsed = JSON.parse(pipewireEvidenceOutput.text || "[]")
        if (!Array.isArray(parsed) || parsed.length > 32) throw new Error("invalid PipeWire evidence")
        service.pipewireEvidenceRecords = parsed
        retryCount = 0
      } catch (error) {
        service.pipewireEvidenceRecords = []
        if (retryCount < 1) {
          retryCount++
          pipewireEvidenceRefresh.restart()
        }
      }
    }
  }

  Timer {
    interval: 2000
    running: pipewireEvidenceProbe.running
    onTriggered: {
      pipewireEvidenceProbe.timedOut = true
      pipewireEvidenceProbe.signal(9)
    }
  }

  // Five quiet seconds is long enough to avoid interrupting an active input
  // burst while remaining imperceptible when the user has naturally paused.
  // Inhibitors are deliberately ignored: media/fullscreen policy is handled
  // by Smart Context, while this monitor answers only whether input is quiet.
  IdleMonitor {
    id: naturalPauseMonitor
    enabled: service.stateLoaded && !service.demoMode
    timeout: 5
    respectInhibitors: false
  }

  // Wayland deliberately does not expose other apps' keystrokes. A short
  // idle-notify window detects recent keyboard or pointer work without
  // reading or storing input content.
  IdleMonitor {
    id: typingPauseMonitor
    enabled: service.config.detectors.recentInput && service.stateLoaded
      && (!service.demoMode || service.demoTypingProbe)
      && (service.phase === Model.State.Warning || service.phase === Model.State.Final)
      && service.remainingMs <= 11000
    timeout: service.typingQuietSeconds
    respectInhibitors: false
  }

  Process {
    id: ensureStateDir
    property bool timedOut: false
    command: ["bash", "-c",
      "set -e; [[ ! -L $1 ]]; umask 077; exec install -d -m 700 -- \"$1\"",
      "lookelsewhere-state-dir", service.stateDir]
    onExited: function(exitCode) {
      if (ensureStateDir.timedOut) {
        ensureStateDir.timedOut = false
        service.recoveryWarning = "Local state storage did not respond in time. Changes will not be saved."
        service.persistenceBlocked = true
        service.stateLoaded = true
      } else if (exitCode === 0) {
        service.stateStorageReady = true
        stateLoader.running = true
      } else {
        service.recoveryWarning = "Local state storage could not be prepared. Changes will not be saved."
        service.persistenceBlocked = true
        service.stateLoaded = true
      }
    }
  }

  Timer {
    interval: 5000
    running: ensureStateDir.running
    onTriggered: {
      ensureStateDir.timedOut = true
      ensureStateDir.signal(9)
    }
  }

  Process {
    id: stateLoader
    property bool timedOut: false
    command: [service.boundedReaderPath, "--max-bytes",
      String(service.stateReadLimit), service.statePath]
    stdout: StdioCollector {
      id: stateReaderOutput
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (stateLoader.timedOut) {
        stateLoader.timedOut = false
        service.blockStateLoad("Saved state did not respond in time. The original file has been preserved.")
      } else if (exitCode === 0) {
        service.loadState(stateReaderOutput.text)
      } else if (exitCode === 65) {
        service.blockStateLoad("Saved state is too large to read safely. The original file has been preserved.")
      } else if (exitCode === 66 || exitCode === 67) {
        service.blockStateLoad("Saved state is not a regular file owned by this user. The original path has been preserved.")
      } else {
        service.blockStateLoad("Saved state could not be read safely. The original file has been preserved.")
      }
    }
  }

  Timer {
    interval: 5000
    running: stateLoader.running
    onTriggered: {
      stateLoader.timedOut = true
      stateLoader.signal(9)
    }
  }

  FileView {
    id: stateFile
    path: service.stateStorageReady ? service.statePath : ""
    blockAllReads: true
    watchChanges: false
    atomicWrites: true
    printErrors: false
  }

  Timer {
    id: saveTimer
    interval: 250
    repeat: false
    onTriggered: service.flushState()
  }

  Timer {
    interval: 1000
    repeat: true
    running: service.stateLoaded
    triggeredOnStart: true
    onTriggered: service.observe()
  }

  Timer {
    interval: 10
    repeat: true
    running: service.stateLoaded && !service.demoMode
      && service.phase === Model.State.Breaking && !service.completionCuePlayed
    onTriggered: {
      if (Model.shouldLeadCompletionCue(service.phase, service.remainingMs, 25))
        service.playCompletionCue()
    }
  }

  Timer {
    // Quickshell has no shutdown callback reliable enough to flush during a
    // shell restart, so keep any visible countdown rollback below five seconds.
    interval: 5000
    repeat: true
    running: service.stateLoaded && !service.demoMode
    onTriggered: service.flushState()
  }

  Process {
    id: dictationProbe
    command: ["omarchy-voxtype-status"]
    running: service.config.detectors.dictation && !service.demoMode
    onRunningChanged: if (!running) service.dictationActive = false
    stdout: SplitParser {
      onRead: function(data) {
        try {
          var value = JSON.parse(String(data || "{}"))
          var state = String(value.alt || value.class || "").toLowerCase()
          service.dictationAvailable = state !== ""
          service.dictationActive = state === "recording" || state === "transcribing"
        } catch (error) {
          service.dictationActive = false
          service.dictationAvailable = false
        }
      }
    }
    onExited: function(exitCode) {
      if (service.config.detectors.dictation && !service.demoMode) {
        service.dictationActive = false
        service.dictationAvailable = false
      }
    }
  }

  Process {
    id: breakStartSound
    command: ["canberra-gtk-play", "-f", service.startSoundPath, "-V", service.soundVolumeDb, "-d", "LookElsewhere break started"]
    onExited: function(exitCode) { service.startSoundAvailable = exitCode === 0 }
  }

  Process {
    id: breakCompletionSound
    command: ["canberra-gtk-play", "-f", service.completionSoundPath, "-V", service.soundVolumeDb, "-d", "LookElsewhere break complete"]
    onExited: function(exitCode) { service.completionSoundAvailable = exitCode === 0 }
  }

  Component.onCompleted: {
    ensureStateDir.running = true
    activeWindowRefresh.start()
    pipewireEvidenceRefresh.start()
  }

  IpcHandler {
    target: "look-elsewhere"

    function status(): string { return JSON.stringify({ state: service.phase, remainingMs: service.remainingMs, evidence: service.evidence(), demo: service.demoMode, idlePaused: service.idlePauseActive, steamPaused: service.steamPauseActive, naturalPauseReady: service.naturalPauseReady, typingHoldActive: service.typingHoldActive, contextLabel: service.contextLabel, browserIntegration: service.browserIntegrationStatus, sundownIntegration: service.sundownIntegrationStatus, naturalBreakDecision: service.snapshot.naturalBreakDecision || null, recoveryWarning: service.recoveryWarning }) }
    function configuration(): string { return JSON.stringify(service.config) }
    function diagnostics(): string { return JSON.stringify({ fullscreen: service.fullscreenAvailable, dictation: service.dictationAvailable, mpris: true, pipewire: true, pipewireActiveStreams: service.activePipewireNodeIds.length, pipewireEvidenceRecords: service.pipewireEvidenceRecords.length, browserIntegration: service.browserIntegrationStatus, sundownIntegration: service.sundownIntegrationStatus, sundownSteamSensor: service.sundownSteamSensor, steamGameActive: service.sundownSteamActive, steamPauseActive: service.steamPauseActive, idle: true, sound: service.soundAvailable, persistenceBlocked: service.persistenceBlocked, schedulerLastGapMs: service.lastObserveGapMs, schedulerMaximumGapMs: service.maximumObserveGapMs, schedulerLastDurationMs: service.lastObserveDurationMs, schedulerMaximumDurationMs: service.maximumObserveDurationMs }) }
    function takeBreak(): string { service.takeBreak(); return service.phase }
    function postpone(minutes: int): string { service.postponeMinutes(minutes); return service.phase }
    function pause(minutes: int): string { service.pauseMinutes(minutes); return service.phase }
    function pauseBreaks(): string { service.pauseBreaks(); return service.phase }
    function togglePause(): string { service.togglePause(); return service.phase }
    function resume(): string { service.resume(); return service.phase }
    function skip(): string { service.skipBreak(); return service.phase }
    function resetHistory(): string { service.resetHistory(); return "ok" }
    function undoNaturalBreak(): string { service.undoNaturalBreak(); return service.phase }
    function resetLocalData(): string { service.resetLocalData(); return "ok" }
    function demo(state: string): string { service.setDemo(state); return service.phase }
    function demoNext(): string { return service.advanceDemo() }
    function demoOff(): string { service.clearDemo(); return service.phase }
  }
}
