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
    property var _scannedPaths: []

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

                root._scannedPaths.push(path)
            }
        }

        onStarted: {
            root._scannedPaths = []
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                return

            // Check if items changed to avoid unnecessary re-renderings
            let changed = root.wallpapers.count !== root._scannedPaths.length
            if (!changed) {
                for (let i = 0; i < root._scannedPaths.length; i++) {
                    if (root.wallpapers.get(i).path !== root._scannedPaths[i]) {
                        changed = true
                        break
                    }
                }
            }

            if (changed) {
                root.wallpapers.clear()
                for (let i = 0; i < root._scannedPaths.length; i++) {
                    root.wallpapers.append({
                        path: root._scannedPaths[i]
                    })
                }
            }
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

    property string matugenMode: "dark" // dark | light
    property string matugenScheme: "scheme-tonal-spot"
    property string matugenContrast: "0"
    property string sourceColor: ""
    property ListModel palettes: ListModel {}

    Process {
        id: paletteProcess
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                root.palettes.clear()

                var parsed

                try {
                    parsed = JSON.parse(text)
                } catch (err) {
                    console.warn("WallpaperService: bad palette JSON:", err)
                    return
                }

                if (!Array.isArray(parsed))
                    return

                for (var i = 0; i < parsed.length; i++) {
                    var p = parsed[i]

                    root.palettes.append({
                        background: p.background,
                        surface: p.surface,
                        surfaceVariant: p.surfaceVariant,
                        primary: p.primary,
                        secondary: p.secondary,
                        tertiary: p.tertiary,
                        text: p.text,
                        error: p.error,
                        source: p.source,
                        mode: p.mode,
                        scheme: p.scheme
                    })
                }
            }
        }
    }

    function extractPalette(path) {
        if (!path)
            return

        palettes.clear()

        paletteProcess.command = [
            Quickshell.env("HOME") + "/.nix-profile/bin/matugen-preview",
            path
        ]

        paletteProcess.running = true
    }

    Process {
        id: matugenProcess

        // Theme generation lives entirely in the packaged
        // `matugen-theme` command: shell, kitty, GTK, Qt, nvim,
        // Vicinae and Zen all get updated there.
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                console.warn("WallpaperService: matugen failed with code", exitCode)
                return
            }

            ThemeService.reloadMatugenFile()
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

        var themeCommand = [
            Quickshell.env("HOME") + "/.nix-profile/bin/matugen-theme"
        ]

        if (root.sourceColor.length > 0) {
            themeCommand.push("color", root.sourceColor)
        } else {
            themeCommand.push("image", path)
        }

        themeCommand.push(
            "--mode", root.matugenMode,
            "--type", root.matugenScheme,
            "--contrast", root.matugenContrast
        )

        matugenProcess.command = themeCommand
        matugenProcess.running = true
    }

    function reload() {
        scanProcess.running = true
    }

    Component.onCompleted: {
        reload()
    }
}
