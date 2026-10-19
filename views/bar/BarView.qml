import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../core"
import "../shared"
import "../../components/bar"
import "../../components/sections"
import "../../services"
import "../../island"

// Idle content of the bar layout: notification bell + control pill
// and media on the left, clock center, tray + power right.
// Clicking the clock section drops the panel.
Item {
    id: root

    implicitHeight: Theme.barHeight

    // Bar's own controls at the blank left end: notification bell
    // at the extreme left, then the control-center pill
    // (wifi / bluetooth / battery).
    RowLayout {
        id: leftCluster
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        NotificationBell {
            Layout.alignment: Qt.AlignVCenter
        }

        ControlPill {
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Compact media line: single row (note + title) because the bar
    // is only 33px tall; tapping opens the full media view.
    Item {
        id: mediaSection
        visible: MediaService.hasPlayer
        anchors.left: leftCluster.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: mediaRow.implicitWidth
        implicitHeight: Theme.barHeight

        RowLayout {
            id: mediaRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: "♪"
                color: Theme.textPrimary
                font.family: Theme.iconFont
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
            }

            ScrollingText {
                text: MediaService.title || "No Title"
                maxWidth: 200
                fontSize: 13
                Layout.alignment: Qt.AlignVCenter
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            gesturePolicy: TapHandler.ReleaseWithinBounds

            onTapped: function(event) {
                event.accepted = true

                IslandController.openMediaFromLeftSection()
            }
        }
    }

    Item {
        id: centerSection
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: centerRow.implicitWidth + 24
        implicitHeight: Theme.barHeight

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 10
            color: centerHover.hovered || IslandState.mode === IslandState.expandedMode
                ? Theme.surface
                : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }
        }

        HoverHandler {
            id: centerHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            gesturePolicy: TapHandler.ReleaseWithinBounds

            onTapped: function(event) {
                event.accepted = true

                if (IslandState.mode === IslandState.expandedMode)
                    IslandController.reset()
                else
                    IslandController.openExpanded()
            }
        }

        RowLayout {
            id: centerRow
            anchors.centerIn: parent
            spacing: 10

            Item {
                id: centerSlot
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: clock.implicitWidth
                implicitHeight: Theme.barHeight

                // The clock is never displaced: transient status
                // drops down below the bar instead (Island's OSD
                // dropdown).
                ClockView {
                    id: clock
                    anchors.centerIn: parent
                }
            }
        }
    }

    RightSection {
        id: rightSection
        // Bar layout never shows the compact right-side chip: the
        // center section already swaps the clock for the status
        // overlay, so the chip just duplicated the OSD next to the
        // systray icons.
        showStatusChip: false
        showControlPill: false
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
    }

    TraySection {
        id: traySection
        anchors.right: rightSection.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
    }
}
