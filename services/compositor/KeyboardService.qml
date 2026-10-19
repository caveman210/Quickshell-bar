import QtQuick
import "../../core"
import "../compositor/hyprland"
import "../compositor/niri"

// Thin facade: the compositor monitors resolve the raw keymap name
// (niri: keyboard-layouts JSON, Hyprland: hyprctl devices) and emit
// it here; this service normalizes it and announces switches.
Item {
    id: root
    property string layout: "EN"
    property string fullName: "English"
    property string icon: "󰌌"
    property string lastLayout: ""

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
        niriKeys.refresh()
        hyprKeys.refresh()
    }

    NiriKeyboardMonitor {
        id: niriKeys
        active: CompositorService.isNiri

        onKeymapChanged: function(name) {
            root.applyKeymap(name)
        }
    }

    HyprlandKeyboardMonitor {
        id: hyprKeys
        active: CompositorService.isHyprland

        onKeymapChanged: function(name) {
            root.applyKeymap(name)
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
