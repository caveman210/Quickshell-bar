import QtQuick

import Quickshell

import "../../styles"
import "../shared"
import "../../services"
import "../../services/notification"

// Notifications-only pane (the Control Center's notification stack
// without the cards), opened from the bar's bell icon.
Item {
    id: root

    readonly property real maxViewHeight: Quickshell.screens.length > 0
        ? 0.65 * Quickshell.screens[0].height
        : 0.65 * 1080

    readonly property real paneHeight: Math.max(
        150, notifView.listContentHeight + 72
    )

    implicitWidth: 460
    implicitHeight: Math.min(paneHeight + 44, maxViewHeight)

    Rectangle {
        anchors.fill: parent
        anchors.margins: 22
        radius: 14
        color: Theme.surface
        clip: true

        NotificationView {
            id: notifView
            anchors.fill: parent
            anchors.margins: 14
        }
    }

    Component.onCompleted: NotificationService.markRead()
}
