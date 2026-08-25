import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "../Ui" as ProductUi
import "../vendor/qmlpack/oma-ui-kit/Ui" as LookUi

ColumnLayout {
  id: root

  property string title: qsTr("Look elsewhere")
  property string subtitle: qsTr("Let your eyes settle on something distant. Breathe. The screen will still be here.")
  property bool longBreak: false
  property int minutes: 3
  property int seconds: 0
  property bool reducedMotion: true
  property bool animationActive: false
  property bool actionsVisible: true
  property bool skipVisible: true
  property bool skipEnabled: true
  property bool postponeVisible: true
  property real clockFontSize: Style.font.display * 1.35
  property real clockSeparatorOverlap: 0

  signal skipRequested()
  signal postponeRequested()

  width: Math.min(parent ? parent.width - Style.space(48) : Style.space(520), Style.space(520))
  spacing: Style.space(18)

  ProductUi.BedIcon {
    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: Style.space(64)
    Layout.preferredHeight: Layout.preferredWidth
    color: Color.accent
  }

  Text {
    Layout.fillWidth: true
    Layout.topMargin: -Style.space(4)
    text: root.title
    color: Color.lock.text
    font.family: Style.font.family
    font.pixelSize: Style.font.displayLarge * 1.35
    font.weight: Font.Bold
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
  }

  Text {
    Layout.fillWidth: true
    Layout.topMargin: -Style.space(12)
    horizontalAlignment: Text.AlignHCenter
    text: root.subtitle
    color: Color.lock.placeholder
    font.family: Style.font.family
    font.pixelSize: Style.font.subtitle
    wrapMode: Text.WordWrap
  }

  BorderSurface {
    Layout.alignment: Qt.AlignHCenter
    Layout.bottomMargin: -Style.space(12)
    visible: root.longBreak
    implicitWidth: longBreakLabel.implicitWidth + Style.space(14)
    implicitHeight: longBreakLabel.implicitHeight + Style.space(6)
    color: Style.hoverFillFor(Color.lock.text, Color.accent)
    borderSpec: Border.controlSpec("normal", Color.lock.text, Color.accent)
    radius: height / 2

    Text {
      id: longBreakLabel
      anchors.centerIn: parent
      text: qsTr("Long break")
      color: Color.lock.text
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.weight: Font.Bold
    }
  }

  Row {
    Layout.alignment: Qt.AlignHCenter
    spacing: -root.clockSeparatorOverlap
    Accessible.role: Accessible.StaticText
    Accessible.name: qsTr("%1 minutes and %2 seconds remaining").arg(root.minutes).arg(root.seconds)

    ProductUi.RollingNumber {
      value: root.minutes
      minimumDigits: 2
      color: Color.lock.text
      fontFamily: Style.font.family
      fontSize: root.clockFontSize
      fontWeight: Font.DemiBold
      reducedMotion: root.reducedMotion
      animationActive: root.animationActive
    }

    Text {
      text: ":"
      color: Color.lock.text
      font.family: Style.font.family
      font.pixelSize: root.clockFontSize
      font.weight: Font.DemiBold
      Accessible.ignored: true
    }

    ProductUi.RollingNumber {
      value: root.seconds
      minimumDigits: 2
      color: Color.lock.text
      fontFamily: Style.font.family
      fontSize: root.clockFontSize
      fontWeight: Font.DemiBold
      reducedMotion: root.reducedMotion
      animationActive: root.animationActive
    }
  }

  RowLayout {
    Layout.alignment: Qt.AlignHCenter
    visible: root.actionsVisible
    spacing: Style.space(10)

    LookUi.WeightedButton {
      label: qsTr("Skip break")
      labelWeight: Font.Bold
      bordered: true
      focusable: root.animationActive && actionEnabled
      foreground: Color.lock.text
      accent: Color.accent
      background: Style.hoverFillFor(Color.lock.text, Color.accent)
      fontFamily: Style.font.family
      horizontalPadding: Style.space(12)
      verticalPadding: Style.space(8)
      visible: root.skipVisible
      actionEnabled: root.skipEnabled
      disabledTooltipText: qsTr("Breaks cannot be skipped in Hardcore mode")
      Accessible.role: Accessible.Button
      Accessible.name: actionEnabled || disabledTooltipText === ""
        ? label : qsTr("%1 unavailable; %2").arg(label).arg(disabledTooltipText)
      Accessible.onPressAction: if (actionEnabled) clicked()
      onClicked: root.skipRequested()
    }

    LookUi.WeightedButton {
      label: qsTr("+1 minute")
      labelWeight: Font.Bold
      bordered: true
      focusable: root.animationActive
      foreground: Color.lock.text
      accent: Color.accent
      background: Style.hoverFillFor(Color.lock.text, Color.accent)
      fontFamily: Style.font.family
      horizontalPadding: Style.space(12)
      verticalPadding: Style.space(8)
      visible: root.postponeVisible
      Accessible.role: Accessible.Button
      Accessible.name: label
      Accessible.onPressAction: clicked()
      onClicked: root.postponeRequested()
    }
  }
}
