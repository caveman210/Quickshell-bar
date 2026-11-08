import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../core"
import "../../styles"
import "../../services"
import "../../services/appearance"
import "../../services/connectivity"
import "../../services/display"
import "../../services/notification"
import "../../services/power"
import "../../services/shell"
import "../../services/system"
import "../../island"
import "../../config"

// Compact Settings pane with edge placement, toggles, and manual weather config
FocusScope {
    id: root
    implicitWidth: 380
    implicitHeight: layout.implicitHeight + 28

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
        anchors.margins: 14
        spacing: 10

        // Compact Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "󰒓"
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "Settings"
                color: Theme.textPrimary
                font.pixelSize: 16
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: Theme.surface
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: Theme.textPrimary
                    font.pixelSize: 11
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: IslandController.reset() }
            }
        }

        // Layout Selector Pill Segment
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 46
            radius: 12
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                Repeater {
                    model: ["Bar", "Pill", "Notch"]
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: IslandState.layoutName === modelData ? Theme.accent : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: IslandState.layoutName === modelData ? Theme.background : Theme.textPrimary
                            font.pixelSize: 12
                            font.bold: true
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (modelData === "Bar") IslandState.layout = IslandState.layoutBar
                                else if (modelData === "Pill") IslandState.layout = IslandState.layoutPill
                                else IslandState.layout = IslandState.layoutNotch
                            }
                        }
                    }
                }
            }
        }

        // Toggle Group Container
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: toggleList.implicitHeight + 16
            radius: 12
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            ColumnLayout {
                id: toggleList
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                // 1. Bar Dock Placement: Top vs Bottom
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: Placement.icon; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.accent }
                    Text { text: "Bar Edge Position"; color: Theme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }

                    Rectangle {
                        width: 70
                        height: 26
                        radius: 13
                        color: Theme.buttonBackground

                        Text {
                            anchors.centerIn: parent
                            text: Placement.subtitle
                            color: Theme.textPrimary
                            font.pixelSize: 11
                            font.bold: true
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Placement.toggle() }
                    }
                }

                // Divider line
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                // 2. Bar Info Mode Cycle: Cycle / Weather / Motivation
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: "󰔏"; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.accent }
                    Text { text: "Bar Display Slot"; color: Theme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }

                    Rectangle {
                        width: 80
                        height: 26
                        radius: 13
                        color: Theme.buttonBackground

                        Text {
                            anchors.centerIn: parent
                            text: ConfigStore.barInfoMode === "cycle" ? "Cycle (30m)"
                                : (ConfigStore.barInfoMode === "weather" ? "Weather" : "Quote")
                            color: Theme.accent
                            font.pixelSize: 11
                            font.bold: true
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (ConfigStore.barInfoMode === "cycle") ConfigStore.barInfoMode = "weather"
                                else if (ConfigStore.barInfoMode === "weather") ConfigStore.barInfoMode = "motivation"
                                else ConfigStore.barInfoMode = "cycle"
                                ConfigStore.save()
                            }
                        }
                    }
                }

                // Divider line
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                // 3. Auto-Hide Bar Toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: "󰒲"; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.accent }
                    Text { text: "Auto-Hide Bar"; color: Theme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }

                    Rectangle {
                        width: 44
                        height: 24
                        radius: 12
                        color: AutoHideService.enabled ? Theme.accent : Theme.buttonBackground

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: AutoHideService.enabled ? parent.width - width - 3 : 3
                            width: 18
                            height: 18
                            radius: 9
                            color: AutoHideService.enabled ? Theme.background : Theme.textPrimary
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: AutoHideService.toggle() }
                    }
                }
            }
        }

        // Manual Weather Location Override Input
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            radius: 10
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text { text: "󰍎"; font.family: Theme.iconFont; font.pixelSize: 15; color: Theme.accent }

                TextInput {
                    id: locInput
                    Layout.fillWidth: true
                    text: ConfigStore.weatherLocation
                    color: Theme.textPrimary
                    font.pixelSize: 12
                    selectByMouse: true
                    clip: true

                    Text {
                        text: "Override City (e.g. London, Delhi)"
                        color: Theme.textMuted
                        font.pixelSize: 12
                        visible: locInput.text === "" && !locInput.activeFocus
                    }

                    onEditingFinished: {
                        ConfigStore.weatherLocation = locInput.text.trim()
                        ConfigStore.save()
                    }
                }
            }
        }

        // Navigation Links Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 10
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "󰸉"; font.family: Theme.iconFont; font.pixelSize: 14; color: Theme.accent }
                    Text { text: "Wallpapers"; color: Theme.textPrimary; font.pixelSize: 12; font.bold: true }
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: IslandController.openWallpaperSelector() }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 10
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: SystemService.osIcon; font.family: Theme.iconFont; font.pixelSize: 14; color: Theme.accent }
                    Text { text: "System Info"; color: Theme.textPrimary; font.pixelSize: 12; font.bold: true }
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: IslandController.openSystemMenu() }
            }
        }
    }
}
