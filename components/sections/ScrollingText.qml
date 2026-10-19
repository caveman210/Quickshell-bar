import QtQuick

import "../../styles"

Item {
    id: root
    property string text: ""
    property int maxWidth: 100
    property int fontSize: 13
    property bool hovered: false
    width: maxWidth
    implicitHeight: label.implicitHeight
    clip: true

    Text {
        id: label
        text: root.text
        color: Theme.textPrimary
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: root.fontSize
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
        x: 0
    }

    SequentialAnimation {
        id: scrollAnimation
        loops: Animation.Infinite

        NumberAnimation {
            target: label
            property: "x"
            to: -(label.width - root.maxWidth)
            duration: 8000
            easing.type: Easing.Linear
        }

        PauseAnimation {
            duration: 2000
        }

        NumberAnimation {
            target: label
            property: "x"
            to: 0
            duration: 8000
            easing.type: Easing.Linear
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    function isHovered() {
        return root.hovered || hoverHandler.hovered
    }

    function shouldScroll() {
        return isHovered() && label.width > root.maxWidth + 20
    }

    function updateScroll() {
        scrollAnimation.stop()
        label.x = 0

        if (root.visible && shouldScroll())
            scrollAnimation.start()
    }

    onTextChanged: updateScroll()

    onVisibleChanged: updateScroll()

    // Restart scrolling only after the Text item has been laid out.
    // The width is not updated immediately when the text changes.
    Connections {
        target: label

        function onWidthChanged() {
            updateScroll()
        }
    }

    onHoveredChanged: updateScroll()

    Connections {
        target: hoverHandler

        function onHoveredChanged() {
            updateScroll()
        }
    }
}
