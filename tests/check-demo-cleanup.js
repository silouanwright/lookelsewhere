const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

// Exercise the production QML method without starting desktop detectors.
const source = fs.readFileSync(path.join(__dirname, "../Service.qml"), "utf8");
const start = source.indexOf("  function clearDemo() {");
const end = source.indexOf("  function scheduleSave() {", start);
assert(start >= 0 && end > start);
const saved = { state: "waiting-for-pause", pauseReason: "manual", totals: { completed: 19 } };
const context = vm.createContext({
  demoMode: true,
  snapshot: { state: "breaking" },
  preDemoSnapshot: saved,
  config: {},
  preDemoConfig: { focusMs: 1200000 },
  preDemoRecoveryWarning: "preserve this warning",
  preDemoPersistenceBlocked: true,
  Model: { defaultSnapshot() { throw new Error("cleanup reset the saved state"); } },
});
vm.runInContext(source.slice(start, end) + "\nclearDemo();", context);
assert.equal(context.snapshot, saved);
assert.equal(context.demoMode, false);
assert.equal(context.snapshot.totals.completed, 19);
const after = JSON.stringify(context.snapshot);
const config = context.config;
vm.runInContext("clearDemo(); clearDemo();", context);
assert.equal(context.snapshot, saved);
assert.equal(JSON.stringify(context.snapshot), after);
assert.equal(context.config, config);
assert.equal(context.recoveryWarning, "preserve this warning");
assert.equal(context.persistenceBlocked, true);
console.log("Repeated demo cleanup preserves the saved snapshot, settings and recovery state.");
