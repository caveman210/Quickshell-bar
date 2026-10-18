import QtQuick

import "../styles"
import "../services"

// Privacy indicators pinned to the bar ends. Mic sits in a slot on
// the far left; camera + screen-share go to the far right in split
// mode (the pill). The notch already spends its right end on the
// battery glyph, so it sets split: false and keeps everything on
// the left.
//
// Every glyph occupies the same box as the battery icon: the slot
// width is measured from the battery glyph's own advance width
// rather than hardcoded, so the icons line up with it if the font
// or size ever changes.
//
// Slots stay reserved once anything goes live, so a second device
// filling the opposite side never resizes the bar again and the
// clock never shifts mid-call.
//
// Mic is the only clickable one: it toggles mute. Camera and
// screen-share are read-only progress readouts and carry no
// handler, so they never invite a click they cannot honor.
Item {
    id: root

    // Muted wins over live so a muted mic during a call shows red
    // rather than green — the "forced mute" state.
    readonly property bool micMuted: MicrophoneService.muted
    readonly property bool micLive: PrivacyService.micActive
    readonly property bool cameraLive: PrivacyService.cameraActive
    readonly property bool castLive:
        PrivacyService.screenSharingActive

    // Camera/cast ride the right end; otherwise they stay on the
    // left beside the mic (notch, where the battery owns the right).
    property bool split: true

    // Anything live expands the bar; all idle collapses it.
    readonly property bool anyActive:
        micLive || cameraLive || castLive

    // Measured from the battery glyph itself rather than hardcoded.
    // This font is monospace, so one measurement covers mic, camera
    // and cast as well.
    readonly property real slotWidth: batteryRef.advanceWidth

    // Reserved slot runs, deliberately independent of what is
    // currently visible: filling the second slot must never resize
    // the bar. Split mode spends the right end on camera + cast; the
    // notch groups all three on the left because its right end
    // already belongs to the battery glyph.
    readonly property real leftWidth:
        split ? slotWidth : slotWidth * 3

    readonly property real rightWidth: split ? slotWidth * 2 : 0

    implicitWidth: leftWidth + rightWidth
    implicitHeight: 24

    TextMetrics {
        id: batteryRef
        font.family: Theme.iconFont
        font.pixelSize: 16
        text: "󰁺"
    }

    Row {
        id: leftSlot
        spacing: 0
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Item {
            id: micSlot
            width: root.slotWidth
            height: 24

            HoverHandler {
                id: micHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                id: micTap
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.ReleaseWithinBounds

                onTapped: function(event) {
                    event.accepted = true
                    MicrophoneService.toggle()
                }
            }

            Text {
                id: micText
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

            // Hover/press feedback so the mute target reads as
            // interactive rather than a passive indicator.
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: 6
                color: "transparent"
                border.width: 1
                border.color: micHover.hovered
                                  ? Theme.border
                                  : "transparent"

                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.animationFast
                    }
                }
            }

            scale: micTap.pressed ? 0.88 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Item {
            id: cameraLeftSlot
            width: !root.split ? root.slotWidth : 0
            height: 24

            Text {
                anchors.centerIn: parent
                visible: !root.split && root.cameraLive
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
            id: castLeftSlot
            width: !root.split ? root.slotWidth : 0
            height: 24

            Text {
                anchors.centerIn: parent
                visible: !root.split && root.castLive
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

    Item {
        id: rightSlot
        width: root.rightWidth
        height: 24
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        // Camera takes the outermost slot so it sits flush against
        // the end exactly like the battery glyph; screen-share fills
        // inboard of it.
        Item {
            id: cameraRightSlot
            width: root.split ? root.slotWidth : 0
            height: 24
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                visible: root.split && root.cameraLive
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
            id: castRightSlot
            width: root.split ? root.slotWidth : 0
            height: 24
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                visible: root.split && root.castLive
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
}