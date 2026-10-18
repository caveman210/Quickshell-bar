pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property int percentage: 100
    property bool charging: false
    property bool pluggedIn: false
    property bool available: false
    property string status: ""
    property string icon: "󰁺"

    // Shows the low-battery indicator when capacity drops below this.
    readonly property int threshold: 15
    readonly property bool active: available && percentage < threshold && !charging
    readonly property string displayText: percentage + "%"

    Process {
        id: batteryReader
        running: true
        command: [
            "sh",
            "-c",
            "cap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo \"\"); stat=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo \"\"); onl=$(cat /sys/class/power_supply/ADP1/online 2>/dev/null || cat /sys/class/power_supply/AC/online 2>/dev/null || cat /sys/class/power_supply/ACAD/online 2>/dev/null || echo \"\"); echo \"$cap\"; echo \"$stat\"; echo \"$onl\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                if (lines.length < 1)
                    return

                // No battery on this machine (desktop): stay inactive so
                // the default bar never shows a bogus "(0%)" warning.
                if (lines[0].trim() === "" || isNaN(Number(lines[0]))) {
                    root.available = false
                    return
                }

                root.available = true
                root.percentage = Number(lines[0])
                root.status = lines.length > 1 ? lines[1].trim() : ""
                root.pluggedIn = lines.length > 2 && lines[2].trim() === "1"
                root.charging = root.status === "Charging"
                updateIcon()
            }
        }
    }

    // Relaxed 30s poll (matches BatteryService). Capacity/status
    // change slowly; 30s granularity is plenty for a status readout.
    Timer {
        interval: 30000
        running: true
        repeat: true

        onTriggered: {
            update()
        }
    }

    function updateIcon() {
        if (pluggedIn) {
            icon = "󰂄"
            return
        }

        if (percentage >= 95) {
            icon = "󰁹"
        } else if (percentage >= 90) {
            icon = "󰂂"
        } else if (percentage >= 80) {
            icon = "󰂁"
        } else if (percentage >= 70) {
            icon = "󰂀"
        } else if (percentage >= 60) {
            icon = "󰁿"
        } else if (percentage >= 50) {
            icon = "󰁾"
        } else if (percentage >= 40) {
            icon = "󰁽"
        } else if (percentage >= 30) {
            icon = "󰁼"
        } else if (percentage >= 20) {
            icon = "󰁻"
        } else if (percentage >= 10) {
            icon = "󰁺"
        } else if (percentage >= 5) {
            icon = "󱃍"
        } else {
            icon = "󱟩"
        }
    }

    // Compat entry point + manual refresh. Calling it also forces
    // the singleton to instantiate at startup (see shell.qml), so
    // polling runs even while the default bar is not visible.
    function update() {
        if (batteryReader.running)
            return

        batteryReader.running = false
        batteryReader.running = true
    }
}
