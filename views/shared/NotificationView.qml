import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../services"
import "../../services/notification"

Item {
    id: root

    // Full height of the notification stack; lets the Control
    // Center size its pane to the number of notifications.
    readonly property real listContentHeight: list.contentHeight

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Notifications"
                color: Theme.textPrimary
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: 90
                implicitHeight: 32
                radius: Theme.radiusSmall
                color: Theme.buttonBackground
                border.width: clearMouse.containsMouse ? 1 : 0
                border.color: Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: "Clear All"
                    color: clearMouse.containsMouse
                           ? Theme.textPrimary
                           : Theme.buttonText
                    font.pixelSize: 13
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.clear()
                }
            }
        }

        // ListView is already scrollable — no ScrollView wrapper.
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: NotificationService.conversations
            spacing: 10

            delegate: Rectangle {
                id: card

                readonly property string groupKey: model.key

                // Re-read whenever the service bumps revision.
                property var groupMessages: {
                    var r = NotificationService.revision
                    return NotificationService.messagesFor(card.groupKey)
                }

                width: list.width
                height: content.implicitHeight + 24
                radius: 12
                color: Theme.card

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.toggleGroup(card.groupKey)
                }

                ColumnLayout {
                    id: content
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: 22
                            clip: true
                            color: Theme.surfaceVariant
                            border.width: model.highPriority ? 2 : 1
                            border.color: model.highPriority
                                ? Theme.danger
                                : Theme.borderSubtle

                            Image {
                                id: appIconImage

                                // Falls back to the app icon when the
                                // saved avatar blob is missing (e.g.
                                // the cache was cleaned by hand).
                                property string failedAsset: ""
                                readonly property bool hasAvatar: model.avatarAsset !== ""
                                    && failedAsset !== model.avatarAsset

                                anchors.fill: parent
                                anchors.margins: hasAvatar ? 0 : 9
                                source: hasAvatar
                                    ? NotificationService.assetUrl(
                                          model.avatarAsset
                                      )
                                    : NotificationService.iconSource(
                                          model.desktopEntry,
                                          model.appIcon
                                      )
                                sourceSize.width: 64
                                sourceSize.height: 64
                                asynchronous: true
                                cache: true
                                fillMode: Image.PreserveAspectFit
                                visible: status === Image.Ready

                                onStatusChanged: {
                                    if (status === Image.Error && model.avatarAsset !== "")
                                        failedAsset = model.avatarAsset
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: appIconImage.status !== Image.Ready
                                text: "󰂚"
                                font.family: Theme.iconFont
                                font.pixelSize: 20
                                color: Theme.icon
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: model.title
                                    color: Theme.textPrimary
                                    font.bold: true
                                    font.pixelSize: 14
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Rectangle {
                                    visible: model.highPriority
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitWidth: priorityText.implicitWidth + 14
                                    implicitHeight: 18
                                    radius: 9
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Theme.danger

                                    Text {
                                        id: priorityText
                                        anchors.centerIn: parent
                                        text: "High priority"
                                        color: Theme.danger
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }

                            Text {
                                text: model.preview
                                color: Theme.textSecondary
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        // Right meta column: time with the dismiss
                        // button to its right; the message count +
                        // expand chevron sit right below the time.
                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: 5

                            RowLayout {
                                spacing: 10

                                Text {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: NotificationService.formatTime(model.ts)
                                    color: Theme.textMuted
                                    font.pixelSize: 11
                                }

                                Item {
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Theme.radiusSmall
                                        color: "transparent"
                                        border.width: removeMouse.containsMouse ? 1 : 0
                                        border.color: Theme.borderHover

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            font.family: Theme.iconFont
                                            font.pixelSize: 13
                                            color: removeMouse.containsMouse
                                                ? Theme.danger
                                                : Theme.icon
                                        }
                                    }

                                    MouseArea {
                                        id: removeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotificationService.removeGroup(
                                            card.groupKey
                                        )
                                    }
                                }
                            }

                            RowLayout {
                                spacing: 3
                                visible: model.msgCount > 1

                                Text {
                                    text: String(model.msgCount)
                                    color: Theme.textMuted
                                    font.pixelSize: 11
                                }

                                Text {
                                    text: model.collapsed ? "󰅀" : "󰅃"
                                    font.family: Theme.iconFont
                                    font.pixelSize: 12
                                    color: Theme.icon
                                }
                            }
                        }
                    }

                    // Expanded messages. Opacity dims closed ones
                    // (expired / dismissed / retracted).
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 56
                        visible: !model.collapsed && card.groupMessages.length > 0
                        spacing: 8

                        Repeater {
                            model: card.collapsed ? [] : card.groupMessages

                            delegate: ColumnLayout {
                                id: msgColumn

                                required property var modelData

                                Layout.fillWidth: true
                                spacing: 5
                                opacity: modelData.closed ? 0.55 : 1

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        Layout.alignment: Qt.AlignTop
                                        text: NotificationService.formatTime(
                                            modelData.ts
                                        )
                                        color: Theme.textMuted
                                        font.pixelSize: 11
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: NotificationService.messageText(
                                            modelData
                                        )
                                        color: Theme.textSecondary
                                        font.pixelSize: 12
                                        textFormat: Text.RichText
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Image {
                                    visible: modelData.hasAsset
                                    source: modelData.hasAsset
                                        ? NotificationService.assetUrl(
                                            modelData.asset
                                        )
                                        : ""
                                    sourceSize.width: 640
                                    sourceSize.height: 640
                                    asynchronous: true
                                    cache: true
                                    fillMode: Image.PreserveAspectFit
                                    Layout.maximumWidth: 320
                                    Layout.maximumHeight: 240
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {
        anchors.centerIn: parent
        active: NotificationService.conversations.count === 0
        sourceComponent: emptyComponent
    }

    Component {
        id: emptyComponent

        Column {
            spacing: 8
            anchors.centerIn: parent

            Text {
                text: "󰂚"
                color: Theme.icon
                font.family: Theme.iconFont
                font.pixelSize: 36
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "No notifications"
                color: Theme.textSecondary
                font.pixelSize: 14
            }
        }
    }
}
