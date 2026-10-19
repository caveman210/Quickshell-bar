import QtQuick
import Quickshell.Io

// Reads the active niri keyboard layout and re-reads when the
// event stream reports a layout change.
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

    NiriEventStream {
        active: root.active

        onLineRead: function(line) {
            if (line.indexOf("KeyboardLayoutsChanged") !== -1)
                root.refresh()
        }
    }

    Process {
        id: reader
        command: ["niri", "msg", "--json", "keyboard-layouts"]

        stdout: StdioCollector {
            onStreamFinished: {
                // {"names": ["English (US)", ...], "current_idx": 0}
                // Anything else is a CLI error — ignore it.
                try {
                    var parsed = JSON.parse(text.trim())

                    if (parsed.names && parsed.current_idx !== undefined)
                        root.keymapChanged(parsed.names[parsed.current_idx] || "")
                } catch (err) {}
            }
        }
    }
}
