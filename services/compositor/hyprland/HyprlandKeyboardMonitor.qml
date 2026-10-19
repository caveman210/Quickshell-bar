import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

// Reads the main keyboard's keymap from hyprctl and re-reads when
// the activelayout event fires.
Item {
    id: root

    property bool active: false

    signal keymapChanged(string name)

    function refresh() {
        if (!root.active)
            return

        if (reader.running)
            return

        reader.running = true
    }

    onActiveChanged: {
        if (active)
            root.refresh()
    }

    Connections {
        target: Hyprland
        enabled: root.active

        function onRawEvent(event) {
            if (event.name === "activelayout")
                root.refresh()
        }
    }

    Process {
        id: reader
        command: [
            "bash",
            "-c",
            "hyprctl -j devices | jq -r '.keyboards[] | select(.main == true) | .active_keymap'"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var keymap = text.trim()

                if (keymap.length > 0)
                    root.keymapChanged(keymap)
            }
        }
    }
}
