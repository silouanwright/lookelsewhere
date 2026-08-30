pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "../Model.js" as Model
import "../vendor/qmlpack/oma-ui-kit/Ui" as LookUi

ColumnLayout {
  id: root

  property var snapshot: null
  property color foreground: Color.popups.text
  property color muted: Color.muted
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real sideInset: 0
  property real topInset: 0
  property bool reducedMotion: false

  readonly property var statistics: snapshot && snapshot.statistics
    ? snapshot.statistics : Model.defaultStatistics(Date.now())
  readonly property var today: statistics.today
  readonly property var sessions: today.sessions || []
  readonly property var previousDays: statistics.days || []
  readonly property real medianSessionMs: Model.medianSessionDuration(snapshot)

  function dayLabel(dayKey) {
    return new Date(String(dayKey) + "T12:00:00").toLocaleDateString(Qt.locale(), "ddd, MMM d")
  }

  function timeLabel(milliseconds) {
    return new Date(Number(milliseconds || 0)).toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
  }

  function outcomeLabel(outcome) {
    if (outcome === "long-break") return qsTr("Long break")
    if (outcome === "planned-break") return qsTr("Planned break")
    if (outcome === "away") return qsTr("Time away")
    return qsTr("Eye break")
  }

  Layout.fillWidth: true
  Layout.leftMargin: sideInset
  Layout.rightMargin: sideInset
  Layout.topMargin: Style.space(8)
  spacing: Style.space(10)

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: root.topInset
    label: qsTr("Today")
    foreground: root.muted
    fontFamily: root.fontFamily
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(activeMetric.implicitHeight, completedMetric.implicitHeight)
    Layout.topMargin: -Style.space(7)

    Metric {
      id: activeMetric
      anchors { left: parent.left; right: metricDivider.left; verticalCenter: parent.verticalCenter }
      anchors.rightMargin: Style.space(12)
      label: qsTr("Active screen time")
      value: Model.formatDuration(root.today.activeMs)
      prominent: true
    }
    Rectangle {
      id: metricDivider
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(1, Style.space(1))
      height: Style.space(46)
      color: root.foreground
      opacity: 0.14
    }
    Metric {
      id: completedMetric
      anchors { left: metricDivider.right; right: parent.right; verticalCenter: parent.verticalCenter }
      anchors.leftMargin: Style.space(12)
      label: qsTr("Breaks completed")
      value: String(root.today.completed || 0)
      prominent: true
    }
  }

  PanelSeparator {
    Layout.fillWidth: true
    foreground: root.foreground
    strength: 0.08
  }

  RowLayout {
    Layout.fillWidth: true
    Layout.leftMargin: Style.space(4)
    Layout.rightMargin: Style.space(4)
    spacing: Style.space(7)
    Accessible.role: Accessible.StaticText
    Accessible.name: qsTr("Current session, %1").arg(
      Model.formatDuration(root.statistics.currentSessionActiveMs))
    Rectangle {
      id: liveIndicator
      Layout.preferredWidth: Style.space(5)
      Layout.preferredHeight: Layout.preferredWidth
      radius: width / 2
      color: root.accent

      SequentialAnimation on opacity {
        running: !root.reducedMotion
        loops: Animation.Infinite
        NumberAnimation { to: 0.4; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
        onRunningChanged: if (!running) liveIndicator.opacity = 1
      }
    }
    Text {
      text: qsTr("Current session")
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      Accessible.ignored: true
    }
    Text {
      text: "·"
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      Accessible.ignored: true
    }
    Text {
      text: Model.formatDuration(root.statistics.currentSessionActiveMs)
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.weight: Font.DemiBold
      Accessible.ignored: true
    }
  }

  Text {
    Layout.fillWidth: true
    Layout.leftMargin: Style.space(4)
    text: qsTr("%1 short · %2 long · %3 planned · %4 snoozed · %5 skipped")
      .arg(Number(root.today.shortBreaks || 0)).arg(Number(root.today.longBreaks || 0))
      .arg(Number(root.today.plannedBreaks || 0)).arg(Number(root.today.snoozed || 0))
      .arg(Number(root.today.skipped || 0))
    color: root.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    horizontalAlignment: Text.AlignLeft
    wrapMode: Text.WordWrap
  }

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(4)
    label: qsTr("Recent sessions")
    foreground: root.muted
    fontFamily: root.fontFamily
  }

  Text {
    Layout.fillWidth: true
    text: qsTr("Longest %1  ·  Median %2")
      .arg(Model.formatDuration(root.today.longestSessionMs))
      .arg(root.medianSessionMs > 0 ? Model.formatDuration(root.medianSessionMs) : qsTr("Not yet"))
    color: root.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    horizontalAlignment: Text.AlignLeft
  }

  Text {
    Layout.fillWidth: true
    visible: root.sessions.length === 0
    text: qsTr("Your completed focus sessions will appear here.")
    color: root.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
  }

  Repeater {
    model: root.sessions
    delegate: ColumnLayout {
      required property var modelData
      required property int index
      Layout.fillWidth: true
      spacing: Style.space(5)
      Accessible.role: Accessible.StaticText
      Accessible.name: qsTr("%1, %2, ended %3")
        .arg(root.outcomeLabel(modelData.outcome))
        .arg(Model.formatDuration(modelData.durationMs))
        .arg(root.timeLabel(modelData.endedAtMs))

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)
        Text {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignBaseline
          text: root.outcomeLabel(modelData.outcome)
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.weight: Font.Medium
          elide: Text.ElideRight
          Accessible.ignored: true
        }
        Text {
          Layout.alignment: Qt.AlignBaseline
          text: Model.formatDuration(modelData.durationMs)
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          Accessible.ignored: true
        }
        Text {
          Layout.alignment: Qt.AlignBaseline
          text: root.timeLabel(modelData.endedAtMs)
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          Accessible.ignored: true
        }
      }
      PanelSeparator {
        Layout.fillWidth: true
        visible: index < root.sessions.length - 1
        foreground: root.foreground
        strength: 0.08
      }
    }
  }

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(4)
    visible: root.previousDays.length > 0
    label: qsTr("Previous days")
    foreground: root.muted
    fontFamily: root.fontFamily
  }

  Repeater {
    model: root.previousDays
    delegate: ColumnLayout {
      required property var modelData
      required property int index
      Layout.fillWidth: true
      spacing: Style.space(5)
      Accessible.role: Accessible.StaticText
      Accessible.name: qsTr("%1, %2 active screen time, %3 breaks")
        .arg(root.dayLabel(modelData.dateKey))
        .arg(Model.formatDuration(modelData.activeMs))
        .arg(Number(modelData.completed || 0))

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)
        Text {
          Layout.fillWidth: true
          text: root.dayLabel(modelData.dateKey)
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
          Accessible.ignored: true
        }
        Text {
          text: Model.formatDuration(modelData.activeMs)
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          Accessible.ignored: true
        }
        Text {
          text: qsTr("%1 breaks").arg(Number(modelData.completed || 0))
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          Accessible.ignored: true
        }
      }
      PanelSeparator {
        Layout.fillWidth: true
        visible: index < root.previousDays.length - 1
        foreground: root.foreground
        strength: 0.08
      }
    }
  }

  component Metric: ColumnLayout {
    property string label: ""
    property string value: ""
    property bool compact: false
    property bool prominent: false
    spacing: Style.space(1)
    Accessible.role: Accessible.StaticText
    Accessible.name: qsTr("%1, %2").arg(label).arg(value)
    Text {
      Layout.fillWidth: true
      text: parent.value
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: parent.prominent ? Style.font.display
        : (parent.compact ? Style.font.body : Style.font.heading)
      font.weight: Font.DemiBold
      horizontalAlignment: Text.AlignHCenter
      Accessible.ignored: true
    }
    Text {
      Layout.fillWidth: true
      text: parent.label
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      Accessible.ignored: true
    }
  }
}
