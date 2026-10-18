import QtQuick

import "../styles"

// Hover tooltip for the expanded bar's privacy cluster. Lives inside
// the island capsule (the window is masked to the capsule Region in
// IslandWindow, and Island clips too), so it stays short and anchors
// just below the icon.
Rectangle {
    id: root

    property string title: ""
    property string detail: ""

    visible: opacity > 0
    radius: Theme.radiusSmall
    color: Theme.card
    border.width: 1
    border.color: Theme.border

    implicitWidth: Math.max(titleMetrics.width, detailMetrics.width) + 20
    implicitHeight: (titleMetrics.height + detailMetrics.height) + 14

    opacity: 0
    scale: opacity > 0 ? 1.0 : 0.94

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.animationFast
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.animationFast
            easing.type: Easing.OutCubic
        }
    }

    // Measures with the same fonts as the display text so
    // implicitWidth fits the longest line exactly.
    TextMetrics {
        id: titleMetrics
        font.pixelSize: 11
        font.weight: Font.Medium
        elide: Text.ElideNone
        text: root.title
    }

    TextMetrics {
        id: detailMetrics
        font.pixelSize: 11
        elide: Text.ElideNone
        text: root.detail
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            text: root.title
            color: Theme.textPrimary
            font.pixelSize: 11
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.detail
            color: Theme.textSecondary
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }
}