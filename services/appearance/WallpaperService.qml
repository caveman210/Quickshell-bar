pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import ".."
import "../../core"

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

    property string _pendingPath: ""

    Process {
        id: applyProcess

        // Toast only on success: a missing `awww` or a failed
        // transition must not report a change that never happened.
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                console.warn(
                    "WallpaperService: awww failed with code",
                    exitCode
                )

                return
            }

            StatusManager.show({
                mode: "wallpaper",
                icon: "󰸉",
                title: String(root._pendingPath).split("/").pop(),
                statusWidth: 240,
                statusHeight: 33
            })
        }
    }

    function apply(path) {
        _pendingPath = path

        applyProcess.command = [
            "awww",
            "img",
            path,

            "--transition-type", "grow",
            "--transition-duration", "2",
            "--transition-fps", "60"
        ]

        applyProcess.running = true
    }

    function reload() {
        scanProcess.running = true
    }

    Component.onCompleted: {
        reload()
    }
}
