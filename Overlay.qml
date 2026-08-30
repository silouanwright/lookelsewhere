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
  readonly property bool naturalBreakToastVisible: service && service.naturalBreakToastVisible
  readonly property bool breaking: service && service.phase === "breaking"
  readonly property bool finalCountdown: service && service.phase === "final-countdown"
  readonly property bool plannedReady: service && service.plannedReady
  readonly property int remainingSeconds: service ? Math.max(0, Math.ceil(service.remainingMs / 1000)) : 0
  readonly property int remainingMinutesPart: Math.floor(remainingSeconds / 60)
  readonly property int remainingSecondsPart: remainingSeconds % 60
  readonly property real warningClockFontSize: Style.font.heading
  readonly property real breakClockFontSize: Style.font.display * 1.35
  readonly property color popupMuted: Qt.tint(Color.popups.background,
    Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.82))
  readonly property real warningClockSeparatorOverlap: Math.max(0,
    (warningClockColonMetrics.advanceWidth - warningClockColonMetrics.tightBoundingRect.width) / 2)
  readonly property real clockSeparatorOverlap: Math.max(0,
    (clockColonMetrics.advanceWidth - clockColonMetrics.tightBoundingRect.width) / 2)

  function accessibleCountdown(seconds, suffix) {
    if (seconds <= 10) return qsTr("%1 seconds %2").arg(seconds).arg(suffix)
    if (seconds < 60) return qsTr("Less than one minute %1").arg(suffix)
    return qsTr("About %1 minutes %2").arg(Math.ceil(seconds / 60)).arg(suffix)
  }

  function announcePhase() {
    if (!service) return
    if (service.phase === "warning")
      root.Accessible.announce(qsTr("Break reminder. %1").arg(accessibleCountdown(remainingSeconds, qsTr("until break"))))
    else if (service.phase === "final-countdown")
      root.Accessible.announce(qsTr("Break starting soon"), Accessible.Assertive)
    else if (service.phase === "breaking")
      root.Accessible.announce(qsTr("Break started"), Accessible.Assertive)
    else if (service.phase === "working")
      root.Accessible.announce(qsTr("Break complete"))
  }

  Accessible.role: Accessible.Pane
  Accessible.name: qsTr("LookElsewhere alerts")

  Connections {
    target: root.service
    function onPhaseChanged() { root.announcePhase() }
  }

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
      visible: (root.visibleState || root.naturalBreakToastVisible) && shouldPresent
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      mask: Region {
        item: !window.authoritative ? emptyHitArea
          : (root.breaking ? fullScreenHitArea
            : (root.finalCountdown ? finalChip
              : (root.visibleState ? warningCard : naturalBreakChip)))
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
        contentBlur = root.service && root.service.config.reducedTransparency ? 0 : 0.08
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
        : authoritative && (root.naturalBreakToastVisible
            || (root.visibleState && !root.finalCountdown))
          ? WlrKeyboardFocus.OnDemand
          : WlrKeyboardFocus.None

      Item { id: emptyHitArea; width: 0; height: 0 }

      Rectangle {
        anchors.fill: parent
        visible: root.breaking || window.backdropReveal > 0
        color: root.service && root.service.config.reducedTransparency
          ? Qt.rgba(Color.lock.background.r, Color.lock.background.g, Color.lock.background.b, 1)
          : Color.lock.background
        opacity: Math.max(0, Math.min(1, window.backdropReveal))
      }

      Item {
        id: fullScreenHitArea
        anchors.fill: parent
        visible: root.breaking
        enabled: root.breaking && window.authoritative
        focus: enabled

        Flickable {
          id: breakViewport
          x: Math.round((parent.width - width) / 2)
          y: Math.round((parent.height - height) / 2 + window.contentOffset)
          width: Math.min(parent.width - Style.space(48), Style.space(520))
          height: Math.min(parent.height - Style.space(48), breakContent.implicitHeight)
          contentWidth: width
          contentHeight: breakContent.implicitHeight
          boundsBehavior: Flickable.StopAtBounds
          clip: contentHeight > height
          interactive: contentHeight > height
          opacity: Math.max(0, Math.min(1, window.contentOpacity))
          layer.enabled: !(root.service && root.service.config.reducedTransparency)
            && window.contentBlur > 0.001
          layer.smooth: true
          layer.effect: MultiEffect {
            blurEnabled: true
            blur: window.contentBlur
            blurMax: 32
            blurMultiplier: 1
          }

          ProductViews.BreakContent {
            id: breakContent
            width: breakViewport.width
            title: root.service && root.service.plannedActive
              ? root.service.plannedName
              : root.service && root.service.snapshot.activeBreakIsLong
                ? root.service.config.longBreakTitle
                : root.service ? root.service.config.breakTitle : qsTr("Look elsewhere")
            subtitle: root.service && root.service.snapshot.activeBreakIsLong
              ? root.service.config.longBreakSubtitle
              : root.service ? root.service.config.breakSubtitle
              : qsTr("Let your eyes settle on something distant. Breathe. The screen will still be here.")
            longBreak: root.service && root.service.snapshot.activeBreakIsLong
            totalSeconds: root.remainingSeconds
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
        }

        Keys.onPressed: function(event) {
          if (event.key !== Qt.Key_Escape || !root.service) return
          if (root.service.canSkipBreak) root.service.skipBreak()
          event.accepted = true
        }
      }

      ProductUi.TransientNotice {
        id: naturalBreakChip
        visible: root.naturalBreakToastVisible && !root.visibleState
        anchors.top: parent.top
        anchors.topMargin: Style.space(48)
        anchors.horizontalCenter: parent.horizontalCenter
        onVisibleChanged: if (visible && window.authoritative)
          Qt.callLater(function() { undoNaturalBreakButton.forceActiveFocus() })
        ProductUi.BedIcon {
          Layout.preferredWidth: Style.space(20)
          Layout.preferredHeight: Layout.preferredWidth
          color: Color.accent
        }
        Text {
          text: root.service ? root.service.naturalBreakMessage : ""
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.weight: Font.Medium
        }
        OverlayButton {
          id: undoNaturalBreakButton
          text: qsTr("Undo")
          verticalPadding: Style.space(2)
          horizontalPadding: Style.space(6)
          onClicked: if (root.service) root.service.undoNaturalBreak()
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
        onVisibleChanged: if (visible && window.authoritative)
          Qt.callLater(function() { warningBreakNowButton.forceActiveFocus() })

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
              ProductUi.RollingClock {
                value: root.remainingSeconds
                separatorOverlap: root.warningClockSeparatorOverlap
                color: Color.popups.text
                fontFamily: Style.font.family
                fontSize: root.warningClockFontSize
                fontWeight: Font.Bold
                reducedMotion: root.service && root.service.config.reducedMotion
                animationActive: warningCard.visible
                Accessible.role: Accessible.StaticText
                Accessible.name: root.accessibleCountdown(root.remainingSeconds, qsTr("until break"))
              }
              Text {
                Layout.fillWidth: true
                Layout.topMargin: -Style.space(3)
                text: root.service && root.service.plannedActive
                  ? root.service.plannedName
                  : root.service && root.service.nextBreakIsLong
                  ? qsTr("Long break")
                  : qsTr("Short break")
                color: root.popupMuted
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
              id: warningBreakNowButton
              text: root.plannedReady ? qsTr("Start break") : qsTr("Break now")
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
            OverlayButton {
              visible: root.plannedReady
              text: qsTr("Skip today")
              verticalPadding: Style.space(3)
              onClicked: if (root.service) root.service.skipBreak()
            }
          }
        }
      }

      ProductUi.TransientNotice {
        id: finalChip
        visible: root.finalCountdown
        anchors.top: parent.top
        anchors.topMargin: Style.space(48)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - Style.space(32), implicitWidth)
        ProductUi.BedIcon {
          Layout.preferredWidth: Style.space(20)
          Layout.preferredHeight: Layout.preferredWidth
          color: Color.accent
        }
        Text {
          Layout.fillWidth: true
          text: root.service && root.service.plannedActive
            ? qsTr("%1 starts in").arg(root.service.plannedName)
            : qsTr("Starting break in")
          color: root.popupMuted
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.weight: Font.Medium
          elide: Text.ElideRight
        }
        Text {
          text: root.service ? root.service.remainingText : ""
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.weight: Font.DemiBold
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
    focusable: visible && actionEnabled
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
