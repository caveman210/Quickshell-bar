import QtQuick
import Quickshell.Hyprland

// Translates Hyprland's raw workspace events into the same
// compositor-agnostic signals as the niri monitor.
Item {
    id: root

    property bool active: false

    // Hyprland reports the workspace by name directly.
    signal workspaceActivated(string name)

    Connections {
        target: Hyprland
        enabled: root.active

        function onRawEvent(event) {
            if (event.name === "workspace")
                root.workspaceActivated(event.data)
        }
    }
}
