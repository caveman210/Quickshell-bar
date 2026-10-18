import QtQuick
import QtQuick.Layouts

import "../components"
import "../services"
import "../core"
import "../styles"

// Full privacy panel, opened from the expanded bar's privacy cluster
// or via IPC. One row per capture device: current state plus which
// applications are holding it open.
//
// App lists come from the PipeWire stream pass only, so a device
// claimed through a direct /dev/video* or ALSA open shows "In use"
// with no applications listed.
FocusScope {
    id: root

    property int selectedRow: 0
    readonly property int rowCount: 3

    implicitWidth: 560
    implicitHeight: 300

    Component.onCompleted: {
        forceActiveFocus()
    }

    Keys.onPressed: function(event) {
        switch (event.key) {
        case Qt.Key_Left:
        case Qt.Key_H:

            root.selectedRow =
                (root.selectedRow + root.rowCount - 1) % root.rowCount

            event.accepted = true
            break

        case Qt.Key_Right:
        case Qt.Key_L:

            root.selectedRow =
                (root.selectedRow + 1) % root.rowCount

            event.accepted = true
            break

        case Qt.Key_Return:
        case Qt.Key_Enter:

            // Only the microphone row carries an action; the other
            // two are read-only readouts.
            if (root.selectedRow === 0)
                MicrophoneService.toggle()

            event.accepted = true
            break

        case Qt.Key_Escape:

            IslandController.reset()

            event.accepted = true
            break
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 16

        Text {
            text: "Privacy"
            color: Theme.textPrimary
            font.pixelSize: 20
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 58
            radius: 14
            color: Theme.surface
            border.width: 1
            border.color: root.selectedRow === 0
                              ? Theme.borderSelected
                              : Theme.border

            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 12

                Text {
                    text: MicrophoneService.muted ? "󰍭" : "󰍬"
                    color: MicrophoneService.muted
                          ? Theme.danger
                          : Theme.success
                    font.family: Theme.iconFont
                    font.pixelSize: 18
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Microphone"
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: PrivacyService.micActive
                                ? MicrophoneService.muted
                                    ? "Muted — capture is live"
                                    : "In use"
                                : "Idle"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Repeater {
                    model: PrivacyService.micApps

                    Rectangle {
                        required property string modelData

                        implicitWidth: chipText.implicitWidth + 14
                        implicitHeight: 22
                        radius: 11
                        color: Theme.surfaceVariant

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: Theme.textSecondary
                            font.pixelSize: 10
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 86
                    implicitHeight: 30
                    radius: 15
                    color: MicrophoneService.muted
                          ? Theme.accent
                          : Theme.buttonBackground

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animationFast
                        }
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: function(event) {
                            event.accepted = true
                            MicrophoneService.toggle()
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: MicrophoneService.muted
                              ? "Unmute"
                              : "Mute"
                        color: MicrophoneService.muted
                              ? Theme.background
                              : Theme.textPrimary
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 58
            radius: 14
            color: Theme.surface
            border.width: 1
            border.color: root.selectedRow === 1
                              ? Theme.borderSelected
                              : Theme.border

            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 12

                Text {
                    text: "󰄀"
                    color: PrivacyService.cameraActive
                          ? Theme.success
                          : Theme.iconDisabled
                    font.family: Theme.iconFont
                    font.pixelSize: 18
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Camera"
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: PrivacyService.cameraActive
                                ? "In use"
                                : "Idle"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Repeater {
                    model: PrivacyService.cameraApps

                    Rectangle {
                        required property string modelData

                        implicitWidth: chipText.implicitWidth + 14
                        implicitHeight: 22
                        radius: 11
                        color: Theme.surfaceVariant

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: Theme.textSecondary
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 58
            radius: 14
            color: Theme.surface
            border.width: 1
            border.color: root.selectedRow === 2
                              ? Theme.borderSelected
                              : Theme.border

            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 12

                Text {
                    text: "󰄘"
                    color: PrivacyService.screenSharingActive
                          ? Theme.danger
                          : Theme.iconDisabled
                    font.family: Theme.iconFont
                    font.pixelSize: 18
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Screen Share"
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: PrivacyService.screenSharingActive
                                ? PrivacyService.externalDisplayConnected
                                    && !PrivacyService._streamActive
                                    ? "External display connected"
                                    : "Screen is being captured"
                                : "Idle"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Text {
            Layout.fillWidth: true
            text: "Only captures claimed through PipeWire are attributed to an app. Direct device opens and root-owned captures are not listed."
            color: Theme.textMuted
            font.pixelSize: 10
            wrapMode: Text.WordWrap
        }
    }
}