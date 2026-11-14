import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

import "../../styles"
import "../../core"
import "../../island"

FocusScope {
    id: root
    implicitWidth: Math.max(120, grid.implicitWidth + 24)
    implicitHeight: Math.max(40, grid.implicitHeight + 20)

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
        columns: Math.min(5, Math.max(1, root.items.length))
        rowSpacing: 6
        columnSpacing: 6

        Repeater {
            model: root.items
            delegate: TrayIcon {
                item: modelData
            }
        }
    }

    Text {
        visible: root.items.length === 0
        anchors.centerIn: parent
        text: "No active tray icons"
        color: Theme.textMuted
        font.pixelSize: 12
    }
}
