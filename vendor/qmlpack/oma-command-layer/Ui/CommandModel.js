function normalize(value) {
  var parts = String(value === undefined || value === null ? "" : value)
    .split("+").map(function(part) { return part.trim() }).filter(function(part) { return part !== "" })
  if (!parts.length) return ""

  var base = parts.pop()
  if (/^[a-z]$/i.test(base)) base = base.toUpperCase()
  else if (/^f(?:[1-9]|1[0-2])$/i.test(base)) base = base.toUpperCase()
  else if (!/^[0-9?]$/.test(base)) return ""

  var aliases = { control: "Ctrl", ctrl: "Ctrl", alt: "Alt", shift: "Shift", meta: "Meta", super: "Meta" }
  var requested = {}
  for (var i = 0; i < parts.length; i++) {
    var modifier = aliases[parts[i].toLowerCase()]
    if (!modifier || requested[modifier]) return ""
    requested[modifier] = true
  }

  var order = ["Ctrl", "Alt", "Shift", "Meta"]
  var normalized = []
  for (var j = 0; j < order.length; j++) if (requested[order[j]]) normalized.push(order[j])
  normalized.push(base)
  return normalized.join("+")
}

function resolve(settings, definitions) {
  var source = settings || {}
  var items = definitions || []
  var result = {}

  for (var i = 0; i < items.length; i++) {
    var definition = items[i]
    result[definition.action] = normalize(source[definition.setting]) || definition.fallback
  }

  // Duplicate QML shortcuts are ambiguous. Restore custom collisions to the
  // package consumer's unique defaults.
  for (var pass = 0; pass < items.length; pass++) {
    var counts = {}
    for (var j = 0; j < items.length; j++) {
      var value = result[items[j].action]
      counts[value] = Number(counts[value] || 0) + 1
    }

    var changed = false
    for (var k = 0; k < items.length; k++) {
      var item = items[k]
      if (counts[result[item.action]] > 1 && result[item.action] !== item.fallback) {
        result[item.action] = item.fallback
        changed = true
      }
    }
    if (!changed) break
  }

  return result
}

function label(sequence) {
  var value = String(sequence || "")
  return /^Shift\+.$/.test(value) ? "⬆" + value.slice(-1) : value
}
