import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../core"
import "../../services/system"
import "../../styles"

// Minimal fastfetch pane, opened from the Control Center system card.
//
// The ASCII art is printed in a real monospace font at its natural
// metrics: no scaling, no Layout.fillWidth, no fixed line height. That
// is what keeps the block glyphs square and the drawing undistorted.
FocusScope {
    id: root

    readonly property int logoPixelSize: 10

    readonly property real screenWidth: Quickshell.screens.length > 0
        ? Quickshell.screens[0].width
        : 1920

    // Grow to fit the widest info row instead of eliding it. `content`
    // is the art + info row; the outer chrome is 22px layout margins
    // plus 14px card padding on each side (72px total).
    implicitWidth: Math.min(
        Math.max(560, Math.ceil(content.implicitWidth) + 72),
        0.92 * screenWidth
    )

    readonly property real maxViewHeight: 0.65 * (
        Quickshell.screens.length > 0
            ? Quickshell.screens[0].height
            : 1080
    )

    implicitHeight: Math.min(layout.implicitHeight + 44, maxViewHeight)

    readonly property var rows: [
        { label: "OS", value: SystemService.details.os || "—" },
        { label: "Kernel", value: SystemService.details.kernel || "—" },
        { label: "WM", value: SystemService.details.wm || "—" },
        { label: "CPU", value: SystemService.details.cpu || "—" },
        { label: "GPU", value: SystemService.details.gpu || "—" },
        { label: "Memory", value: SystemService.details.memory || "—" }
    ]

    // Data comes from SystemService's disk cache; the pane never
    // triggers a fetch on its own. The weekly timer in the service and
    // the refresh button below are the only things that re-run
    // fastfetch.
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
        anchors.margins: 22
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: SystemService.osIcon
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 22
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "System"
                color: Theme.textPrimary
                font.pixelSize: 20
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            // Manual refresh — always re-runs fastfetch and rewrites
            // the cache, regardless of the weekly timer.
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                HoverHandler {
                    id: refreshHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: SystemService.refreshNow()
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: "\uf021"
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 13
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: SystemService.refreshing ? "refreshing…" : "refresh"
                    color: refreshHover.hovered && !SystemService.refreshing
                        ? Theme.accent
                        : Theme.textSecondary
                    font.pixelSize: 11
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: content.implicitHeight + 28
            radius: 14
            color: Theme.surface
            clip: true

            RowLayout {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 20

                Text {
                    Layout.alignment: Qt.AlignTop
                    text: SystemService.logo !== ""
                        ? SystemService.logo
                        : (SystemService.loaded
                            ? "Logo unavailable"
                            : "Reading system…")
                    color: SystemService.logo !== ""
                        ? Theme.textPrimary
                        : Theme.textMuted
                    font.family: Theme.iconFontMono
                    font.pixelSize: SystemService.logo !== ""
                        ? root.logoPixelSize
                        : 12
                    textFormat: Text.PlainText
                    wrapMode: Text.NoWrap
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 10

                    Repeater {
                        model: root.rows

                        delegate: RowLayout {
                            required property var modelData

                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                Layout.preferredWidth: 88
                                Layout.alignment: Qt.AlignTop
                                text: modelData.label
                                color: Theme.textMuted
                                font.pixelSize: 11
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                text: modelData.value
                                color: Theme.textPrimary
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
