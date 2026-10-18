import QtQuick

import "../styles"

// Icon is always a Nerd Font glyph for the same reason as
// ControlCard: the old SVG recolor path (MultiEffect) is a no-op on
// this setup, so an SVG icon would render black regardless.
Rectangle {
    id: root
    property string icon: ""
    property real value: 0.5

    // Volume and brightness icons stay dark against the light track
    // fill and flip to textPrimary once the level drops under 10%.
    readonly property color iconColor:
        value < 0.1
            ? Theme.textPrimary
            : Theme.background

    signal valueChangedByUser(real value)
    signal iconClicked
    implicitWidth: 473
    implicitHeight: 35
    radius: 20
    color: Theme.surface

    Rectangle {
        width: root.value > 0
            ? Math.max(parent.height, parent.width * root.value)
            : 0
        height: parent.height
        radius: height / 2
        color: Theme.accent
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        font.family: Theme.iconFont
        font.pixelSize: 18
        color: root.iconColor

        Behavior on color {
            ColorAnimation {
                duration: Theme.animationFast
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onPressed: function(mouse) {
            updateValue(mouse.x)
        }

        onPositionChanged: function(mouse) {
            if (pressed)
                updateValue(mouse.x)
        }

        function updateValue(x) {
            let newValue =
                Math.max(
                    0,
                    Math.min(
                        1,
                        x / root.width
                    )
                )

            root.value = newValue

            root.valueChangedByUser(newValue)
        }
    }

    MouseArea {
        id: iconArea
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 46
        height: parent.height
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onPressed: function(mouse) {
            mouse.accepted = true
        }

        onClicked: function(mouse) {
            mouse.accepted = true
            root.iconClicked()
        }
    }
}
