import QtQuick

import "../styles"
import "../services"
import "../island"
import "../core"

// Dropdown control for the expanded bar: the privacy glyphs sit in
// battery-sized slots and only while the device is actually in use.
// Hovering one raises a tooltip, clicking anywhere on the cluster
// opens the full privacy panel.
//
// The tooltip is anchored to the cluster's left and vertically
// centered rather than below it: the island is masked to the capsule
// Region (IslandWindow) and Island clips, so anything drawn past the
// ~75px expanded bar height is cut off. Sitting beside the cluster
// keeps it inside that band at every size.
Item {
    id: root

    readonly property bool micMuted: MicrophoneService.muted
    readonly property bool micLive: PrivacyService.micActive
    readonly property bool cameraLive: PrivacyService.cameraActive
    readonly property bool castLive:
        PrivacyService.screenSharingActive

    readonly property bool anyActive:
        micLive || cameraLive || castLive

    // "" | "mic" | "camera" | "cast"
    property string hovered: ""

    TextMetrics {
        id: batteryRef
        font.family: Theme.iconFont
        font.pixelSize: 16
        text: "󰁺"
    }

    readonly property real slotWidth: batteryRef.advanceWidth

    implicitWidth: anyActive ? row.implicitWidth : 0
    implicitHeight: 32

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: 10
        color: root.hovered !== "" || clusterHover.hovered
               ? Theme.surfaceVariant
               : Theme.surface

        Behavior on color {
            ColorAnimation {
                duration: Theme.animationFast
            }
        }
    }

    HoverHandler {
        id: clusterHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: function(event) {
            event.accepted = true

            if (IslandState.mode === IslandState.privacyMenuMode)
                return

            IslandController.openPrivacyMenuFromRightSection()
        }
    }

    Row {
        id: row
        visible: root.anyActive
        spacing: 0
        anchors.centerIn: parent

        Item {
            width: root.slotWidth
            height: 32

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
                onHoveredChanged: {
                    root.hovered = hovered ? "mic" : ""
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.micLive
                text: root.micMuted ? "󰍭" : "󰍬"
                color: root.micMuted ? Theme.danger : Theme.success
                font.family: Theme.iconFont
                font.pixelSize: 16

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationFast
                    }
                }
            }
        }

        Item {
            width: root.slotWidth
            height: 32

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
                onHoveredChanged: {
                    root.hovered = hovered ? "camera" : ""
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.cameraLive
                text: "󰄀"
                color: Theme.success
                font.family: Theme.iconFont
                font.pixelSize: 16

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationFast
                    }
                }
            }
        }

        Item {
            width: root.slotWidth
            height: 32

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
                onHoveredChanged: {
                    root.hovered = hovered ? "cast" : ""
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.castLive
                text: "󰄘"
                color: Theme.danger
                font.family: Theme.iconFont
                font.pixelSize: 16

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationFast
                    }
                }
            }
        }
    }

    PrivacyTooltip {
        id: tooltip

        // Parked off to the side while hidden so it can't influence
        // the cluster's implicit size.
        x: root.hovered !== ""
               ? -(width + 8)
               : 0
        y: (root.height - height) / 2
        z: 500

        opacity: root.hovered !== "" ? 1 : 0

        title: {
            switch (root.hovered) {
            case "mic":
                return "Microphone"
            case "camera":
                return "Camera"
            case "cast":
                return "Screen Share"
            default:
                return ""
            }
        }

        detail: {
            switch (root.hovered) {
            case "mic":
                if (root.micMuted)
                    return "Muted"

                return root.micLive ? "In use" : "Idle"

            case "camera":
                return root.cameraLive ? "In use" : "Idle"

            case "cast":
                return root.castLive ? "Sharing" : "Idle"

            default:
                return ""
            }
        }
    }
}