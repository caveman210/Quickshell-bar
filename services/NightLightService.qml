pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "."

Singleton {
    id: root

    // hyprsunset is Hyprland-only. Disabled on other compositors.
    property bool available: !CompositorService.isNiri
    property bool enabled: false
    property string subtitle: !available ? "N/A" : (enabled ? "On" : "Off")
    property string icon: enabled
        ? "󰔎"
        : "󰃞"

    Process {
        id: stateProcess
        command: [
            "bash",
            "-c",
            "pgrep -x hyprsunset >/dev/null && echo on || echo off"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.enabled = text.trim() === "on"
            }
        }
    }

    Process {
        id: toggleProcess

        onExited: {
            root.update()
        }
    }

    // No polling: toggle() sets `enabled` optimistically and
    // toggleProcess.onExited confirms via update(). An externally
    // killed hyprsunset won't reflect until the next toggle or
    // reload — accepted tradeoff for zero idle wakeups.
    function update() {
        if (!root.available)
            return

        stateProcess.running = false
        stateProcess.running = true
    }

    function toggle() {
        if (!root.available)
            return

        toggleProcess.running = false

        if (enabled) {
            enabled = false

            toggleProcess.command = [
                "pkill",
                "hyprsunset"
            ]
        } else {
            enabled = true

            toggleProcess.command = [
                "hyprsunset",
                "--temperature",
                "4500"
            ]
        }

        toggleProcess.running = true
    }

    Component.onCompleted: update()
}
