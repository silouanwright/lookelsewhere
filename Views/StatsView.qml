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
  property string fontFamily: Style.font.family
  property real sideInset: 0

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
    if (outcome === "away") return qsTr("Time away")
    return qsTr("Eye break")
  }

  Layout.fillWidth: true
  Layout.leftMargin: sideInset
  Layout.rightMargin: sideInset
  Layout.topMargin: Style.space(8)
  spacing: Style.space(10)

  Text {
    Layout.fillWidth: true
    text: qsTr("Today")
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
    font.weight: Font.DemiBold
    horizontalAlignment: Text.AlignHCenter
  }

  RowLayout {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(5)
    spacing: Style.space(12)

    Metric {
      Layout.fillWidth: true
      label: qsTr("Active screen time")
      value: Model.formatDuration(root.today.activeMs)
      prominent: true
    }
    Rectangle {
      Layout.preferredWidth: Math.max(1, Style.space(1))
      Layout.preferredHeight: Style.space(46)
      color: root.foreground
      opacity: 0.14
    }
    Metric {
      Layout.fillWidth: true
      label: qsTr("Breaks completed")
      value: String(root.today.completed || 0)
      prominent: true
    }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

  RowLayout {
    Layout.fillWidth: true
    Layout.leftMargin: Style.space(4)
    Layout.rightMargin: Style.space(4)
    spacing: Style.space(7)
    Rectangle {
      Layout.preferredWidth: Style.space(5)
      Layout.preferredHeight: Layout.preferredWidth
      radius: width / 2
      color: root.foreground
      opacity: 0.72
    }
    Text {
      Layout.fillWidth: true
      text: qsTr("Current session")
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
    Text {
      text: Model.formatDuration(root.statistics.currentSessionActiveMs)
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.weight: Font.DemiBold
    }
  }

  Text {
    Layout.fillWidth: true
    text: qsTr("Longest %1  ·  Median %2")
      .arg(Model.formatDuration(root.today.longestSessionMs))
      .arg(root.medianSessionMs > 0 ? Model.formatDuration(root.medianSessionMs) : qsTr("Not yet"))
    color: root.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    horizontalAlignment: Text.AlignHCenter
  }

  Text {
    Layout.fillWidth: true
    Layout.topMargin: -Style.space(4)
    text: qsTr("%1 short · %2 long · %3 snoozed · %4 skipped")
      .arg(Number(root.today.shortBreaks || 0)).arg(Number(root.today.longBreaks || 0))
      .arg(Number(root.today.snoozed || 0)).arg(Number(root.today.skipped || 0))
    color: root.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    horizontalAlignment: Text.AlignHCenter
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

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)
        Text {
          Layout.fillWidth: true
          text: root.outcomeLabel(modelData.outcome)
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.weight: Font.Medium
          elide: Text.ElideRight
        }
        Text {
          text: Model.formatDuration(modelData.durationMs)
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          text: root.timeLabel(modelData.endedAtMs)
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
      PanelSeparator {
        Layout.fillWidth: true
        visible: index < root.sessions.length - 1
        foreground: root.foreground
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
    delegate: RowLayout {
      required property var modelData
      Layout.fillWidth: true
      spacing: Style.space(8)
      Text {
        Layout.fillWidth: true
        text: root.dayLabel(modelData.dateKey)
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
      }
      Text {
        text: Model.formatDuration(modelData.activeMs)
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
      Text {
        text: qsTr("%1 breaks").arg(Number(modelData.completed || 0))
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }

  component Metric: ColumnLayout {
    property string label: ""
    property string value: ""
    property bool compact: false
    property bool prominent: false
    spacing: Style.space(1)
    Text {
      Layout.fillWidth: true
      text: parent.value
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: parent.prominent ? Style.font.display
        : (parent.compact ? Style.font.body : Style.font.heading)
      font.weight: Font.DemiBold
      horizontalAlignment: Text.AlignHCenter
    }
    Text {
      Layout.fillWidth: true
      text: parent.label
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
    }
  }
}
