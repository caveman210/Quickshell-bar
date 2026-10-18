pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core"

Singleton {
    id: root
    property bool muted: false

    // Nerd Font glyph, matching the icons the island bar already uses.
    property string icon: muted ? "󰍭" : "󰍬"
    property string subtitle:
        muted
            ? "Muted"
            : "Enabled"

    // Set by toggle(), cleared by the next state read. The OSD has
    // to wait for the refreshTimer poll or it reports the pre-toggle
    // value back to the user.
    property bool _osdPending: false

    Process {
        id: micReader
        command: [
            "wpctl",
            "get-volume",
            "@DEFAULT_AUDIO_SOURCE@"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let output = text.trim()

                root.muted = output.indexOf("[MUTED]") !== -1

                if (root._osdPending) {
                    root._osdPending = false
                    root.showOsd()
                }
            }
        }
    }

    Process {
        id: micToggle
        command: [
            "wpctl",
            "set-mute",
            "@DEFAULT_AUDIO_SOURCE@",
            "toggle"
        ]

        onExited: {
            refreshTimer.restart()
        }
    }

    // Relaxed 10s safety poll (was 1s). Mute state is refreshed
    // immediately after every local toggle via refreshTimer.
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: update()
    }

    Timer {
        id: refreshTimer
        interval: 250
        repeat: false
        onTriggered: update()
    }

    function update() {
        micReader.running = false
        micReader.running = true
    }

    function toggle() {
        micToggle.running = false
        micToggle.running = true

        // Deferred: the state read below fires the toast once the
        // new mute value is known.
        root._osdPending = true
    }

    // Muted-while-idle leaves no persistent indicator state (the
    // glyph hides with no stream), so the toast is the only
    // confirmation a mute landed. Mirrors AudioService.showOsd().
    function showOsd() {
        StatusManager.show({
            mode: "microphone",
            icon: root.muted ? "󰍭" : "󰍬",
            title: root.muted ? "Muted" : "Enabled",
            statusWidth: 280,
            statusHeight: 33
        })
    }

    Component.onCompleted: update()
}
