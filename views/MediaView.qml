import QtQuick
import QtQuick.Layouts

import "../components"
import "../services"
import "../styles"

Item {
    id: root
    implicitWidth: 520
    implicitHeight: 145

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            MediaHeader {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.topMargin: 10
                spacing: 14

                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: Theme.surface

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        color: Theme.textPrimary
                        font.family: Theme.iconFont
                        font.pixelSize: 18
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: MediaService.previousTrack()
                    }
                }

                Rectangle {
                    width: 42
                    height: 42
                    radius: 21
                    color: Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: MediaService.isPlaying
                              ? "󰏤"
                              : "󰐊"
                        color: Theme.background
                        font.family: Theme.iconFont
                        font.pixelSize: 20
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton

                        onTapped: {
                            MediaService.togglePlayback()
                        }
                    }
                }

                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color:  Theme.surface

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        color: Theme.textPrimary
                        font.family: Theme.iconFont
                        font.pixelSize: 18
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: MediaService.nextTrack()
                    }
                }
            }
        }

        WaveformProgress {
            Layout.fillWidth: true
        }
    }
}
