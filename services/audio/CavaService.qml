pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import ".."

Singleton {
    id: root
    property var bars: []
    property bool ready: false

    // Live widgets drawing from `bars` (Cava, WaveformProgress). The
    // FFT process runs as an independent audio pipeline thread while media is playing.
    // Decoupled from transient UI component lifecycles (viewers) so view switches never
    // tear down and recreate PipeWire connections.
    property int viewers: 0

    readonly property bool wantRun:
        ready && MediaService.hasPlayer && MediaService.isPlaying

    // Imperative start/stop driven by wantRun so crash-restarts
    // via restartTimer never fight a property binding.
    onWantRunChanged: {
        if (root.wantRun) {
            cava.running = false
            cava.running = true
        } else {
            cava.running = false
            root.bars = []
        }
    }

    Process {
        id: cava
        running: false
        command: [
            "cava",
            "-p",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/cava.conf"
        ]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: function(line) {
                if (line.trim().length === 0)
                    return

                const values = line.trim().split(";")
                const parsed = []

                for (let i = 0; i < values.length; ++i) {
                    if (values[i] !== "")
                        parsed.push(Number(values[i]))
                }

                root.bars = parsed
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.bars = []

            if (root.wantRun)
                restartTimer.restart()
        }
    }

    Timer {
        id: startupTimer
        interval: 1000
        repeat: false
        running: true

        onTriggered: {
            root.ready = true
        }
    }

    Timer {
        id: restartTimer
        interval: 1000
        repeat: false

        onTriggered: {
            if (!root.wantRun)
                return

            cava.running = false
            cava.running = true
        }
    }
}
