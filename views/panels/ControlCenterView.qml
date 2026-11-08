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

Item {
    id: root
    clip: true
    implicitWidth: 460

    readonly property real maxViewHeight: 0.70 * (
        Quickshell.screens.length > 0
            ? Quickshell.screens[0].height
            : 1080
    )

    implicitHeight: Math.min(layout.implicitHeight + 40, maxViewHeight)

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

        // =========================================================
        // MERGED ANDROID 17 / iOS 2-COLUMN CONTROL CENTER
        // Left Column: 2x3 Quick Action Tiles
        // Right Column: Dual Vertical Pill Sliders (Volume & Brightness)
        // =========================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            // 2x3 Grid of Compact Icon Tiles
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                // 1. Wi-Fi
                Rectangle {
                    Layout.fillWidth: true
                    height: 58
                    radius: 14
                    color: WifiService.connected ? Theme.accent : Theme.surface
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text {
                            text: WifiService.icon
                            color: WifiService.connected ? Theme.background : Theme.textPrimary
                            font.family: Theme.iconFont
                            font.pixelSize: 18
                        }
                        Text {
                            text: "Wi-Fi"
                            color: WifiService.connected ? Theme.background : Theme.textPrimary
                            font.bold: true
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: IslandController.openWifiMenu()
                    }
                }

                // 2. Bluetooth
                Rectangle {
                    Layout.fillWidth: true
                    height: 58
                    radius: 14
                    color: BluetoothService.enabled ? Theme.accent : Theme.surface
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text {
                            text: BluetoothService.icon
                            color: BluetoothService.enabled ? Theme.background : Theme.textPrimary
                            font.family: Theme.iconFont
                            font.pixelSize: 18
                        }
                        Text {
                            text: "Bluetooth"
                            color: BluetoothService.enabled ? Theme.background : Theme.textPrimary
                            font.bold: true
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: IslandController.openBluetoothMenu()
                    }
                }

                // 3. Microphone Toggle
                Rectangle {
                    Layout.fillWidth: true
                    height: 58
                    radius: 14
                    color: !MicrophoneService.muted ? Theme.accent : Theme.surface
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text {
                            text: MicrophoneService.icon
                            color: !MicrophoneService.muted ? Theme.background : Theme.textPrimary
                            font.family: Theme.iconFont
                            font.pixelSize: 18
                        }
                        Text {
                            text: "Mic"
                            color: !MicrophoneService.muted ? Theme.background : Theme.textPrimary
                            font.bold: true
                            font.pixelSize: 12
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: MicrophoneService.toggle() }
                }

                // 4. Night Light Toggle
                Rectangle {
                    Layout.fillWidth: true
                    height: 58
                    radius: 14
                    color: NightLightService.enabled ? Theme.accent : Theme.surface
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text {
                            text: NightLightService.icon
                            color: NightLightService.enabled ? Theme.background : Theme.textPrimary
                            font.family: Theme.iconFont
                            font.pixelSize: 18
                        }
                        Text {
                            text: "Night Light"
                            color: NightLightService.enabled ? Theme.background : Theme.textPrimary
                            font.bold: true
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: NightLightService.toggle() }
                }

                // 5. Do Not Disturb
                Rectangle {
                    Layout.fillWidth: true
                    height: 58
                    radius: 14
                    color: NotificationService.dnd ? Theme.accent : Theme.surface
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text {
                            text: NotificationService.dnd ? "󰂛" : "󰂚"
                            color: NotificationService.dnd ? Theme.background : Theme.textPrimary
                            font.family: Theme.iconFont
                            font.pixelSize: 18
                        }
                        Text {
                            text: "DND"
                            color: NotificationService.dnd ? Theme.background : Theme.textPrimary
                            font.bold: true
                            font.pixelSize: 12
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: NotificationService.dnd = !NotificationService.dnd }
                }

                // 6. Wallpaper Picker Shortcut
                Rectangle {
                    Layout.fillWidth: true
                    height: 58
                    radius: 14
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text {
                            text: "󰸉"
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.pixelSize: 18
                        }
                        Text {
                            text: "Wallpaper"
                            color: Theme.textPrimary
                            font.bold: true
                            font.pixelSize: 12
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: IslandController.openWallpaperSelector() }
                }
            }

            // Right: Dual Vertical Pill Sliders (Volume & Brightness)
            RowLayout {
                spacing: 12
                Layout.alignment: Qt.AlignVCenter

                // Vertical Volume
                VerticalSlider {
                    icon: AudioService.volumeIcon
                    value: AudioService.volume / 100
                    onValueChangedByUser: function(v) { AudioService.setVolume(v * 100) }
                }

                // Vertical Brightness
                VerticalSlider {
                    icon: BrightnessService.brightnessIcon
                    value: BrightnessService.brightness / 100
                    onValueChangedByUser: function(v) { BrightnessService.setBrightness(v * 100) }
                }
            }
        }
    }
}
