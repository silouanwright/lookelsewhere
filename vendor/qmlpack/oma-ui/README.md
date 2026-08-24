# oma-ui

Keyboard-first QML settings and action components extracted from
LookElsewhere. They compose Omarchy's installed `qs.Ui` and `qs.Commons`
primitives rather than replacing the host theme and interaction system.

Import the vendored directory from an Omarchy plugin:

```qml
import "vendor/qmlpack/oma-ui/Ui" as OmaUi
```

The package currently targets Omarchy 4.x and Quickshell 0.3.x. It includes a
temporarily adapted Omarchy Dropdown to support Space-key selection; that file
should return upstream when the native control supplies the behavior.
