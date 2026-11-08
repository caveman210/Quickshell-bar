import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../core"
import "../../styles"
import "../../services"

FocusScope {
    id: root
    implicitWidth: 320
    implicitHeight: layout.implicitHeight + 36

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
        anchors.margins: 18
        spacing: 14

        // Header: Location & Refresh
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "󰖐"
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 18
            }

            Text {
                text: WeatherService.city !== "" ? WeatherService.city : "Weather"
                color: Theme.textPrimary
                font.pixelSize: 15
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                width: 26
                height: 26
                radius: 13
                color: Theme.surface

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Theme.textSecondary
                    font.family: Theme.iconFont
                    font.pixelSize: 12
                }

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: WeatherService.refresh() }
            }
        }

        // Current Main Tile
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 80
            radius: 16
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Text {
                    text: WeatherService.icon
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 40
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: WeatherService.temp
                        color: Theme.textPrimary
                        font.pixelSize: 22
                        font.bold: true
                    }

                    Text {
                        text: WeatherService.condition
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Secondary Details (Humidity & Wind)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                height: 50
                radius: 12
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Text { text: "󰖎"; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.accent }
                    ColumnLayout {
                        spacing: 1
                        Text { text: "Humidity"; color: Theme.textSecondary; font.pixelSize: 9 }
                        Text { text: WeatherService.humidity; color: Theme.textPrimary; font.bold: true; font.pixelSize: 12 }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 50
                radius: 12
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Text { text: "󰖝"; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.accent }
                    ColumnLayout {
                        spacing: 1
                        Text { text: "Wind"; color: Theme.textSecondary; font.pixelSize: 9 }
                        Text { text: WeatherService.wind; color: Theme.textPrimary; font.bold: true; font.pixelSize: 12 }
                    }
                }
            }
        }
    }
}
