pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "."

Singleton {
    id: root

    // hyprsunset is Hyprland-only; niri gets gammastep via
    // wlr-gamma-control, which must be installed separately.
    readonly property string backend: {
        if (CompositorService.isHyprland)
            return "hyprsunset"

        if (CompositorService.isNiri)
            return "gammastep"

        return ""
    }

    // On niri the Control Center card only shows once gammastep is
    // actually installed (probed at startup); elsewhere the card
    // never lies about something it cannot do.
    property bool gammastepInstalled: false

    onGammastepInstalledChanged: {
        if (gammastepInstalled)
            root.update()
    }

    property bool available: backend === "hyprsunset"
        || (backend === "gammastep" && gammastepInstalled)

    property bool enabled: false
    property bool toggleBusy: false
    property string subtitle: !available ? "N/A" : (enabled ? "On" : "Off")
    property string icon: enabled
        ? "󰔎"
        : "󰃞"

    Process {
        id: whichProcess
        command: ["bash", "-c", "command -v gammastep >/dev/null 2>&1"]

        onExited: {
            root.gammastepInstalled = exitCode === 0
        }
    }

    Process {
        id: stateProcess
        command: [
            "bash",
            "-c",
            root.backend === "gammastep"
                ? "pgrep -x gammastep >/dev/null && echo on || echo off"
                : "pgrep -x hyprsunset >/dev/null && echo on || echo off"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.enabled = text.trim() === "on"
            }
        }
    }

    Process {
        id: toggleProcess
        property bool targetState: false

        onExited: {
            root.toggleBusy = false

            if (targetState !== root.enabled) {
                // User clicked again while this ran — re-apply the
                // latest requested state instead of re-reading.
                root.applyToggle()
            } else {
                settleTimer.restart()
            }
        }
    }

    // Give kill/start a moment to actually take effect before
    // reading the real process state, so a rapid click burst can't
    // make the icon disagree with what is running.
    Timer {
        id: settleTimer
        interval: 350
        repeat: false

        onTriggered: {
            root.update()
        }
    }

    // No polling: toggle() sets `enabled` optimistically and
    // toggleProcess.onExited confirms via update(). An externally
    // killed process won't reflect until the next toggle or reload
    // — accepted tradeoff for zero idle wakeups.
    function update() {
        if (!root.available)
            return

        stateProcess.running = false
        stateProcess.running = true
    }

    function toggle() {
        if (!root.available)
            return

        // Flip the displayed state immediately, then let applyToggle
        // reconcile. A burst of clicks never kills an in-flight
        // process: the final click wins once it exits.
        root.enabled = !root.enabled

        if (!root.toggleBusy)
            root.applyToggle()
    }

    function applyToggle() {
        settleTimer.stop()

        root.toggleBusy = true
        toggleProcess.targetState = root.enabled

        if (root.enabled) {
            if (root.backend === "gammastep") {
                // setsid detaches it: the gamma client must outlive
                // this Process and shell reloads. Killing it lets
                // the compositor restore the original gamma.
                // -l 0:0 skips geolocation; day/night temps are equal
                // so the result is a constant 4500K.
                toggleProcess.command = [
                    "setsid",
                    "gammastep",
                    "-m", "wayland",
                    "-t", "4500:4500",
                    "-l", "0:0"
                ]
            } else {
                toggleProcess.command = [
                    "hyprsunset",
                    "--temperature",
                    "4500"
                ]
            }
        } else {
            toggleProcess.command = [
                "pkill",
                "-x",
                root.backend
            ]
        }

        toggleProcess.running = true
    }

    Component.onCompleted: {
        if (root.backend === "gammastep")
            whichProcess.running = true

        update()
    }
}
