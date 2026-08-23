# LookElsewhere UI

This directory is LookElsewhere's internal QML component library. Import it
from plugin surfaces with:

```qml
import "Ui" as LookUi
```

Use `LookUi.*` for controls owned by this plugin. These components compose
Omarchy's `qs.Ui` and `qs.Commons` primitives so colors, spacing, focus, and
accessibility continue to follow the active shell theme.

`SettingDropdown.qml` is the only temporarily vendored first-party control.
It exists to add Space-key selection and should return to `qs.Ui.Dropdown`
when that behavior is available upstream. The remaining components are
LookElsewhere-owned compositions extracted from the working plugin.

Product-specific surfaces and visuals stay at the repository root. A control
belongs here only after LookElsewhere already uses it and owns its interaction
contract.
