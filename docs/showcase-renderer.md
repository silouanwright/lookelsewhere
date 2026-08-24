# Showcase renderer

`tools/render-showcase` renders the real LookElsewhere panel and break content
through Omarchy's own QML theme system. It runs Quickshell offscreen with an
isolated temporary home, so it does not change the active theme, monitor,
workspace, shell, or schedule.

The default command produces the square, shortcut-free six-theme panel grid:

```bash
tools/render-showcase
```

Render the full-screen experience at Retina density:

```bash
tools/render-showcase \
  --surface fullscreen \
  --size 1920x1080 \
  --density 2 \
  --output docs/assets/theme-fullscreen-grid.png
```

Full-screen renders use each theme's first packaged wallpaper behind the real
Omarchy lock-surface tint. If a theme has no wallpaper, the renderer falls
back to that theme's background color.

Pass any number of installed theme directory names to choose and order the
tiles. User themes in `~/.config/omarchy/themes` take precedence over stock
themes in `/usr/share/omarchy/themes`.

```bash
tools/render-showcase --columns 2 nord tokyo-night catppuccin-latte
```

Panel and break previews reuse `PanelNowView.qml` and `BreakContent.qml`, the
same visual components rendered by the installed plugin. The harness owns only
static fixture data and offscreen capture; production windowing, focus, IPC,
and service lifecycle remain outside it.
