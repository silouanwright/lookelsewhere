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
  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/look-elsewhere"
  readonly property string statePath: stateDir + "/state.json"

  property var config: Model.defaultConfig()
  property var snapshot: Model.defaultSnapshot(Date.now())
  property bool stateStorageReady: false
  property bool stateLoaded: false
  property bool dictationActive: false
  property bool dictationAvailable: false
  property bool startSoundAvailable: true
  property bool completionSoundAvailable: true
  property bool completionCuePlayed: false
  property string recoveryWarning: ""
  property bool persistenceBlocked: false
  property bool demoMode: false
  property bool demoIdle: false
  property bool demoNaturalPause: true
  property var demoEvidence: []
  property var preDemoSnapshot: null
  property var preDemoConfig: null
  property string preDemoRecoveryWarning: ""
  property bool preDemoPersistenceBlocked: false

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var pipewireNodes: Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property var activeToplevel: Hyprland.activeToplevel
  readonly property bool fullscreenAvailable: !activeToplevel || !!activeToplevel.wayland
  readonly property bool fullscreenActive: config.detectors.fullscreen
    && !!(activeToplevel && activeToplevel.wayland && activeToplevel.wayland.fullscreen)
  readonly property bool mediaActive: {
    for (var i = 0; i < players.length; i++)
      if (players[i] && players[i].isPlaying) return true
    return false
  }
  readonly property bool microphoneActive: {
    var source = Pipewire.defaultAudioSource
    if (!source || !source.audio || source.audio.muted) return false
    for (var i = 0; i < pipewireNodes.length; i++) {
      var node = pipewireNodes[i]
      if (node && node.isStream && node.isSink === false && node.audio && !node.audio.muted) return true
    }
    return false
  }
  readonly property bool idle: demoMode ? demoIdle : idleMonitor.isIdle
  readonly property bool naturalPauseReady: demoMode ? demoNaturalPause : naturalPauseMonitor.isIdle
  readonly property bool idlePauseActive: config.detectors.idle && idle
  readonly property string phase: snapshot.state || Model.State.Working
  readonly property string label: idlePauseActive ? "Paused while you’re away" : Model.stateLabel(snapshot)
  readonly property string remainingText: Model.formatDuration(remainingMs)
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
  readonly property bool interrupting: phase === Model.State.Warning || phase === Model.State.Final || phase === Model.State.Breaking
  readonly property bool canPostpone: Model.canPostpone(snapshot, config)
  readonly property bool canSkipBreak: phase === Model.State.Breaking && Model.canSkipBreak(config)
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
    return Math.max(0, config.focusMs - Number(snapshot.accumulatedActiveMs || 0))
  }

  function evidence() {
    if (demoMode) return demoEvidence
    var value = []
    if (dictationActive) value.push({ category: "dictation", confidence: 1, active: true })
    if (microphoneActive && fullscreenActive) value.push({ category: "meeting", confidence: 0.9, active: true })
    else if (microphoneActive) value.push({ category: "microphone", confidence: 0.75, active: true })
    if (mediaActive) value.push({ category: "media", confidence: 0.8, active: true })
    if (fullscreenActive) value.push({ category: "fullscreen", confidence: 0.65, active: true })
    return value
  }

  function observe() {
    var beforeState = snapshot.state
    var effectiveIdle = config.detectors.idle && idle
    snapshot = Model.observe(snapshot, {
      nowMs: Date.now(),
      active: !effectiveIdle,
      idle: effectiveIdle,
      naturalPause: naturalPauseReady,
      evidence: evidence()
    }, config)
    playTransitionSound(beforeState, snapshot.state)
    if (!demoMode && snapshot.state !== beforeState) scheduleSave()
  }

  function configure(values) {
    var authoritative = Model.configFromSettings(values)
    if (demoMode) preDemoConfig = authoritative
    config = authoritative
  }

  function takeBreak() {
    var beforeState = snapshot.state
    snapshot = Model.startBreak(snapshot, Date.now(), config)
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

  function pauseMinutes(minutes) {
    var next = JSON.parse(JSON.stringify(snapshot))
    next.state = Model.State.Waiting
    next.pauseReason = "manual"
    next.postponedUntilMs = Date.now() + Math.max(1, Number(minutes || 60)) * 60000
    snapshot = next
    scheduleSave()
  }

  function pauseBreaks() {
    var next = JSON.parse(JSON.stringify(snapshot))
    next.state = Model.State.Waiting
    next.pauseReason = "manual"
    next.postponedUntilMs = 0
    next.lastObservedAtMs = Date.now()
    snapshot = next
    scheduleSave()
  }

  function resume() {
    var next = JSON.parse(JSON.stringify(snapshot))
    next.state = Model.State.Working
    next.pauseReason = ""
    next.postponedUntilMs = 0
    next.lastObservedAtMs = Date.now()
    snapshot = next
    scheduleSave()
  }

  function togglePause() {
    // A convenience binding must not become an alternate enforcement exit.
    if (interrupting) return
    if (phase === Model.State.Waiting && snapshot.pauseReason === "manual") resume()
    else pauseBreaks()
  }

  function skipBreak() {
    if (!canSkipBreak) return
    var beforeState = snapshot.state
    var next = Model.completeBreak(snapshot, Date.now())
    next.totals.completed = Math.max(0, next.totals.completed - 1)
    next.totals.skipped++
    snapshot = next
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
    }
    demoMode = true
    demoIdle = false
    demoNaturalPause = true
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
      flowConfig.warningMs = 8000
      flowConfig.finalMs = 3000
      flowConfig.breakMs = 10000
      config = Model.normalizeConfig(flowConfig)
      next.accumulatedActiveMs = config.focusMs
    }
    else if (name === "due") next.accumulatedActiveMs = config.focusMs - 30000
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
    else if (name === "protected") {
      next.accumulatedActiveMs = config.focusMs
      next.dueAtMs = now
      demoEvidence = [{ category: "meeting", confidence: 0.95, active: true }]
    } else if (name === "warning" || name === "final") {
      next = Model.startWarning(next, now, config)
      if (name === "final") next.warningEndsAtMs = now + config.finalMs
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

  function clearDemo() {
    demoMode = false
    demoIdle = false
    demoNaturalPause = true
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
      if (parsed && parsed.snapshot) snapshot = parsed.snapshot
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

  PwObjectTracker {
    objects: Pipewire.defaultAudioSource ? [Pipewire.defaultAudioSource] : []
  }

  IdleMonitor {
    id: idleMonitor
    enabled: true
    timeout: 60
    respectInhibitors: true
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

  Process {
    id: ensureStateDir
    command: ["mkdir", "-p", service.stateDir]
    onExited: function(exitCode) {
      if (exitCode === 0) {
        service.stateStorageReady = true
        Qt.callLater(function() { stateFile.reload() })
      } else {
        service.recoveryWarning = "Local state storage could not be prepared. Changes will not be saved."
        service.persistenceBlocked = true
        service.stateLoaded = true
      }
    }
  }

  FileView {
    id: stateFile
    path: service.stateStorageReady ? service.statePath : ""
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: if (service.stateStorageReady) service.loadState(text())
    onLoadFailed: if (service.stateStorageReady) service.loadState("")
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
    interval: 50
    repeat: true
    running: service.stateLoaded && !service.demoMode
      && service.phase === Model.State.Breaking && !service.completionCuePlayed
    onTriggered: {
      if (Model.shouldLeadCompletionCue(service.phase, service.remainingMs, 100))
        service.playCompletionCue()
    }
  }

  Timer {
    // Bound visible rollback near a due break without writing every scheduler
    // tick throughout the entire work interval.
    interval: service.interrupting || service.remainingMs <= 60000 ? 5000 : 30000
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
    command: ["canberra-gtk-play", "-f", service.startSoundPath, "-V", service.soundVolumeDb, "-d", "Look Elsewhere break started"]
    onExited: function(exitCode) { service.startSoundAvailable = exitCode === 0 }
  }

  Process {
    id: breakCompletionSound
    command: ["canberra-gtk-play", "-f", service.completionSoundPath, "-V", service.soundVolumeDb, "-d", "Look Elsewhere break complete"]
    onExited: function(exitCode) { service.completionSoundAvailable = exitCode === 0 }
  }

  Component.onCompleted: {
    ensureStateDir.running = true
  }

  IpcHandler {
    target: "look-elsewhere"

    function status(): string { return JSON.stringify({ state: service.phase, remainingMs: service.remainingMs, evidence: service.evidence(), demo: service.demoMode, idlePaused: service.idlePauseActive, naturalPauseReady: service.naturalPauseReady, recoveryWarning: service.recoveryWarning }) }
    function configuration(): string { return JSON.stringify(service.config) }
    function diagnostics(): string { return JSON.stringify({ fullscreen: service.fullscreenAvailable, dictation: service.dictationAvailable, mpris: true, pipewire: true, idle: true, sound: service.soundAvailable, persistenceBlocked: service.persistenceBlocked }) }
    function takeBreak(): string { service.takeBreak(); return service.phase }
    function postpone(minutes: int): string { service.postponeMinutes(minutes); return service.phase }
    function pause(minutes: int): string { service.pauseMinutes(minutes); return service.phase }
    function pauseBreaks(): string { service.pauseBreaks(); return service.phase }
    function togglePause(): string { service.togglePause(); return service.phase }
    function resume(): string { service.resume(); return service.phase }
    function skip(): string { service.skipBreak(); return service.phase }
    function resetHistory(): string { service.resetHistory(); return "ok" }
    function resetLocalData(): string { service.resetLocalData(); return "ok" }
    function demo(state: string): string { service.setDemo(state); return service.phase }
    function demoOff(): string { service.clearDemo(); return service.phase }
  }
}
