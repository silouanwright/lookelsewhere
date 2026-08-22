import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var service: null
  property var shell: null
  property var manifest: null

  readonly property bool visibleState: service && service.interrupting
  readonly property bool breaking: service && service.state === "breaking"
  readonly property bool finalCountdown: service && service.state === "final-countdown"

  Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      id: window
      required property var modelData
      screen: modelData
      visible: root.visibleState
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      mask: Region {
        item: !window.authoritative ? emptyHitArea
          : (root.breaking ? fullScreenHitArea : (root.finalCountdown ? finalChip : warningCard))
      }

      readonly property bool authoritative: Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === modelData.name
      property real backdropReveal: 0
      property real contentOpacity: 0
      property real contentOffset: 0
      property real contentBlur: 0

      function beginBreakReveal() {
        backdropAnimation.stop()
        contentOpacityAnimation.stop()
        contentMotionAnimation.stop()
        contentBlurAnimation.stop()
        backdropReveal = 0
        contentOffset = Style.space(96)
        contentOpacity = 0.24
        contentBlur = 0.2
        backdropAnimation.start()
        contentOpacityAnimation.start()
        contentMotionAnimation.start()
        contentBlurAnimation.start()
      }

      Connections {
        target: root
        function onBreakingChanged() {
          if (root.breaking) window.beginBreakReveal()
          else {
            backdropAnimation.stop()
            contentOpacityAnimation.stop()
            contentMotionAnimation.stop()
            contentBlurAnimation.stop()
            window.backdropReveal = 0
            window.contentOpacity = 0
            window.contentOffset = 0
            window.contentBlur = 0
          }
        }
      }

      NumberAnimation {
        id: backdropAnimation
        target: window
        property: "backdropReveal"
        from: 0
        to: 1
        duration: 1100
        easing.type: Easing.InOutSine
      }

      SequentialAnimation {
        id: contentOpacityAnimation
        PauseAnimation { duration: 40 }
        NumberAnimation {
          target: window
          property: "contentOpacity"
          from: 0.24
          to: 1
          duration: 850
          easing.type: Easing.InOutSine
        }
      }

      SequentialAnimation {
        id: contentMotionAnimation
        PauseAnimation { duration: 40 }
        NumberAnimation {
          target: window
          property: "contentOffset"
          from: Style.space(96)
          to: 0
          duration: 1000
          easing.type: Easing.InOutSine
        }
      }

      SequentialAnimation {
        id: contentBlurAnimation
        PauseAnimation { duration: 40 }
        NumberAnimation {
          target: window
          property: "contentBlur"
          from: 0.2
          to: 0
          duration: 900
          easing.type: Easing.InOutSine
        }
      }

      WlrLayershell.namespace: "look-elsewhere"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: root.breaking && authoritative ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      Item { id: emptyHitArea; width: 0; height: 0 }

      Rectangle {
        anchors.fill: parent
        visible: root.breaking || window.backdropReveal > 0
        color: Color.lock.background
        opacity: Math.max(0, Math.min(1, window.backdropReveal))
      }

      Item {
        id: fullScreenHitArea
        anchors.fill: parent
        visible: root.breaking
        enabled: root.breaking && window.authoritative
        focus: enabled

        ColumnLayout {
          x: Math.round((parent.width - width) / 2)
          y: Math.round((parent.height - implicitHeight) / 2 + window.contentOffset)
          width: Math.min(parent.width - Style.space(48), Style.space(520))
          spacing: Style.space(18)
          opacity: Math.max(0, Math.min(1, window.contentOpacity))
          scale: 1 - 0.015 * Math.min(1, Math.max(0, window.contentOffset / Style.space(96)))
          layer.enabled: window.contentBlur > 0.001
          layer.smooth: true
          layer.effect: MultiEffect {
            blurEnabled: true
            blur: window.contentBlur
            blurMax: 32
            blurMultiplier: 1
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "󰈉"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.space(54)
          }
          Text {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Look elsewhere")
            color: Color.lock.text
            font.family: Style.font.family
            font.pixelSize: Style.font.displayLarge
            font.weight: Font.DemiBold
          }
          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Let your eyes settle on something distant. Breathe. The screen will still be here.")
            color: Color.lock.placeholder
            font.family: Style.font.family
            font.pixelSize: Style.font.subtitle
            wrapMode: Text.WordWrap
          }
          Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.service ? root.service.remainingText : ""
            color: Color.lock.text
            font.family: Style.font.family
            font.pixelSize: Style.font.display
            font.weight: Font.DemiBold
          }
          RowLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: window.authoritative
            spacing: Style.space(10)
            OverlayButton {
              text: qsTr("Skip break")
              visible: root.service && root.service.config.enforcement !== "focused"
              onClicked: if (root.service) root.service.skipBreak()
            }
            OverlayButton {
              text: qsTr("+1 minute")
              visible: root.service && root.service.config.enforcement === "gentle"
              onClicked: if (root.service) root.service.postponeMinutes(1)
            }
          }
        }

        Keys.onEscapePressed: {
          if (root.service && root.service.config.enforcement !== "focused") root.service.skipBreak()
        }
      }

      BorderSurface {
        id: warningCard
        visible: !root.breaking && !root.finalCountdown
        anchors.top: parent.top
        anchors.topMargin: Style.space(56)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - Style.space(32), Style.space(520))
        height: warningContent.implicitHeight + Style.space(28)
        radius: Style.cornerRadius
        color: Color.popups.background
        borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))

        RowLayout {
          id: warningContent
          anchors.fill: parent
          anchors.margins: Style.space(14)
          spacing: Style.space(12)

          Text {
            text: "󰈉"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.display
          }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(2)
            Text {
              text: qsTr("Almost time")
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
              font.weight: Font.DemiBold
            }
            Text {
              text: qsTr("Your eyes will appreciate this.")
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }
          }
          Text {
            text: root.service ? root.service.remainingText : ""
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
            font.weight: Font.DemiBold
          }
          OverlayButton {
            text: qsTr("+5m")
            visible: window.authoritative
            onClicked: if (root.service) root.service.postponeMinutes(5)
          }
          OverlayButton {
            text: qsTr("Now")
            primary: true
            visible: window.authoritative
            onClicked: if (root.service) root.service.takeBreak()
          }
        }
      }

      BorderSurface {
        id: finalChip
        visible: root.finalCountdown
        anchors.top: parent.top
        anchors.topMargin: Style.space(56)
        anchors.horizontalCenter: parent.horizontalCenter
        width: finalRow.implicitWidth + Style.space(28)
        height: Style.space(48)
        radius: height / 2
        color: Color.popups.background
        borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))

        RowLayout {
          id: finalRow
          anchors.centerIn: parent
          spacing: Style.space(10)
          Text {
            text: "󰈉"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
          }
          Text {
            text: qsTr("Starting break in")
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.body
          }
          Text {
            text: root.service ? root.service.remainingText : ""
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
            font.weight: Font.DemiBold
          }
        }
      }
    }
  }

  component OverlayButton: Button {
    property bool primary: false
    selected: primary
    bordered: !primary
    focusable: root.breaking
    foreground: root.breaking ? Color.lock.text : Color.popups.text
    accent: Color.accent
    // Give the full-screen escape action a visible resting affordance. Use
    // the theme's hover fill rather than a fixed alpha/color so it remains
    // coherent across Omarchy themes.
    background: root.breaking && !primary
      ? Style.hoverFillFor(Color.lock.text, Color.accent)
      : "transparent"
    fontFamily: Style.font.family
    horizontalPadding: Style.space(12)
    verticalPadding: Style.space(8)
  }
}
