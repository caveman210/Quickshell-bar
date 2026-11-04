import QtQuick

import "../../styles"
import "../../island"

// Small dropdown to switch the island layout. It is positioned by the
// caller (x/y are set under the Layout card on open) and closes on
// selection via closed() or on outside taps.
Rectangle {
    id: root
    signal closed()

    implicitWidth: 190
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
            readonly property bool selected: IslandState.layout === IslandState.layoutPill
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
                text: ""
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
                    IslandState.layout = IslandState.layoutPill
                    root.closed()
                }
            }
        }

        Item {
            id: notchOption
            readonly property bool selected: IslandState.layout === IslandState.layoutNotch
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
                text: ""
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
                    IslandState.layout = IslandState.layoutNotch
                    root.closed()
                }
            }
        }

        Item {
            id: barOption
            readonly property bool selected: IslandState.layout === IslandState.layoutBar
            width: parent.width
            height: 38

            Rectangle {
                anchors.fill: parent
                radius: 9
                color: barOption.selected || barHover.hovered ? Theme.surfaceVariant : "transparent"
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Bar"
                color: Theme.textPrimary
                font.pixelSize: 13
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: barOption.selected
                text: ""
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 14
            }

            HoverHandler {
                id: barHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    IslandState.layout = IslandState.layoutBar
                    root.closed()
                }
            }
        }

        // Bar layout options (divider + style + edge toggles)
        Rectangle {
            visible: IslandState.layoutIsBar
            width: parent.width - 12
            height: 1
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.border
            opacity: 0.5
        }

        Item {
            id: barFloatingOption
            visible: IslandState.layoutIsBar
            width: parent.width
            height: 38

            Rectangle {
                anchors.fill: parent
                radius: 9
                color: floatingHover.hovered ? Theme.surfaceVariant : "transparent"
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: IslandState.barFloating ? "󰁅" : "󰁝"
                    color: Theme.icon
                    font.family: Theme.iconFont
                    font.pixelSize: 14
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: IslandState.barFloating ? "Floating" : "Attached"
                    color: Theme.textPrimary
                    font.pixelSize: 13
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 18
                radius: 9
                color: IslandState.barFloating ? Theme.accent : Theme.surfaceVariant

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    anchors.verticalCenter: parent.verticalCenter
                    x: IslandState.barFloating ? parent.width - width - 2 : 2
                    color: IslandState.barFloating ? Theme.background : Theme.textMuted

                    Behavior on x {
                        NumberAnimation { duration: 120 }
                    }
                }
            }

            HoverHandler {
                id: floatingHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    IslandState.barFloating = !IslandState.barFloating
                }
            }
        }

        Item {
            id: barEdgeOption
            visible: IslandState.layoutIsBar
            width: parent.width
            height: 38

            Rectangle {
                anchors.fill: parent
                radius: 9
                color: edgeHover.hovered ? Theme.surfaceVariant : "transparent"
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Placement.icon
                    color: Theme.icon
                    font.family: Theme.iconFont
                    font.pixelSize: 14
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Placement.bottom ? "Bottom Edge" : "Top Edge"
                    color: Theme.textPrimary
                    font.pixelSize: 13
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 18
                radius: 9
                color: Placement.bottom ? Theme.accent : Theme.surfaceVariant

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    anchors.verticalCenter: parent.verticalCenter
                    x: Placement.bottom ? parent.width - width - 2 : 2
                    color: Placement.bottom ? Theme.background : Theme.textMuted

                    Behavior on x {
                        NumberAnimation { duration: 120 }
                    }
                }
            }

            HoverHandler {
                id: edgeHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    Placement.toggle()
                }
            }
        }
    }
}
