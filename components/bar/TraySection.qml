import QtQuick

import Quickshell.Services.SystemTray

import "../../styles"
import "../../island"
import "../../core"

// System tray for the bar layout: every item renders inline, next to
// the power button. Clicking an icon drops that item's SNI menu right
// below it (TrayItemMenu, in the island's dropdown slot).
Item {
    id: root

    readonly property var items: SystemTray.items ? SystemTray.items.values : []

    // The open menu belongs to one of these items; if the tray
    // changes at all, close it rather than leave stale entries.
    onItemsChanged: {
        if (IslandState.trayItemMenu)
            IslandController.closeTrayItemMenu()
    }

    implicitWidth: inlineRow.implicitWidth
    implicitHeight: inlineRow.implicitHeight

    Row {
        id: inlineRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: root.items

            delegate: TrayIcon {
                item: modelData
            }
        }
    }
}
