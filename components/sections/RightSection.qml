import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

import "../../styles"
import "../../core"
import "../../island"
import "../../services"
import "../bar"

Item {
    id: root
    // Bar layout passes false: the bar's center section swaps the
    // clock for the status overlay instead, so the chip would only
    // duplicate the OSD next to the systray icons.
    property bool showStatusChip: true
    // Bar layout shows the control-center pill here, at the right
    // edge.
    property bool showControlPill: true
    readonly property bool hasTray: SystemTray.items && SystemTray.items.values.length > 0
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.right: parent.right
        anchors.rightMargin: Theme.sectionGap
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        StatusChip {
            Layout.alignment: Qt.AlignVCenter
            visible: root.showStatusChip && StatusManager.visible
            icon: StatusManager.icon
            title: StatusManager.title
        }

        ControlPill {
            id: pill
            visible: root.showControlPill
            Layout.alignment: Qt.AlignVCenter
        }

        // Dedicated Chevron button between toggles and power
        Rectangle {
            id: trayChevronButton
            visible: root.hasTray
            color: chevronHover.hovered ? Theme.buttonHover : Theme.surface
            radius: 10
            implicitWidth: 32
            implicitHeight: pill.implicitHeight
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }

            HoverHandler {
                id: chevronHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: function(event) {
                    event.accepted = true
                    var p = trayChevronButton.mapToItem(null, trayChevronButton.width / 2, 0)
                    IslandController.toggleTrayOverflow(p.x)
                }
            }

            Text {
                anchors.centerIn: parent
                text: IslandState.barTrayOpen ? "󰅃" : "󰅀"
                color: chevronHover.hovered ? Theme.iconActive : Theme.icon
                font.family: Theme.iconFont
                font.pixelSize: 14
            }
        }

        PrivacyCluster {
            id: privacy
            // Hide when split mode is active: privacy already lives in the detached bubble
            visible: IslandState.layoutIsBar && !(MediaService.hasPlayer && MediaService.isPlaying && (PrivacyService.micActive || PrivacyService.cameraActive || PrivacyService.screenSharingActive))
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            id: powerButton
            color: powerHover.hovered ? Theme.buttonHover : Theme.surface
            radius: 10
            implicitWidth: 32
            implicitHeight: pill.implicitHeight
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }

            HoverHandler {
                id: powerHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.ReleaseWithinBounds

                onTapped: function(event) {
                    event.accepted = true

                    if (
                        IslandState.mode === IslandState.powerMenuMode
                    )
                        return

                    IslandController.openPowerMenu()
                }
            }

            Text {
                anchors.centerIn: parent
                text: ""
                color: powerHover.hovered ? Theme.iconActive : Theme.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }
        }
    }
}
