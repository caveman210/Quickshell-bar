import QtQuick

import "../../styles"
import "../../services"
import "../../services/audio"

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

    // 16px icon slot width + spacing between multiple icons on the same side
    readonly property real slotWidth: 20
    readonly property real itemSpacing: 6

    readonly property int leftCount: split
        ? (micLive ? 1 : 0)
        : ((micLive ? 1 : 0) + (cameraLive ? 1 : 0) + (castLive ? 1 : 0))
    readonly property int rightCount: split
        ? ((cameraLive ? 1 : 0) + (castLive ? 1 : 0))
        : 0

    // Dynamic width according to number of active icons
    readonly property real leftWidth: leftCount > 0
        ? (leftCount * slotWidth + (leftCount - 1) * itemSpacing)
        : 0

    readonly property real rightWidth: rightCount > 0
        ? (rightCount * slotWidth + (rightCount - 1) * itemSpacing)
        : 0

    implicitWidth: leftWidth + rightWidth
    implicitHeight: 24

    TextMetrics {
        id: batteryRef
        font.family: Theme.iconFontMono
        font.pixelSize: 16
        text: "󰁺"
    }

    Row {
        id: leftSlot
        spacing: root.itemSpacing
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Item {
            id: micSlot
            width: root.slotWidth
            height: 24
            visible: root.micLive

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
                font.family: Theme.iconFontMono
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
            width: root.slotWidth
            height: 24
            visible: !root.split && root.cameraLive

            Text {
                anchors.centerIn: parent
                visible: !root.split && root.cameraLive
                text: "󰄀"
                color: Theme.success
                font.family: Theme.iconFontMono
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
            width: root.slotWidth
            height: 24
            visible: !root.split && root.castLive

            Text {
                anchors.centerIn: parent
                visible: !root.split && root.castLive
                text: "󰄘"
                color: Theme.danger
                font.family: Theme.iconFontMono
                font.pixelSize: 16

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationFast
                    }
                }
            }
        }
    }

    Row {
        id: rightSlot
        spacing: root.itemSpacing
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.split && (root.cameraLive || root.castLive)

        Item {
            id: castRightSlot
            width: root.slotWidth
            height: 24
            visible: root.split && root.castLive

            Text {
                anchors.centerIn: parent
                visible: root.split && root.castLive
                text: "󰄘"
                color: Theme.danger
                font.family: Theme.iconFontMono
                font.pixelSize: 16

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationFast
                    }
                }
            }
        }

        Item {
            id: cameraRightSlot
            width: root.slotWidth
            height: 24
            visible: root.split && root.cameraLive

            Text {
                anchors.centerIn: parent
                visible: root.split && root.cameraLive
                text: "󰄀"
                color: Theme.success
                font.family: Theme.iconFontMono
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