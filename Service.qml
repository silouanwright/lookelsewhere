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
  property bool stateLoaded: false
  property bool fullscreenActive: false
  property bool fullscreenAvailable: false
  property bool dictationActive: false
  property bool dictationAvailable: false
  property string recoveryWarning: ""
  property bool persistenceBlocked: false
  property bool settingsOpen: false
  property var settingWriteQueue: []
  property bool demoMode: false
  property var demoEvidence: []
  property var preDemoSnapshot: null
  property var preDemoConfig: null

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var pipewireNodes: Pipewire.nodes ? Pipewire.nodes.values : []
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
  readonly property bool idle: idleMonitor.isIdle
  readonly property string state: snapshot.state || Model.State.Working
  readonly property string label: Model.stateLabel(snapshot)
  readonly property string remainingText: Model.formatDuration(remainingMs)
  readonly property real progress: {
    if (state === Model.State.Breaking) return config.breakMs > 0 ? 1 - remainingMs / config.breakMs : 1
    return config.focusMs > 0 ? Math.max(0, Math.min(1, Number(snapshot.accumulatedActiveMs || 0) / config.focusMs)) : 0
  }
  readonly property string protectedSummary: state === Model.State.Protected
    ? Model.protectedExplanation(snapshot.protectedCategory)
    : ""
  readonly property bool interrupting: state === Model.State.Warning || state === Model.State.Final || state === Model.State.Breaking
  readonly property bool canPostpone: Model.canPostpone(snapshot, config)
  readonly property int remainingMs: {
    var now = Date.now()
    if (state === Model.State.Breaking) return Math.max(0, Number(snapshot.breakEndsAtMs || 0) - now)
    if (state === Model.State.Warning || state === Model.State.Final) return Math.max(0, Number(snapshot.warningEndsAtMs || 0) - now)
    if (state === Model.State.Waiting && snapshot.postponedUntilMs > now) return snapshot.postponedUntilMs - now
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
      nowMs: Date.now(), active: !effectiveIdle, idle: effectiveIdle, evidence: evidence()
    }, config)
    if (interrupting) settingsOpen = false
    if (!demoMode && snapshot.state !== beforeState) scheduleSave()
  }

  function configure(values) {
    var incoming = values || {}
    var next = JSON.parse(JSON.stringify(config))
    if (incoming.focusMinutes !== undefined) next.focusMs = Number(incoming.focusMinutes) * 60000
    if (incoming.breakSeconds !== undefined) next.breakMs = Number(incoming.breakSeconds) * 1000
    if (incoming.enforcement !== undefined) next.enforcement = String(incoming.enforcement)
    if (incoming.maximumDelayMinutes !== undefined) next.maximumDelayMs = Number(incoming.maximumDelayMinutes) * 60000
    if (incoming.snoozeBudget !== undefined) next.snoozeBudget = Number(incoming.snoozeBudget)
    if (incoming.reducedMotion !== undefined) next.reducedMotion = incoming.reducedMotion === true
    if (incoming.officeHoursEnabled !== undefined) next.officeHours.enabled = incoming.officeHoursEnabled === true
    if (incoming.officeStart !== undefined) next.officeHours.startMinute = parseClockMinute(incoming.officeStart, next.officeHours.startMinute)
    if (incoming.officeEnd !== undefined) next.officeHours.endMinute = parseClockMinute(incoming.officeEnd, next.officeHours.endMinute)
    var detectorKeys = ["idle", "fullscreen", "media", "microphone", "dictation"]
    for (var i = 0; i < detectorKeys.length; i++) {
      var detector = detectorKeys[i]
      var settingKey = detector + "Detection"
      if (incoming[settingKey] !== undefined) next.detectors[detector] = incoming[settingKey] === true
    }
    config = Model.normalizeConfig(next)
    scheduleSave()
  }

  function parseClockMinute(value, fallback) {
    var match = /^(\d{1,2}):(\d{2})$/.exec(String(value || "").trim())
    if (!match) return fallback
    var hour = Number(match[1])
    var minute = Number(match[2])
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 ? hour * 60 + minute : fallback
  }

  function takeBreak() {
    snapshot = Model.startBreak(snapshot, Date.now(), config)
    scheduleSave()
  }

  function postponeMinutes(minutes) {
    if (!canPostpone) return
    snapshot = Model.postpone(snapshot, Date.now(), Math.max(1, Number(minutes || 1)) * 60000, config)
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

  function resume() {
    var next = JSON.parse(JSON.stringify(snapshot))
    next.state = Model.State.Working
    next.pauseReason = ""
    next.postponedUntilMs = 0
    next.lastObservedAtMs = Date.now()
    snapshot = next
    scheduleSave()
  }

  function skipBreak() {
    var next = Model.completeBreak(snapshot, Date.now())
    next.totals.completed = Math.max(0, next.totals.completed - 1)
    next.totals.skipped++
    snapshot = next
    scheduleSave()
  }

  function setDemo(name) {
    if (!demoMode) {
      preDemoSnapshot = JSON.parse(JSON.stringify(snapshot))
      preDemoConfig = JSON.parse(JSON.stringify(config))
    }
    demoMode = true
    demoEvidence = []
    var now = Date.now()
    var next = Model.defaultSnapshot(now)
    if (name === "working") next.accumulatedActiveMs = config.focusMs * 0.35
    else if (name === "due") next.accumulatedActiveMs = config.focusMs - 30000
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
    } else if (name === "break") next = Model.startBreak(next, now, config)
    snapshot = next
    observe()
  }

  function clearDemo() {
    demoMode = false
    demoEvidence = []
    snapshot = preDemoSnapshot || Model.defaultSnapshot(Date.now())
    config = preDemoConfig || config
    snapshot.lastObservedAtMs = Date.now()
    preDemoSnapshot = null
    preDemoConfig = null
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
      if (parsed && parsed.config) config = Model.normalizeConfig(parsed.config)
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
    stateFile.setText(JSON.stringify({ version: 1, config: config, snapshot: snapshot }, null, 2) + "\n")
  }

  function resetLocalData() {
    snapshot = Model.defaultSnapshot(Date.now())
    recoveryWarning = ""
    persistenceBlocked = false
    flushState()
  }

  function openSettings() { settingsOpen = true }
  function closeSettings() { settingsOpen = false }

  function updateSetting(key, value) {
    var incoming = {}
    incoming[String(key)] = value
    configure(incoming)
    var queue = settingWriteQueue.slice()
    queue.push({ key: String(key), value: value })
    settingWriteQueue = queue
    startNextSettingWrite()
  }

  function startNextSettingWrite() {
    if (settingWriter.running || settingWriteQueue.length === 0) return
    var item = settingWriteQueue[0]
    settingWriter.command = ["omarchy", "bar", "set", pluginId, item.key, JSON.stringify(item.value), "--json"]
    settingWriter.running = true
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

  Process {
    id: ensureStateDir
    command: ["mkdir", "-p", service.stateDir]
  }

  FileView {
    id: stateFile
    path: service.statePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: service.loadState(text())
    onLoadFailed: service.loadState("")
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
    interval: 30000
    repeat: true
    running: service.stateLoaded && !service.demoMode
    onTriggered: service.flushState()
  }

  Timer {
    interval: 2000
    repeat: true
    running: !service.demoMode
    triggeredOnStart: true
    onTriggered: {
      if (!fullscreenProbe.running) fullscreenProbe.running = true
      if (!dictationProbe.running) dictationProbe.running = true
    }
  }

  Process {
    id: fullscreenProbe
    command: ["hyprctl", "activewindow", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var value = JSON.parse(text)
          service.fullscreenActive = Number(value.fullscreen || value.fullscreenClient || 0) > 0
          service.fullscreenAvailable = true
        } catch (error) {
          service.fullscreenActive = false
          service.fullscreenAvailable = false
        }
      }
    }
    onExited: function(exitCode) { if (exitCode !== 0) service.fullscreenAvailable = false }
  }

  Process {
    id: dictationProbe
    command: ["omarchy-voxtype-status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var value = String(text || "").toLowerCase()
        service.dictationActive = value.indexOf("record") >= 0 || value.indexOf("transcrib") >= 0
        service.dictationAvailable = true
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        service.dictationActive = false
        service.dictationAvailable = false
      }
    }
  }

  Process {
    id: settingWriter
    onExited: function(exitCode) {
      if (exitCode !== 0) console.warn("look-elsewhere: failed to persist setting", settingWriteQueue.length ? settingWriteQueue[0].key : "")
      var queue = settingWriteQueue.slice(1)
      settingWriteQueue = queue
      startNextSettingWrite()
    }
  }

  Component.onCompleted: {
    ensureStateDir.running = true
    Qt.callLater(function() { stateFile.reload() })
  }

  IpcHandler {
    target: "look-elsewhere"

    function status(): string { return JSON.stringify({ state: service.state, remainingMs: service.remainingMs, evidence: service.evidence(), demo: service.demoMode, recoveryWarning: service.recoveryWarning }) }
    function configuration(): string { return JSON.stringify(service.config) }
    function diagnostics(): string { return JSON.stringify({ fullscreen: service.fullscreenAvailable, dictation: service.dictationAvailable, mpris: true, pipewire: true, idle: true, persistenceBlocked: service.persistenceBlocked }) }
    function takeBreak(): string { service.takeBreak(); return service.state }
    function postpone(minutes: int): string { service.postponeMinutes(minutes); return service.state }
    function pause(minutes: int): string { service.pauseMinutes(minutes); return service.state }
    function resume(): string { service.resume(); return service.state }
    function skip(): string { service.skipBreak(); return service.state }
    function resetHistory(): string { service.resetHistory(); return "ok" }
    function resetLocalData(): string { service.resetLocalData(); return "ok" }
    function openSettings(): string { service.openSettings(); return "ok" }
    function closeSettings(): string { service.closeSettings(); return "ok" }
    function demo(state: string): string { service.setDemo(state); return service.state }
    function demoOff(): string { service.clearDemo(); return service.state }
  }
}
