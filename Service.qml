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
  property bool dictationActive: false
  property bool demoMode: false
  property var demoEvidence: []

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
    ? "Held quietly while " + (snapshot.protectedCategory || "protected work") + " is active."
    : ""
  readonly property bool interrupting: state === Model.State.Warning || state === Model.State.Final || state === Model.State.Breaking
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
    var before = JSON.stringify(snapshot)
    snapshot = Model.observe(snapshot, {
      nowMs: Date.now(), active: !idle, idle: idle, evidence: evidence()
    }, config)
    if (JSON.stringify(snapshot) !== before) scheduleSave()
  }

  function configure(values) {
    var incoming = values || {}
    var next = {}
    for (var key in config) next[key] = config[key]
    if (incoming.focusMinutes !== undefined) next.focusMs = Number(incoming.focusMinutes) * 60000
    if (incoming.breakSeconds !== undefined) next.breakMs = Number(incoming.breakSeconds) * 1000
    if (incoming.enforcement !== undefined) next.enforcement = String(incoming.enforcement)
    config = Model.normalizeConfig(next)
    scheduleSave()
  }

  function takeBreak() {
    snapshot = Model.startBreak(snapshot, Date.now(), config)
    scheduleSave()
  }

  function postponeMinutes(minutes) {
    snapshot = Model.postpone(snapshot, Date.now(), Math.max(1, Number(minutes || 1)) * 60000)
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
    demoMode = true
    demoEvidence = []
    var now = Date.now()
    var next = Model.defaultSnapshot(now)
    if (name === "due") next.accumulatedActiveMs = config.focusMs - 30000
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
    snapshot = Model.defaultSnapshot(Date.now())
    scheduleSave()
  }

  function scheduleSave() {
    if (stateLoaded) saveTimer.restart()
  }

  function loadState(raw) {
    if (stateLoaded) return
    try {
      var parsed = raw ? JSON.parse(raw) : null
      if (parsed && parsed.snapshot) snapshot = parsed.snapshot
      if (parsed && parsed.config) config = Model.normalizeConfig(parsed.config)
    } catch (error) {
      console.warn("look-elsewhere: state parse failed:", error)
    }
    snapshot.lastObservedAtMs = Date.now()
    stateLoaded = true
  }

  function flushState() {
    stateFile.setText(JSON.stringify({ version: 1, config: config, snapshot: snapshot }, null, 2) + "\n")
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
        } catch (error) { service.fullscreenActive = false }
      }
    }
  }

  Process {
    id: dictationProbe
    command: ["omarchy-voxtype-status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var value = String(text || "").toLowerCase()
        service.dictationActive = value.indexOf("record") >= 0 || value.indexOf("transcrib") >= 0
      }
    }
    onExited: function(exitCode) { if (exitCode !== 0) service.dictationActive = false }
  }

  Component.onCompleted: {
    ensureStateDir.running = true
    Qt.callLater(function() { stateFile.reload() })
  }

  IpcHandler {
    target: "look-elsewhere"

    function status(): string { return JSON.stringify({ state: service.state, remainingMs: service.remainingMs, evidence: service.evidence(), demo: service.demoMode }) }
    function takeBreak(): string { service.takeBreak(); return service.state }
    function postpone(minutes: int): string { service.postponeMinutes(minutes); return service.state }
    function pause(minutes: int): string { service.pauseMinutes(minutes); return service.state }
    function resume(): string { service.resume(); return service.state }
    function skip(): string { service.skipBreak(); return service.state }
    function demo(state: string): string { service.setDemo(state); return service.state }
    function demoOff(): string { service.clearDemo(); return service.state }
  }
}
