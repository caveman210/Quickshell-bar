pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core"
import "../island"

Singleton {
    id: root
    property int brightness: 0
    property bool _osdReady: false

    readonly property string brightnessIcon: {
        if (brightness <= 25)
            return "󰃜"

        if (brightness <= 65)
            return "󰃞"

        return "󰃠"
    }

    Process {
        id: queryProcess
        command: [
            "brightnessctl",
            "info"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()

                let match = output.match(/\((\d+)%\)/)

                if (!match)
                    return

                let newBrightness = parseInt(match[1])

                let changed = newBrightness !== root.brightness

                root.brightness = newBrightness

                if (!root._osdReady) {
                    root._osdReady = true
                    return
                }

                if (
                    changed &&
                    IslandState.mode === IslandState.defaultMode
                )
                    root.showOsd()
            }
        }
    }

    Process {
        id: setProcess

        onExited: {
            root.update()
        }
    }

    function update() {
        if (queryProcess.running)
            return

        queryProcess.running = false
        queryProcess.running = true
    }

    function setBrightness(value) {
        let percent = Math.round(value)

        let scriptPath =
            String(
                Qt.resolvedUrl("../scripts/brightness.sh")
            ).replace("file://", "")

        setProcess.command = [
            scriptPath,
            percent + "%"
        ]

        setProcess.running = true
    }

    function increase(step) {
        let amount = step === undefined ? 5 : step

        setBrightness(
            Math.min(100, brightness + amount)
        )
    }

    function decrease(step) {
        let amount = step === undefined ? 5 : step

        setBrightness(
            Math.max(0, brightness - amount)
        )
    }

    function showOsd() {
        var icon

        if (root.brightness < 25)
            icon = "󰃞"
        else if (root.brightness < 60)
            icon = "󰃟"
        else
            icon = "󰃠"

        StatusManager.show({
            mode: "brightness",
            icon: icon,
            title: root.brightness + "%",
            value: root.brightness,
            statusWidth: 280,
            statusHeight: 33
        })
    }

    // Safety net only. Changes arrive event-driven via
    // scripts/brightness.sh -> StatusWatcher (which calls update()),
    // plus setProcess.onExited above. This 10s poll only catches
    // external changes (e.g. FN keys bypassing the script).
    Timer {
        interval: 10000
        repeat: true
        running: true

        onTriggered: {
            root.update()
        }
    }

    Component.onCompleted: {
        update()
    }
}
