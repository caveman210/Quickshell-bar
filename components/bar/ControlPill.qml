import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../core"
import "../../island"
import "../../services"
import "../../services/connectivity"
import "../../services/power"

// Wifi / Bluetooth / Battery / VPN readout. The pill itself is the click
// target for the Control Center.
Rectangle {
    id: root

    color: Theme.surface
    radius: 10
    implicitWidth: icons.implicitWidth + 18
    implicitHeight: icons.implicitHeight + 10

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: function(event) {
            event.accepted = true

            if (IslandState.mode === IslandState.controlCenterMode) {
                IslandController.reset()
                return
            }

            IslandController.openControlCenterFromRightSection()
        }
    }

    RowLayout {
        id: icons
        anchors.centerIn: parent
        spacing: 14

        // VPN Lock Indicator (appears only when active)
        Text {
            visible: VpnService.connected
            Layout.alignment: Qt.AlignVCenter
            text: "󰌾"
            color: Theme.accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: WifiService.icon
            color: Theme.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: BluetoothService.icon
            color: BluetoothService.enabled
                   ? Theme.icon
                   : Theme.iconDisabled
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }
        }

        RowLayout {
            id: batteryRow
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            HoverHandler {
                id: batteryHover
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: BatteryService.icon
                color: Theme.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: batteryHover.hovered
                text: BatteryService.percentage + "%"
                color: Theme.textPrimary
                font.pixelSize: 12
            }
        }
    }
}
