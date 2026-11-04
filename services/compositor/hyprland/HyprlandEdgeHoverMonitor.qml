import QtQuick
import Quickshell
import Quickshell.Io

// Hyprland has no cursor-position binding, but it does expose
// `hyprctl cursorpos` — poll it while the island's reveal sources
// are active. This means the island window needs no input region
// on Hyprland at all: while hidden its mask maps the off-screen
// capsule, so every click passes straight through to the windows
// below. Niri uses the 1px EdgeTriggerWindow instead.
Item {
    id: root

    property bool active: false

    // Reveal edge: top by default, bottom for a bottom-docked island.
    property bool bottomEdge: false

    signal hoverChanged(bool hovered)

    readonly property real screenBottom: Quickshell.screens.length > 0
        ? Quickshell.screens[0].y + Quickshell.screens[0].height
        : 0

    function cursorAtEdge(y) {
        return root.bottomEdge ? y >= root.screenBottom - 1 : y <= 1
    }

    Timer {
        id: cursorPoll
        interval: 150
        repeat: true
        running: root.active

        onTriggered: {
            cursorProc.running = false
            cursorProc.running = true
        }
    }

    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos"]

        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.split(",")

                if (parts.length < 2)
                    return

                var y = parseInt(parts[1])

                if (isNaN(y))
                    return

                root.hoverChanged(root.cursorAtEdge(y))
            }
        }
    }
}
