# oma-showcase

Render a plugin-owned QML preview across installed Omarchy themes without
changing the active desktop theme.

The package owns the isolated home, theme selection, offscreen Quickshell
window, high-density capture, wallpaper discovery, and image grid. The
consuming plugin owns its preview component and fixture data.

```bash
oma-showcase \
  --project . \
  --preview tools/showcase/Preview.qml \
  --output docs/assets/themes.png
```

Requires Omarchy 4.x, Quickshell, and ImageMagick.
