import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

import "../../styles"
import "../../core"
import "../../island"

FocusScope {
    id: root
    implicitWidth: grid.implicitWidth + 20
    implicitHeight: grid.implicitHeight + 16

    Component.onCompleted: forceActiveFocus()
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            IslandController.closeTrayItemMenu()
            event.accepted = true
        }
    }

    readonly property var items: SystemTray.items ? SystemTray.items.values : []

    GridLayout {
        id: grid
        anchors.centerIn: parent
        columns: Math.min(4, Math.max(1, root.items.length))
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: root.items
            delegate: TrayIcon {
                item: modelData
            }
        }
    }
}
