// Archived post-MVP settings prototype from commit 3d7bc50.
// This file is research material only and is not loaded by the plugin runtime.
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Item {
  id: root

  property var service: null
  signal closeRequested()

  readonly property color foreground: Color.popups.text
  readonly property color muted: Color.muted
  readonly property color accent: Color.accent
  readonly property string fontFamily: Style.font.family

  focus: true
  Keys.onEscapePressed: root.closeRequested()

  function minutes(milliseconds) { return Math.round(Number(milliseconds || 0) / 60000) }
  function seconds(milliseconds) { return Math.round(Number(milliseconds || 0) / 1000) }
  function clock(minutesSinceMidnight) {
    var value = Math.max(0, Math.min(1439, Number(minutesSinceMidnight || 0)))
    var hour = Math.floor(value / 60)
    var minute = value % 60
    return (hour < 10 ? "0" : "") + hour + ":" + (minute < 10 ? "0" : "") + minute
  }
  function saveInteger(key, field) {
    if (!service || !field.acceptableInput) return
    service.updateSetting(key, Number(field.text))
  }

  Flickable {
    id: scroll
    anchors.fill: parent
    contentWidth: width
    contentHeight: form.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick

    ColumnLayout {
      id: form
      width: scroll.width
      spacing: Style.space(18)

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(12)

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(2)
          Text {
            text: qsTr("Look Elsewhere settings")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            font.weight: Font.DemiBold
          }
          Text {
            text: qsTr("Calm breaks, timed around what you are doing.")
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }
        }

        Button {
          text: qsTr("Close")
          bordered: true
          focusable: true
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          onClicked: root.closeRequested()
        }
      }

      Text {
        text: qsTr("Breaks")
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        font.weight: Font.DemiBold
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Style.space(12)
        rowSpacing: Style.space(10)

        ColumnLayout {
          Layout.fillWidth: true
          Text { text: qsTr("Focus interval (minutes)"); color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
          TextField {
            id: focusMinutes
            Layout.fillWidth: true
            text: root.service ? String(root.minutes(root.service.config.focusMs)) : "20"
            validator: IntValidator { bottom: 1; top: 180 }
            foreground: root.foreground
            accent: root.accent
            onEditingFinished: root.saveInteger("focusMinutes", focusMinutes)
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Text { text: qsTr("Break duration (seconds)"); color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
          TextField {
            id: breakSeconds
            Layout.fillWidth: true
            text: root.service ? String(root.seconds(root.service.config.breakMs)) : "20"
            validator: IntValidator { bottom: 5; top: 600 }
            foreground: root.foreground
            accent: root.accent
            onEditingFinished: root.saveInteger("breakSeconds", breakSeconds)
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Text { text: qsTr("Maximum smart delay (minutes)"); color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
          TextField {
            id: maximumDelay
            Layout.fillWidth: true
            text: root.service ? String(root.minutes(root.service.config.maximumDelayMs)) : "15"
            validator: IntValidator { bottom: 0; top: 180 }
            foreground: root.foreground
            accent: root.accent
            onEditingFinished: root.saveInteger("maximumDelayMinutes", maximumDelay)
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Text { text: qsTr("Snoozes per cycle"); color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
          TextField {
            id: snoozeBudget
            Layout.fillWidth: true
            text: root.service ? String(root.service.config.snoozeBudget) : "3"
            validator: IntValidator { bottom: 0; top: 10 }
            foreground: root.foreground
            accent: root.accent
            onEditingFinished: root.saveInteger("snoozeBudget", snoozeBudget)
          }
        }
      }

      Text {
        text: qsTr("Office hours")
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        font.weight: Font.DemiBold
      }

      Toggle {
        Layout.fillWidth: true
        label: qsTr("Use office hours")
        description: qsTr("Pause break scheduling outside this daily window. Overnight schedules are supported.")
        checked: root.service && root.service.config.officeHours.enabled
        foreground: root.foreground
        accent: root.accent
        fontFamily: root.fontFamily
        onClicked: if (root.service) root.service.updateSetting("officeHoursEnabled", !checked)
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(12)

        ColumnLayout {
          Layout.fillWidth: true
          Text { text: qsTr("Starts"); color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
          TextField {
            id: officeStart
            Layout.fillWidth: true
            text: root.service ? root.clock(root.service.config.officeHours.startMinute) : "08:00"
            placeholderText: qsTr("08:00")
            foreground: root.foreground
            accent: root.accent
            onEditingFinished: if (root.service) root.service.updateSetting("officeStart", text)
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Text { text: qsTr("Ends"); color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
          TextField {
            id: officeEnd
            Layout.fillWidth: true
            text: root.service ? root.clock(root.service.config.officeHours.endMinute) : "18:00"
            placeholderText: qsTr("18:00")
            foreground: root.foreground
            accent: root.accent
            onEditingFinished: if (root.service) root.service.updateSetting("officeEnd", text)
          }
        }
      }

      Text {
        text: qsTr("Smart Context")
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        font.weight: Font.DemiBold
      }

      Toggle {
        Layout.fillWidth: true
        label: qsTr("Idle time")
        description: qsTr("Count only active screen use toward the next break.")
        checked: root.service && root.service.config.detectors.idle
        foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
        onClicked: if (root.service) root.service.updateSetting("idleDetection", !checked)
      }
      Toggle {
        Layout.fillWidth: true
        label: qsTr("Fullscreen work")
        description: qsTr("Wait through presentations, games, and other fullscreen activity.")
        checked: root.service && root.service.config.detectors.fullscreen
        foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
        onClicked: if (root.service) root.service.updateSetting("fullscreenDetection", !checked)
      }
      Toggle {
        Layout.fillWidth: true
        label: qsTr("Media playback")
        description: qsTr("Wait while a compatible MPRIS player is actively playing.")
        checked: root.service && root.service.config.detectors.media
        foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
        onClicked: if (root.service) root.service.updateSetting("mediaDetection", !checked)
      }
      Toggle {
        Layout.fillWidth: true
        label: qsTr("Microphone and meetings")
        description: qsTr("Uses PipeWire stream state only. Audio is never recorded.")
        checked: root.service && root.service.config.detectors.microphone
        foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
        onClicked: if (root.service) root.service.updateSetting("microphoneDetection", !checked)
      }
      Toggle {
        Layout.fillWidth: true
        label: qsTr("Omarchy dictation")
        description: qsTr("Wait while local dictation is recording or transcribing.")
        checked: root.service && root.service.config.detectors.dictation
        foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
        onClicked: if (root.service) root.service.updateSetting("dictationDetection", !checked)
      }

      Text {
        text: qsTr("Behavior and experience")
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        font.weight: Font.DemiBold
      }

      Dropdown {
        Layout.fillWidth: true
        label: qsTr("Enforcement")
        value: root.service ? root.service.config.enforcement : "balanced"
        options: [
          { value: "gentle", label: qsTr("Gentle — snooze during breaks") },
          { value: "balanced", label: qsTr("Balanced — skip after a pause") },
          { value: "focused", label: qsTr("Focused — no routine skips") }
        ]
        foreground: root.foreground
        accent: root.accent
        fontFamily: root.fontFamily
        onChanged: function(nextValue) { if (root.service) root.service.updateSetting("enforcement", nextValue) }
      }

      Toggle {
        Layout.fillWidth: true
        label: qsTr("Reduce motion")
        description: qsTr("Remove the break-screen rise and soft-focus transition.")
        checked: root.service && root.service.config.reducedMotion
        foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
        onClicked: if (root.service) root.service.updateSetting("reducedMotion", !checked)
      }

      BorderSurface {
        Layout.fillWidth: true
        implicitHeight: privacyContent.implicitHeight + Style.space(28)
        color: Style.controlFill(false, false, root.foreground, root.accent)
        borderSpec: Border.controlSpec("normal", root.foreground, root.accent)
        radius: Style.cornerRadius

        ColumnLayout {
          id: privacyContent
          anchors.fill: parent
          anchors.margins: Style.space(14)
          spacing: Style.space(8)
          Text {
            Layout.fillWidth: true
            text: qsTr("Private by design")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.weight: Font.DemiBold
          }
          Text {
            Layout.fillWidth: true
            text: qsTr("Signals stay local and coarse. Look Elsewhere stores no audio, screen captures, window titles, media titles, transcripts, accounts, or telemetry.")
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }
          Button {
            text: qsTr("Reset break history")
            bordered: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            onClicked: if (root.service) root.service.resetHistory()
          }
        }
      }
    }
  }
}
