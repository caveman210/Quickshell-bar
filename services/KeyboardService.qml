import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import "../core"
import "."

Item {
    id: root
    property string layout: "EN"
    property string fullName: "English"
    property string icon: "󰌌"
    property string lastLayout: ""

    function parseKeymap(rawText) {
        var text = rawText.trim()

        if (text.length === 0)
            return ""

        // Niri: {"names": ["English (US)", ...], "current_idx": 0}
        // Anything else from this backend is a CLI error — ignore it.
        if (CompositorService.isNiri) {
            try {
                var parsed = JSON.parse(text)

                if (parsed.names && parsed.current_idx !== undefined)
                    return parsed.names[parsed.current_idx] || ""
            } catch (err) {}

            return ""
        }

        // Hyprland: plain active_keymap string.
        return text
    }

    function applyKeymap(keymap) {
        if (!keymap || keymap.length === 0)
            return

        var newLayout = "EN"
        var newName = "English"

        if (keymap.startsWith("English")) {
            newLayout = "EN"
            newName = "English"
        } else if (
            keymap.startsWith("Persian") ||
            keymap.startsWith("Iranian")
        ) {
            newLayout = "FA"
            newName = "Persian"
        } else {
            newLayout = keymap.substring(0, 2).toUpperCase()
            newName = keymap
        }

        if (root.lastLayout === "") {
            root.lastLayout = newLayout
            root.layout = newLayout
            root.fullName = newName

            return
        }

        if (newLayout === root.lastLayout)
            return

        root.lastLayout = newLayout

        root.layout = newLayout
        root.fullName = newName

        StatusManager.show({
            mode: "keyboard",
            icon: root.icon,
            title: root.fullName,
            value: root.layout,
            statusWidth: 220,
            statusHeight: 33
        })
    }

    function refresh() {
        if (layoutReader.running)
            return

        layoutReader.running = false
        layoutReader.running = true
    }

    Process {
        id: layoutReader
        running: true
        command: CompositorService.isNiri ? [
            "niri",
            "msg",
            "--json",
            "keyboard-layouts"
        ] : [
            "bash",
            "-c",
            "hyprctl -j devices | jq -r '.keyboards[] | select(.main == true) | .active_keymap'"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.applyKeymap(root.parseKeymap(text))
            }
        }
    }

    // Hyprland: re-query only when the layout actually switches.
    Connections {
        enabled: CompositorService.isHyprland
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activelayout")
                root.refresh()
        }
    }

    // Niri: watch the compositor event stream for layout changes.
    Process {
        id: niriEventStream
        running: CompositorService.isNiri
        command: ["niri", "msg", "--json", "event-stream"]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: function(line) {
                if (line.indexOf("KeyboardLayoutsChanged") !== -1)
                    root.refresh()
            }
        }
    }

    // Safety net only (30s). Catches missed events, e.g. if the
    // compositor restarted and the stream is reconnecting.
    Timer {
        interval: 30000
        running: true
        repeat: true

        onTriggered: {
            root.refresh()
        }
    }
}
