import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../styles"
import "../../components/sections"
import "../../core"
import "../shared"
import "../../services"
import "../../services/appearance"
import "../../services/audio"
import "../../services/connectivity"
import "../../services/display"
import "../../services/notification"
import "../../services/power"
import "../../services/shell"
import "../../services/system"
import "../../island"

FocusScope {
    id: root
    clip: true
    implicitWidth: 420

    readonly property real maxViewHeight: 0.70 * (
        Quickshell.screens.length > 0
            ? Quickshell.screens[0].height
            : 1080
    )

    implicitHeight: Math.min(layout.implicitHeight + 40, maxViewHeight)

    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            IslandController.reset()
            event.accepted = true
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Header: Title + Settings Shortcut + Battery
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Control Center"
                color: Theme.textPrimary
                font.pixelSize: 20
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            // Dedicated Settings Hub Button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: Theme.surface
                border.width: 1
                border.color: Theme.border
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                }

                HoverHandler { id: setHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: IslandController.openSettings() }
            }

            // Battery Readout
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6
                Text {
                    text: BatteryService.icon
                    color: Theme.icon
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }
                Text {
                    text: BatteryService.percentage + "%"
                    color: Theme.textPrimary
                    font.pixelSize: 13
                }
            }
        }

        // Quick Action Tiles: Icon-only Grid (6 icons across 3 or 6 columns)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // 1. Wi-Fi
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 16
                color: WifiService.connected ? Theme.accent : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: WifiService.icon
                    color: WifiService.connected ? Theme.background : Theme.textPrimary
                    font.family: Theme.iconFont
                    font.pixelSize: 20
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: IslandController.openWifiMenu() }
            }

            // 2. Bluetooth
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 16
                color: BluetoothService.enabled ? Theme.accent : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: BluetoothService.icon
                    color: BluetoothService.enabled ? Theme.background : Theme.textPrimary
                    font.family: Theme.iconFont
                    font.pixelSize: 20
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: IslandController.openBluetoothMenu() }
            }

            // 3. Microphone Toggle
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 16
                color: !MicrophoneService.muted ? Theme.accent : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: MicrophoneService.icon
                    color: !MicrophoneService.muted ? Theme.background : Theme.textPrimary
                    font.family: Theme.iconFont
                    font.pixelSize: 20
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: MicrophoneService.toggle() }
            }

            // 4. Night Light Toggle
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 16
                color: NightLightService.enabled ? Theme.accent : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: NightLightService.icon
                    color: NightLightService.enabled ? Theme.background : Theme.textPrimary
                    font.family: Theme.iconFont
                    font.pixelSize: 20
                }

                // Schedule active badge indicator (clock icon in top-right corner)
                Text {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    text: "󰥔"
                    visible: ConfigStore.nightLightSchedule
                    color: NightLightService.enabled ? Theme.background : Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 11
                }

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: NightLightService.toggle() }
            }

            // 5. Do Not Disturb
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 16
                color: NotificationService.dnd ? Theme.accent : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: NotificationService.dnd ? "󰂛" : "󰂚"
                    color: NotificationService.dnd ? Theme.background : Theme.textPrimary
                    font.family: Theme.iconFont
                    font.pixelSize: 20
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: NotificationService.dnd = !NotificationService.dnd }
            }

            // 6. Power Profile Toggle (tlp-pd)
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 16
                color: PowerProfileService.isPerformance ? Theme.accent : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: PowerProfileService.icon
                    color: PowerProfileService.isPerformance ? Theme.background : (PowerProfileService.isPowerSaver ? Theme.textSecondary : Theme.accent)
                    font.family: Theme.iconFont
                    font.pixelSize: 20
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: PowerProfileService.cycleProfile() }
            }
        }

        // Sliders at bottom: fully rounded capsule sliders
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            // Volume Slider
            ControlSlider {
                Layout.fillWidth: true
                icon: AudioService.volumeIcon
                value: AudioService.volume / 100
                onIconClicked: AudioService.toggleMute()
                onValueChangedByUser: function(v) { AudioService.setVolume(v * 100) }
            }

            // Brightness Slider
            ControlSlider {
                Layout.fillWidth: true
                icon: BrightnessService.brightnessIcon
                value: BrightnessService.brightness / 100
                onValueChangedByUser: function(v) { BrightnessService.setBrightness(v * 100) }
            }
        }
    }
}
