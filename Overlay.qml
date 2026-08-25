pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Ui" as ProductUi
import "Views" as ProductViews
import "vendor/qmlpack/oma-ui-kit/Ui" as LookUi

Item {
  id: root

  property var service: null
  property var shell: null
  property var manifest: null

  readonly property bool visibleState: service && service.interrupting
  readonly property bool breaking: service && service.phase === "breaking"
  readonly property bool finalCountdown: service && service.phase === "final-countdown"
  readonly property int remainingSeconds: service ? Math.max(0, Math.ceil(service.remainingMs / 1000)) : 0
  readonly property int remainingMinutesPart: Math.floor(remainingSeconds / 60)
  readonly property int remainingSecondsPart: remainingSeconds % 60
  readonly property real warningClockFontSize: Style.font.heading
  readonly property real breakClockFontSize: Style.font.display * 1.35
  readonly property real warningClockSeparatorOverlap: Math.max(0,
    (warningClockColonMetrics.advanceWidth - warningClockColonMetrics.tightBoundingRect.width) / 2)
  readonly property real clockSeparatorOverlap: Math.max(0,
    (clockColonMetrics.advanceWidth - clockColonMetrics.tightBoundingRect.width) / 2)

  TextMetrics {
    id: warningClockColonMetrics
    text: ":"
    font.family: Style.font.family
    font.pixelSize: root.warningClockFontSize
    font.weight: Font.Bold
  }

  TextMetrics {
    id: clockColonMetrics
    text: ":"
    font.family: Style.font.family
    font.pixelSize: root.breakClockFontSize
    font.weight: Font.DemiBold
  }

  Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      id: window
      required property var modelData
      screen: modelData
      visible: root.visibleState && shouldPresent
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      mask: Region {
        item: !window.authoritative ? emptyHitArea
          : (root.breaking ? fullScreenHitArea : (root.finalCountdown ? finalChip : warningCard))
      }

      readonly property bool authoritative: Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === modelData.name
      readonly property bool shouldPresent: !root.service
        || root.service.config.outputMode !== "focused" || authoritative
      property real backdropReveal: 0
      property real contentOpacity: 0
      property real contentOffset: 0
      property real contentBlur: 0
      readonly property int backdropDuration: 495
      readonly property int contentRevealDelay: 200

      function settleBreakReveal() {
        backdropAnimation.stop()
        contentOpacityAnimation.stop()
        contentMotionAnimation.stop()
        contentBlurAnimation.stop()
        backdropReveal = 1
        contentOffset = 0
        contentOpacity = 1
        contentBlur = 0
      }

      function beginBreakReveal() {
        backdropAnimation.stop()
        contentOpacityAnimation.stop()
        contentMotionAnimation.stop()
        contentBlurAnimation.stop()
        backdropReveal = 0
        contentOffset = Style.space(24)
        contentOpacity = 0
        contentBlur = 0.08
        if (!shouldPresent) {
          settleBreakReveal()
          return
        }
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

      onShouldPresentChanged: {
        if (!root.breaking) return
        if (shouldPresent) beginBreakReveal()
        else settleBreakReveal()
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
        duration: window.backdropDuration
        easing.type: Easing.InOutSine
      }

      SequentialAnimation {
        id: contentOpacityAnimation
        PauseAnimation { duration: window.contentRevealDelay }
        NumberAnimation {
          target: window
          property: "contentOpacity"
          from: 0
          to: 1
          duration: 495
          easing.type: Easing.InOutSine
        }
      }

      SequentialAnimation {
        id: contentMotionAnimation
        PauseAnimation { duration: window.contentRevealDelay }
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
        PauseAnimation { duration: window.contentRevealDelay + 55 }
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

        ProductViews.BreakContent {
          x: Math.round((parent.width - width) / 2)
          y: Math.round((parent.height - implicitHeight) / 2 + window.contentOffset)
          width: Math.min(parent.width - Style.space(48), Style.space(520))
          opacity: Math.max(0, Math.min(1, window.contentOpacity))
          scale: Math.min(1, Math.max(0.1,
            (parent.height - Style.space(48)) / Math.max(1, implicitHeight)))
            * (1 - 0.008 * Math.min(1, Math.max(0, window.contentOffset / Style.space(24))))
          layer.enabled: window.contentBlur > 0.001
          layer.smooth: true
          layer.effect: MultiEffect {
            blurEnabled: true
            blur: window.contentBlur
            blurMax: 32
            blurMultiplier: 1
          }
          title: root.service ? root.service.config.breakTitle : qsTr("Look elsewhere")
          subtitle: root.service ? root.service.config.breakSubtitle
            : qsTr("Let your eyes settle on something distant. Breathe. The screen will still be here.")
          longBreak: root.service && root.service.snapshot.activeBreakIsLong
          minutes: root.remainingMinutesPart
          seconds: root.remainingSecondsPart
          reducedMotion: root.service && root.service.config.reducedMotion
          animationActive: window.visible && root.breaking
          actionsVisible: window.authoritative
          skipVisible: !!root.service
          skipEnabled: root.service && root.service.canSkipBreak
          postponeVisible: root.service && root.service.canPostpone
          clockFontSize: root.breakClockFontSize
          clockSeparatorOverlap: root.clockSeparatorOverlap
          onSkipRequested: if (root.service) root.service.skipBreak()
          onPostponeRequested: if (root.service) root.service.postponeMinutes(1)
        }

        Keys.onPressed: function(event) {
          if (event.key !== Qt.Key_Escape || !root.service) return
          if (root.service.canSkipBreak) root.service.skipBreak()
          event.accepted = true
        }
      }

      BorderSurface {
        id: warningCard
        visible: root.visibleState && !root.breaking && !root.finalCountdown
        anchors.top: parent.top
        anchors.topMargin: Style.space(48)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - Style.space(32), warningActions.implicitWidth + Style.space(16))
        height: warningContent.implicitHeight + Style.space(16)
        radius: Style.cornerRadius
        color: Color.popups.background
        borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))

        ColumnLayout {
          id: warningContent
          anchors.fill: parent
          anchors.leftMargin: Style.space(8)
          anchors.rightMargin: Style.space(8)
          anchors.topMargin: Style.space(8)
          anchors.bottomMargin: Style.space(8)
          spacing: Style.space(6)

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(12)
            ProductUi.BedIcon {
              Layout.preferredWidth: Style.space(38)
              Layout.preferredHeight: Layout.preferredWidth
              color: Color.accent
            }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0
              Row {
                spacing: -root.warningClockSeparatorOverlap
                Accessible.role: Accessible.StaticText
                Accessible.name: qsTr("%1 minutes and %2 seconds until break")
                  .arg(root.remainingMinutesPart).arg(root.remainingSecondsPart)

                ProductUi.RollingNumber {
                  value: root.remainingMinutesPart
                  minimumDigits: 2
                  color: Color.popups.text
                  fontFamily: Style.font.family
                  fontSize: root.warningClockFontSize
                  fontWeight: Font.Bold
                  reducedMotion: root.service && root.service.config.reducedMotion
                  animationActive: warningCard.visible
                }

                Text {
                  text: ":"
                  color: Color.popups.text
                  font.family: Style.font.family
                  font.pixelSize: root.warningClockFontSize
                  font.weight: Font.Bold
                  Accessible.ignored: true
                }

                ProductUi.RollingNumber {
                  value: root.remainingSecondsPart
                  minimumDigits: 2
                  color: Color.popups.text
                  fontFamily: Style.font.family
                  fontSize: root.warningClockFontSize
                  fontWeight: Font.Bold
                  reducedMotion: root.service && root.service.config.reducedMotion
                  animationActive: warningCard.visible
                }
              }
              Text {
                Layout.fillWidth: true
                Layout.topMargin: -Style.space(3)
                text: root.service && root.service.nextBreakIsLong
                  ? qsTr("Long break")
                  : qsTr("Short break")
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.weight: Font.DemiBold
                elide: Text.ElideRight
              }
            }
          }
          RowLayout {
            id: warningActions
            Layout.alignment: Qt.AlignHCenter
            visible: window.authoritative
            spacing: Style.space(6)
            OverlayButton {
              text: qsTr("Break now")
              primary: true
              verticalPadding: Style.space(3)
              onClicked: if (root.service) root.service.takeBreak()
            }
            OverlayButton {
              text: qsTr("+1m")
              verticalPadding: Style.space(3)
              actionEnabled: root.service && root.service.canPostpone
              disabledTooltipText: qsTr("No snoozes available")
              onClicked: if (root.service) root.service.delayNextBreakMinutes(1)
            }
            OverlayButton {
              text: qsTr("+5m")
              verticalPadding: Style.space(3)
              actionEnabled: root.service && root.service.canPostpone
              disabledTooltipText: qsTr("No snoozes available")
              onClicked: if (root.service) root.service.delayNextBreakMinutes(5)
            }
            OverlayButton {
              text: qsTr("+15m")
              verticalPadding: Style.space(3)
              actionEnabled: root.service && root.service.canPostpone
              disabledTooltipText: qsTr("No snoozes available")
              onClicked: if (root.service) root.service.delayNextBreakMinutes(15)
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
        height: finalRow.implicitHeight + Style.space(16)
        radius: height / 2
        color: Color.popups.background
        borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))

        RowLayout {
          id: finalRow
          anchors.fill: parent
          anchors.leftMargin: Style.space(14)
          anchors.rightMargin: Style.space(14)
          spacing: Style.space(10)
          ProductUi.BedIcon {
            Layout.preferredWidth: Style.space(24)
            Layout.preferredHeight: Layout.preferredWidth
            color: Color.accent
          }
          Text {
            Layout.fillWidth: true
            text: qsTr("Starting break in")
            color: Color.popups.text
            opacity: 0.78
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.weight: Font.Medium
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

  component OverlayButton: LookUi.WeightedButton {
    id: actionButton
    property bool primary: false
    label: text
    labelWeight: Font.Bold
    selected: primary
    bordered: !primary
    focusable: root.breaking && actionEnabled
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
    Accessible.name: actionEnabled || disabledTooltipText === ""
      ? text
      : qsTr("%1 unavailable; %2").arg(text).arg(disabledTooltipText)
    Accessible.onPressAction: if (actionEnabled) clicked()

  }
}
