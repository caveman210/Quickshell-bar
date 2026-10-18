import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property int percentage: 0
    property bool charging: false
    property bool pluggedIn: false
    property string status: ""
    property string icon: "󰁺"

    Process {
        id: batteryReader
        running: true
        command: [
            "sh",
            "-c",
            "cat /sys/class/power_supply/BAT0/capacity && cat /sys/class/power_supply/BAT0/status && cat /sys/class/power_supply/ADP1/online"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")

                if (lines.length < 3)
                    return

                root.percentage = Number(lines[0])

                root.status = lines[1]

                root.pluggedIn = lines[2] === "1"

                root.charging =
                    root.status === "Charging"

                updateIcon()
            }
        }
    }

    // Relaxed 30s poll (was 5s). Capacity/status change slowly;
    // 30s granularity is plenty for a status readout.
    Timer {
        interval: 30000
        running: true
        repeat: true

        onTriggered: {
            if (batteryReader.running)
                return

            batteryReader.running = false
            batteryReader.running = true
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
        } else if (percentage >= 5){
            icon = "󱃍"
        } else {
            icon = "󱟩"
        }
    }

    function colorFlash(){
        if(percentage <= 25){
            // 
        }
    }
}
