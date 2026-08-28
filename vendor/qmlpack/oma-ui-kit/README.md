# oma-ui-kit

Keyboard-first QML settings and action components extracted from
LookElsewhere. They compose Omarchy's installed `qs.Ui` and `qs.Commons`
primitives rather than replacing the host theme and interaction system.

Setting rows treat their label and control as one accessible target: clicking
a toggle row toggles it, clicking a dropdown row opens it, and clicking a
number row's label focuses its editor.

Import the vendored directory from an Omarchy plugin:

```qml
import "vendor/qmlpack/oma-ui-kit/Ui" as OmaUi
```

Alongside keyboard-first controls, the kit includes `PanelPattern`, a tiled,
softly faded backdrop renderer. Consumers supply and retain ownership of the
pattern artwork.

The package currently targets Omarchy 4.x and Quickshell 0.3.x. It includes a
temporarily adapted Omarchy Dropdown to support Space-key selection; that file
should return upstream when the native control supplies the behavior.
