import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../core"
import "../../styles"
import "../../services"
import "../../island"

FocusScope {
    id: root

    readonly property real screenWidth: Quickshell.screens.length > 0
        ? Quickshell.screens[0].width
        : 1920

    implicitWidth: 320
    implicitHeight: layout.implicitHeight + 36

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayNames: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate()
    }

    function firstDayOfMonth(y, m) {
        return new Date(y, m, 1).getDay()
    }

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
        spacing: 12

        // Month & Year header with navigation
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "󰸗"
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: root.monthNames[root.viewMonth] + " " + root.viewYear
                color: Theme.textPrimary
                font.pixelSize: 15
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: prevHover.hovered ? Theme.surfaceAlt : Theme.surface
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Theme.textPrimary
                    font.family: Theme.iconFont
                    font.pixelSize: 12
                }

                HoverHandler { id: prevHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        if (root.viewMonth === 0) {
                            root.viewMonth = 11
                            root.viewYear -= 1
                        } else {
                            root.viewMonth -= 1
                        }
                    }
                }
            }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: nextHover.hovered ? Theme.surfaceAlt : Theme.surface
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Theme.textPrimary
                    font.family: Theme.iconFont
                    font.pixelSize: 12
                }

                HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        if (root.viewMonth === 11) {
                            root.viewMonth = 0
                            root.viewYear += 1
                        } else {
                            root.viewMonth += 1
                        }
                    }
                }
            }
        }

        // Days of week header
        Grid {
            columns: 7
            Layout.alignment: Qt.AlignHCenter
            columnSpacing: 8

            Repeater {
                model: root.dayNames
                Text {
                    width: 32
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.textMuted
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        // Days grid
        Grid {
            columns: 7
            Layout.alignment: Qt.AlignHCenter
            columnSpacing: 8
            rowSpacing: 5

            // Blank lead cells
            Repeater {
                model: root.firstDayOfMonth(root.viewYear, root.viewMonth)
                Item { width: 32; height: 28 }
            }

            // Month days
            Repeater {
                model: root.daysInMonth(root.viewYear, root.viewMonth)

                delegate: Rectangle {
                    id: dayCell
                    width: 32
                    height: 28
                    radius: 8

                    property bool isToday: {
                        var now = new Date()
                        return (index + 1) === now.getDate()
                            && root.viewMonth === now.getMonth()
                            && root.viewYear === now.getFullYear()
                    }

                    color: isToday ? Theme.accent : (cellHover.hovered ? Theme.surface : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: index + 1
                        color: dayCell.isToday ? Theme.background : Theme.textPrimary
                        font.pixelSize: 12
                        font.bold: dayCell.isToday
                    }

                    HoverHandler {
                        id: cellHover
                    }
                }
            }
        }

        // Weather banner inside borders (ONLY for Notch and Pill mode)
        // Two-line hero layout: Large 2-line temperature on left, condition wrapped below location on right
        Rectangle {
            visible: !IslandState.layoutIsBar
            Layout.fillWidth: true
            Layout.topMargin: 8
            implicitHeight: weatherRow.implicitHeight + 20
            radius: 14
            color: Theme.surface
            border.width: 1
            border.color: Theme.border
            clip: true

            RowLayout {
                id: weatherRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 12
                spacing: 12

                Text {
                    text: WeatherService.icon
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 28
                    Layout.alignment: Qt.AlignVCenter
                }

                // Double-height prominent temperature display
                Text {
                    text: WeatherService.temp
                    color: Theme.textPrimary
                    font.pixelSize: 22
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Location on top, condition moved to its own line underneath
                ColumnLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    spacing: 2

                    Text {
                        text: WeatherService.city !== "" ? WeatherService.city : "Weather"
                        color: Theme.textPrimary
                        font.pixelSize: 12
                        font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }

                    Text {
                        text: WeatherService.condition
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        Layout.alignment: Qt.AlignRight
                        elide: Text.ElideRight
                    }
                }
            }

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: IslandController.openWeather() }
        }
    }
}
