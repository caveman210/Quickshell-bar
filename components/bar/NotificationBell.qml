import QtQuick

import "../../styles"
import "../../core"
import "../../services"
import "../../services/notification"
import "../../island"

// Bell icon in the bar, left of the clock: opens the notifications
// pane, with the unread count as an accent badge on the icon's
// top-right corner.
Item {
    id: root

    implicitWidth: 28
    implicitHeight: Theme.barHeight

    Text {
        id: glyph
        anchors.centerIn: parent
        text: "󰂚"
        color: Theme.textPrimary
        font.family: Theme.iconFont
        font.pixelSize: 16
    }

    Rectangle {
        id: badge

        readonly property int count: NotificationService.unreadCount
        readonly property bool inFocusMode: FocusService.enabled

        visible: count > 0
        x: Math.max(
            0,
            Math.min(
                Math.round(glyph.x + glyph.width - width / 2),
                root.width - width
            )
        )
        y: Math.round(glyph.y - height / 2 + 3)
        implicitWidth: inFocusMode ? 8 : Math.max(height, badgeText.implicitWidth + 8)
        width: implicitWidth
        height: inFocusMode ? 8 : 14
        radius: height / 2
        color: Theme.accent

        Text {
            id: badgeText
            visible: !badge.inFocusMode
            anchors.centerIn: parent
            text: badge.count > 99 ? "99+" : String(badge.count)
            color: Theme.background
            font.pixelSize: 9
            font.bold: true
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: function(event) {
            event.accepted = true

            if (IslandState.mode === IslandState.notificationsMode)
                IslandController.reset()
            else
                IslandController.openNotifications()
        }
    }
}
