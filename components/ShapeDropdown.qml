import QtQuick

import "../styles"
import "../island"

// Small dropdown to switch the island shape back and forth. It is
// positioned by the caller (x/y are set under the Shape card on
// open) and closes on selection via closed() or on outside taps.
Rectangle {
    id: root
    signal closed()

    implicitWidth: 170
    implicitHeight: options.implicitHeight + 16
    width: implicitWidth
    height: implicitHeight
    radius: 14
    color: Theme.card
    border.width: 1
    border.color: Theme.border

    Column {
        id: options
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 2

        Item {
            id: pillOption
            readonly property bool selected: IslandState.shape === IslandState.shapePill
            width: parent.width
            height: 38

            Rectangle {
                anchors.fill: parent
                radius: 9
                color: pillOption.selected || pillHover.hovered ? Theme.surfaceVariant : "transparent"
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Pill"
                color: Theme.textPrimary
                font.pixelSize: 13
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: pillOption.selected
                text: ""
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 14
            }

            HoverHandler {
                id: pillHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    IslandState.shape = IslandState.shapePill
                    root.closed()
                }
            }
        }

        Item {
            id: notchOption
            readonly property bool selected: IslandState.shape === IslandState.shapeNotch
            width: parent.width
            height: 38

            Rectangle {
                anchors.fill: parent
                radius: 9
                color: notchOption.selected || notchHover.hovered ? Theme.surfaceVariant : "transparent"
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Notch"
                color: Theme.textPrimary
                font.pixelSize: 13
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: notchOption.selected
                text: ""
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 14
            }

            HoverHandler {
                id: notchHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    IslandState.shape = IslandState.shapeNotch
                    root.closed()
                }
            }
        }
    }
}
