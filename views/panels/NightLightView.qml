import QtQuick
import QtQuick.Layouts

import "../../core"
import "../../styles"
import "../../services/display"
import "../../island"
import "../../config"
import "../../components/settings"

// Dedicated Night Light view (styled like WallpaperSelectorView & Settings subviews)
FocusScope {
    id: root
    implicitWidth: 460
    implicitHeight: layout.implicitHeight + 36
    focus: true

    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            IslandController.openSettings()
            event.accepted = true
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        // Top Navigation Header (Back button to Settings)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: backHover.hovered ? Theme.buttonHover : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󰁍"
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                }

                HoverHandler { id: backHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: IslandController.openSettings() }
            }

            Text {
                text: "Night Light"
                color: Theme.textPrimary
                font.bold: true
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            // Active State Indicator / Current temperature
            Rectangle {
                height: 26
                implicitWidth: statusRow.implicitWidth + 14
                radius: 13
                color: NightLightService.enabled ? Theme.accent : Theme.surface
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: NightLightService.enabled ? "󰔎" : "󰃞"
                        color: NightLightService.enabled ? Theme.background : Theme.textMuted
                        font.family: Theme.iconFont
                        font.pixelSize: 12
                    }

                    Text {
                        text: NightLightService.enabled ? (NightLightService.currentTemp + "K") : "Off"
                        color: NightLightService.enabled ? Theme.background : Theme.textSecondary
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }
        }

        // Schedule Configuration Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: schedCol.implicitHeight + 24
            radius: 12
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            ColumnLayout {
                id: schedCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Master Schedule Toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: "󰔎"; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.accent }

                    Column {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { text: "Automatic Schedule"; color: Theme.textPrimary; font.pixelSize: 13; font.bold: true }
                        Text { text: "Gradually shift color temperature at night"; color: Theme.textMuted; font.pixelSize: 10 }
                    }

                    Rectangle {
                        width: 44
                        height: 24
                        radius: 12
                        color: ConfigStore.nightLightSchedule ? Theme.accent : Theme.buttonBackground

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: ConfigStore.nightLightSchedule ? parent.width - width - 3 : 3
                            width: 18
                            height: 18
                            radius: 9
                            color: ConfigStore.nightLightSchedule ? Theme.background : Theme.textPrimary
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                ConfigStore.nightLightSchedule = !ConfigStore.nightLightSchedule
                                ConfigStore.save()
                                if (ConfigStore.nightLightSchedule)
                                    NightLightService.checkSchedule()
                            }
                        }
                    }
                }

                // Hours Picker Row
                RowLayout {
                    Layout.fillWidth: true
                    visible: ConfigStore.nightLightSchedule
                    spacing: 8

                    Text {
                        text: "Operating Window"
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 62
                        height: 26
                        radius: 6
                        color: Theme.background
                        border.width: 1
                        border.color: Theme.border

                        TextInput {
                            id: startTimeInput
                            anchors.fill: parent
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            text: ConfigStore.nightLightStart
                            color: Theme.textPrimary
                            font.pixelSize: 11
                            font.bold: true
                            selectByMouse: true
                            onEditingFinished: {
                                if (text.trim()) {
                                    ConfigStore.nightLightStart = text.trim()
                                    ConfigStore.save()
                                    NightLightService.recheckSchedule()
                                }
                            }
                        }
                    }

                    Text { text: "to"; color: Theme.textMuted; font.pixelSize: 11 }

                    Rectangle {
                        width: 62
                        height: 26
                        radius: 6
                        color: Theme.background
                        border.width: 1
                        border.color: Theme.border

                        TextInput {
                            id: endTimeInput
                            anchors.fill: parent
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            text: ConfigStore.nightLightEnd
                            color: Theme.textPrimary
                            font.pixelSize: 11
                            font.bold: true
                            selectByMouse: true
                            onEditingFinished: {
                                if (text.trim()) {
                                    ConfigStore.nightLightEnd = text.trim()
                                    ConfigStore.save()
                                    NightLightService.recheckSchedule()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Dedicated Interactive Curve Progression Section
        CurveEditor {
            Layout.fillWidth: true
            visible: ConfigStore.nightLightSchedule
        }
    }
}
