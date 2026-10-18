pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "."
import "../core"

Singleton {
    id: root

    // Wallpapers are simply whatever sits in the folder — no metadata
    // file, no theme mapping. Theming is planned to move to matugen
    // (dynamic colors/wallpaper per theme) instead of hardcoding.
    property ListModel wallpapers: ListModel {}

    Process {
        id: scanProcess
        command: [
            "bash",
            "-c",
            "find \"$HOME/Pictures/Wallpapers\" -maxdepth 1 -type f \\( \
                -iname '*.jpg'  -o \
                -iname '*.jpeg' -o \
                -iname '*.png'  -o \
                -iname '*.webp' -o \
                -iname '*.gif' \
            \\) | sort"
        ]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: function(line) {
                let path = line.trim()

                if (path.length === 0)
                    return

                root.wallpapers.append({
                    path: path
                })
            }
        }

        onStarted: {
            root.wallpapers.clear()
        }
    }

    Process {
        id: applyProcess
    }

    function apply(path) {
        applyProcess.command = [
            "awww",
            "img",
            path,

            "--transition-type", "grow",
            "--transition-duration", "2",
            "--transition-fps", "60"
        ]

        applyProcess.running = true

        // Toast the file name so the change is visible on the island.
        StatusManager.show({
            mode: "wallpaper",
            icon: "󰸉",
            title: String(path).split("/").pop(),
            statusWidth: 240,
            statusHeight: 33
        })
    }

    function reload() {
        scanProcess.running = true
    }

    Component.onCompleted: {
        reload()
    }
}
