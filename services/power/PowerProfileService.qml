pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string activeProfile: "balanced"
    readonly property bool isPerformance: activeProfile === "performance"
    readonly property bool isPowerSaver: activeProfile === "power-saver"
    readonly property bool isBalanced: activeProfile === "balanced"

    readonly property string icon: {
        switch (activeProfile) {
            case "performance": return "󰓅"
            case "power-saver": return "󰌪"
            default: return ""
        }
    }

    readonly property string label: {
        switch (activeProfile) {
            case "performance": return "Performance"
            case "power-saver": return "Power Saver"
            default: return "Balanced"
        }
    }

    function cycleProfile() {
        var next = "balanced"
        if (activeProfile === "power-saver") {
            next = "balanced"
        } else if (activeProfile === "balanced") {
            next = "performance"
        } else {
            next = "power-saver"
        }
        setProfile(next)
    }

    function setProfile(profile) {
        activeProfile = profile
        setProc.command = [
            "busctl", "set-property",
            "net.hadess.PowerProfiles",
            "/net/hadess/PowerProfiles",
            "net.hadess.PowerProfiles",
            "ActiveProfile",
            "s",
            profile
        ]
        setProc.running = false
        setProc.running = true
    }

    function update() {
        if (!getProc.running) {
            getProc.running = true
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.update()
    }

    Process {
        id: getProc
        command: [
            "sh", "-c",
            "busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile 2>/dev/null | awk '{print $2}' | tr -d '\"'"
        ]

        stdout: StdioCollector {
            id: outCol
            waitForEnd: true
            onStreamFinished: {
                var res = outCol.text.trim()
                if (res.length > 0 && res !== root.activeProfile) {
                    root.activeProfile = res
                }
            }
        }
    }

    Process {
        id: setProc
        onExited: root.update()
    }
}
