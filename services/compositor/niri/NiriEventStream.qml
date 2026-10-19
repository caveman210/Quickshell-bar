import QtQuick
import Quickshell.Io

// Wraps `niri msg --json event-stream` as a reusable line source.
// Process.running is only ever set imperatively — the old facades
// bound it to a compositor check and restarted with
// running = false; running = true, which destroyed the binding.
// Set `active` instead.
Item {
    id: root

    property bool active: false

    readonly property bool running: process.running

    signal lineRead(string line)

    function start() {
        if (!active)
            return

        if (!process.running)
            process.running = true
    }

    function stop() {
        process.running = false
    }

    onActiveChanged: {
        if (active)
            root.start()
        else
            root.stop()
    }

    Component.onCompleted: root.start()

    Process {
        id: process
        command: ["niri", "msg", "--json", "event-stream"]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: function(line) {
                root.lineRead(line)
            }
        }

        onExited: {
            // Socket dropped (e.g. compositor restarted) — reconnect.
            reconnectTimer.restart()
        }
    }

    Timer {
        id: reconnectTimer
        interval: 2000
        repeat: false

        onTriggered: {
            root.start()
        }
    }
}
