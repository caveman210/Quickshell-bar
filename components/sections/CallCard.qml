import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import "../../styles"
import "../../services/notification"
import "../../services/notification/NotifUtils.js" as NotifUtils

Item {
    id: root

    property var callData: NotificationService.activeCall
    readonly property int totalCalls: NotificationService.activeCalls.length
    readonly property int currentIndex: NotificationService.activeCallIndex

    implicitWidth: 560
    implicitHeight: 75

    readonly property var callInfo: NotifUtils.parseCallInfo(callData)
    readonly property string avatarUrl: callData && callData.image ? callData.image : ""
    readonly property string iconFallback: callData ? NotificationService.iconSource(callData.desktopEntry, callData.appIcon) : ""

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 10
        anchors.bottomMargin: totalCalls > 1 ? 8 : 10
        spacing: 4

        // Main Call Card Content Row
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // Profile Avatar / App Icon (44x44, circular)
            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                Layout.alignment: Qt.AlignVCenter
                radius: 22
                color: Theme.surfaceVariant
                border.width: 1
                border.color: Theme.borderSubtle
                clip: true

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: root.avatarUrl || root.iconFallback
                    sourceSize.width: 88
                    sourceSize.height: 88
                    asynchronous: true
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: avatarImg.status !== Image.Ready
                    text: "󰂚"
                    font.family: Theme.iconFont
                    font.pixelSize: 20
                    color: Theme.accent
                }
            }

            // Caller Details (Middle)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                // Origin / platform ("WhatsApp / Zen Browser")
                Text {
                    Layout.fillWidth: true
                    text: root.callInfo.origin
                    color: Theme.textMuted
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                // Caller Name
                Text {
                    Layout.fillWidth: true
                    text: root.callInfo.caller
                    color: Theme.textPrimary
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            // Action Buttons (Right)
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 12

                // Ignore Button
                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 18
                    color: ignoreMouse.containsMouse ? Theme.surfaceVariant : Theme.surface
                    border.width: 1
                    border.color: Theme.borderSubtle

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationFast }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.iconFont
                        font.pixelSize: 16
                        color: Theme.textSecondary
                    }

                    MouseArea {
                        id: ignoreMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationService.ignoreCall()
                    }
                }

                // Answer / Switch Button
                Rectangle {
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 36
                    radius: 18
                    color: answerMouse.containsMouse ? Theme.accentHover : Theme.accent

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationFast }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "󰏲"
                            font.family: Theme.iconFont
                            font.pixelSize: 15
                            color: Theme.background
                        }

                        Text {
                            text: "Answer"
                            font.pixelSize: 13
                            font.bold: true
                            color: Theme.background
                        }
                    }

                    MouseArea {
                        id: answerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationService.answerCall()
                    }
                }
            }
        }

        // Bottom Pagination Row: [Chevron Left] [Dots] [Chevron Right]
        RowLayout {
            visible: root.totalCalls > 1
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            // Prev Chevron (Bottom Left)
            Rectangle {
                implicitWidth: 22
                implicitHeight: 22
                radius: 11
                color: prevMouse.containsMouse ? Theme.surfaceVariant : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Theme.iconFont
                    font.pixelSize: 15
                    color: Theme.textSecondary
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.prevCall()
                }
            }

            // Pagination Dots
            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Repeater {
                    model: root.totalCalls

                    Item {
                        required property int index
                        width: 16
                        height: 16

                        Rectangle {
                            anchors.centerIn: parent
                            width: index === root.currentIndex ? 16 : 6
                            height: 6
                            radius: 3
                            color: index === root.currentIndex ? Theme.accent : Theme.surfaceVariant

                            Behavior on width {
                                NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic }
                            }
                            Behavior on color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.setCallIndex(index)
                        }
                    }
                }
            }

            // Next Chevron (Bottom Right)
            Rectangle {
                implicitWidth: 22
                implicitHeight: 22
                radius: 11
                color: nextMouse.containsMouse ? Theme.surfaceVariant : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    font.family: Theme.iconFont
                    font.pixelSize: 15
                    color: Theme.textSecondary
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.nextCall()
                }
            }
        }
    }
}
