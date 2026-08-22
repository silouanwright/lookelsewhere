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
  readonly property bool breaking: service && service.phase === "breaking"
  readonly property bool finalCountdown: service && service.phase === "final-countdown"
  readonly property int remainingSeconds: service ? Math.max(0, Math.ceil(service.remainingMs / 1000)) : 0

  Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      id: window
      required property var modelData
      screen: modelData
      visible: root.visibleState && (!root.service || root.service.config.outputMode !== "focused" || window.authoritative)
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
        contentOffset = Style.space(24)
        contentOpacity = 0.28
        contentBlur = 0.08
        if (root.service && root.service.config.reducedMotion) {
          backdropReveal = 1
          contentOffset = 0
          contentOpacity = 1
          contentBlur = 0
          return
        }
        backdropAnimation.start()
        contentOpacityAnimation.start()
        contentMotionAnimation.start()
        contentBlurAnimation.start()
      }

      Component.onCompleted: {
        if (root.breaking) Qt.callLater(window.beginBreakReveal)
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
        duration: 495
        easing.type: Easing.InOutSine
      }

      SequentialAnimation {
        id: contentOpacityAnimation
        PauseAnimation { duration: 66 }
        NumberAnimation {
          target: window
          property: "contentOpacity"
          from: 0.28
          to: 1
          duration: 495
          easing.type: Easing.InOutSine
        }
      }

      SequentialAnimation {
        id: contentMotionAnimation
        PauseAnimation { duration: 0 }
        NumberAnimation {
          target: window
          property: "contentOffset"
          from: Style.space(24)
          to: 0
          duration: 715
          easing.type: Easing.OutCubic
        }
      }

      SequentialAnimation {
        id: contentBlurAnimation
        PauseAnimation { duration: 121 }
        NumberAnimation {
          target: window
          property: "contentBlur"
          from: 0.08
          to: 0
          duration: 495
          easing.type: Easing.InOutSine
        }
      }

      WlrLayershell.namespace: "look-elsewhere"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: root.breaking && authoritative
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

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
          scale: 1 - 0.008 * Math.min(1, Math.max(0, window.contentOffset / Style.space(24)))
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
            text: qsTr("LookElsewhere")
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
          Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            Accessible.role: Accessible.StaticText
            Accessible.name: qsTr("%1 seconds remaining").arg(root.remainingSeconds)

            RollingNumber {
              value: root.remainingSeconds
              color: Color.lock.text
              fontFamily: Style.font.family
              fontSize: Style.font.display
              fontWeight: Font.DemiBold
              reducedMotion: root.service && root.service.config.reducedMotion
            }
            Text {
              text: qsTr("s")
              color: Color.lock.text
              font.family: Style.font.family
              font.pixelSize: Style.font.display
              font.weight: Font.DemiBold
              Accessible.ignored: true
            }
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
              visible: root.service && root.service.config.enforcement === "gentle" && root.service.canPostpone
              onClicked: if (root.service) root.service.postponeMinutes(1)
            }
          }
          Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.service && root.service.config.enforcement === "focused"
            text: qsTr("Emergency exit: Ctrl + Shift + Esc")
            color: Color.lock.placeholder
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
          }
        }

        Keys.onPressed: function(event) {
          if (event.key !== Qt.Key_Escape || !root.service) return
          var emergency = (event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier)
          if (emergency) {
            root.service.emergencyExit()
            event.accepted = true
          } else if (root.service.config.enforcement !== "focused") {
            root.service.skipBreak()
            event.accepted = true
          }
        }
      }

      BorderSurface {
        id: warningCard
        visible: root.visibleState && !root.breaking && !root.finalCountdown
        anchors.top: parent.top
        anchors.topMargin: Style.space(56)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - Style.space(32), Style.space(520))
        height: warningContent.implicitHeight + Style.space(28)
        radius: Style.cornerRadius
        color: Color.popups.background
        borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))

        ColumnLayout {
          id: warningContent
          anchors.fill: parent
          anchors.margins: Style.space(14)
          spacing: Style.space(8)

          RowLayout {
            Layout.fillWidth: true
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
                Layout.fillWidth: true
                text: qsTr("Your eyes will appreciate this.")
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                wrapMode: Text.WordWrap
              }
            }
            Text {
              text: root.service ? root.service.remainingText : ""
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
              font.weight: Font.DemiBold
            }
          }
          RowLayout {
            Layout.alignment: Qt.AlignRight
            visible: window.authoritative
            spacing: Style.space(8)
            OverlayButton {
              text: qsTr("+5m")
              visible: root.service && root.service.canPostpone
              onClicked: if (root.service) root.service.postponeMinutes(5)
            }
            OverlayButton {
              text: qsTr("Now")
              primary: true
              onClicked: if (root.service) root.service.takeBreak()
            }
          }
        }
      }

      BorderSurface {
        id: finalChip
        visible: root.finalCountdown
        anchors.top: parent.top
        anchors.topMargin: Style.space(56)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - Style.space(32), finalRow.implicitWidth + Style.space(28))
        height: Style.space(48)
        radius: height / 2
        color: Color.popups.background
        borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))

        RowLayout {
          id: finalRow
          anchors.fill: parent
          anchors.margins: Style.space(14)
          spacing: Style.space(10)
          Text {
            text: "󰈉"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
          }
          Text {
            Layout.fillWidth: true
            text: qsTr("Starting break in")
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            elide: Text.ElideRight
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
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: clicked()
  }
}
