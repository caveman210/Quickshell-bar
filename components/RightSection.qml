import QtQuick

import "../styles"
import "../core"
import "../island"
import "../services"

Item {
    property Item batteryService
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.right: parent.right
        anchors.rightMargin: Theme.sectionGap
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        StatusChip {
            visible: StatusManager.visible
            icon: StatusManager.icon
            title: StatusManager.title
        }

        Rectangle {
            id: pill
            color: Theme.surface
            radius: 10
            implicitWidth: icons.implicitWidth + 18
            implicitHeight: icons.implicitHeight + 10
            anchors.verticalCenter: parent.verticalCenter

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.ReleaseWithinBounds

                onTapped: function(event) {
                    event.accepted = true

                    if (
                        IslandState.mode === IslandState.controlCenterMode
                    )
                        return

                    IslandController.openControlCenterFromRightSection()
                }
            }

            Row {
                id: icons
                anchors.centerIn: parent
                spacing: 14

                Text {
                    text: WifiService.icon
                    color: Theme.icon
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }

                // Glyph already distinguishes off / on / connected,
                // so this stays a plain readout like wifi. The pill
                // itself is the click target for the Control Center,
                // which holds the actual Bluetooth toggle.
                Text {
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

                Row {
                    id: batteryRow
                    spacing: 6

                    HoverHandler {
                        id: batteryHover
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: batteryService
                              ? batteryService.icon
                              : "󰁺"
                        color: Theme.icon
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: batteryHover.hovered
                        text: batteryService
                              ? batteryService.percentage + "%"
                              : "--%"
                        color: Theme.textPrimary
                        font.pixelSize: 12
                    }
                }
            }
        }

        PrivacyCluster {
            id: privacy
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            id: powerButton
            color: powerHover.hovered ? Theme.buttonHover : Theme.surface
            radius: 10
            implicitWidth: 32
            implicitHeight: pill.implicitHeight
            anchors.verticalCenter: parent.verticalCenter

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
