import QtQuick

import "../../styles"

// Modern iOS / Android 17 style vertical pill slider
// Percentage display positioned neatly underneath the pill
Item {
    id: root
    property string icon: ""
    property real value: 0.5
    property bool dragging: false
    property real _dragValue: 0
    readonly property real displayValue: dragging ? _dragValue : value

    signal valueChangedByUser(real value)

    implicitWidth: 62
    implicitHeight: 168

    // The vertical pill track
    Rectangle {
        id: pillTrack
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 62
        height: 140
        radius: 20
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        clip: true

        // Accent fill rising from bottom
        Rectangle {
            id: fillBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.max(0, parent.height * root.displayValue)
            color: Theme.accent
            radius: 20

            Behavior on height {
                enabled: !root.dragging
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }

        // Bottom Icon
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            text: root.icon
            font.family: Theme.iconFont
            font.pixelSize: 20
            color: root.displayValue > 0.28 ? Theme.background : Theme.textPrimary
            z: 2
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onPressed: function(mouse) {
                root.dragging = true
                updateValue(mouse.y)
            }

            onPositionChanged: function(mouse) {
                if (pressed)
                    updateValue(mouse.y)
            }

            onReleased: root.dragging = false
            onCanceled: root.dragging = false

            function updateValue(y) {
                var fraction = 1 - (y / pillTrack.height)
                var clamped = Math.max(0, Math.min(1, fraction))
                root._dragValue = clamped
                root.valueChangedByUser(clamped)
            }
        }
    }

    // Percentage placed underneath the pill slider
    Text {
        anchors.top: pillTrack.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        text: Math.round(root.displayValue * 100) + "%"
        font.pixelSize: 12
        font.bold: true
        color: Theme.textSecondary
    }
}
