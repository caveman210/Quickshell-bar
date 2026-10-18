pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core"
import "../island"

Singleton {
    id: root
    property int volume: 0
    property bool muted: false
    property bool _osdReady: false

    readonly property string volumeIcon: {
        if (muted)
            return "󰝟"

        if (volume <= 5)
            return "󰖁"

        if (volume <= 40)
            return "󰕿"

        return "󰕾"
    }

    Process {
        id: queryProcess
        command: [
            "sh",
            "-c",
            "wpctl get-volume @DEFAULT_AUDIO_SINK@"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()

                if (output.length === 0)
                    return

                let parts = output.split(" ")

                let value = parseFloat(parts[1])

                let newVolume = !isNaN(value)
                    ? Math.round(value * 100)
                    : root.volume

                let newMuted =
                    output.includes("[MUTED]")

                let volumeChanged = newVolume !== root.volume
                let muteChanged = newMuted !== root.muted

                root.volume = newVolume
                root.muted = newMuted

                if (!root._osdReady) {
                    root._osdReady = true
                    return
                }

                if (
                    (volumeChanged || muteChanged) &&
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

    function setVolume(value) {
        let percent = Math.round(value)

        setProcess.command = [
            "wpctl",
            "set-volume",
            "@DEFAULT_AUDIO_SINK@",
            percent + "%"
        ]

        setProcess.running = true
    }

    function toggleMute() {
        setProcess.command = [
            "wpctl",
            "set-mute",
            "@DEFAULT_AUDIO_SINK@",
            "toggle"
        ]

        setProcess.running = true
    }

    function showOsd() {
        if (root.muted) {
        StatusManager.show({
            mode: "volume",
            icon: "󰝟",
            title: "Muted",
            value: -1,
            statusWidth: 280,
            statusHeight: 33
        })

        return
        }

        var icon

        if (root.volume === 0)
            icon = "󰝟"
        else if (root.volume < 30)
            icon = "󰕿"
        else if (root.volume < 50)
            icon = "󰖀"
        else if (root.volume <= 100)
            icon = "󰕾"
        else
            icon = "󰝝"

        StatusManager.show({
            mode: "volume",
            icon: icon,
            title: root.volume + "%",
            value: root.volume,
            statusWidth: 280,
            statusHeight: 33
        })
    }

    // Safety net only. Volume changes arrive event-driven via
    // scripts/volume.sh -> StatusWatcher (which calls update()),
    // plus setProcess.onExited above. This 10s poll only catches
    // external changes (e.g. pavucontrol) that bypass the scripts.
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
