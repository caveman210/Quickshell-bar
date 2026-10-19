import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"
import "../audio"
import "../display"
import "../../core"
import "../../island"

Item {
    id: root

    FileView {
        id: eventFile
        path: Quickshell.env("HOME") +
              "/.cache/quickshell/status/event"

        watchChanges: true

        // watchChanges only emits fileChanged; reload() re-reads the
        // file and onLoaded does the parsing, so the GUI thread never
        // blocks on a synchronous read.
        property bool sawInitialLoad: false

        onFileChanged: {
            reload()
        }

        onLoaded: {
            // Skip whatever event was already on disk at startup so a
            // stale OSD cannot flash on launch.
            if (eventFile.sawInitialLoad)
                readEvent()
            else
                eventFile.sawInitialLoad = true
        }

        function readEvent() {
            var data = text().trim()

            if (!data)
                return

            var parts = data.split("|")

            if (parts.length !== 2)
                return

            var type = parts[0]
            var value = Number(parts[1])

            if (type === "volume") {
                // Sync ControlCenter slider without polling.
                AudioService.update()

                // Bar layout only: no OSD while the control center
                // pane or the clock dropdown is open.
                if (
                    IslandState.layoutIsBar &&
                    (
                        IslandState.mode === IslandState.controlCenterMode ||
                        IslandState.mode === IslandState.expandedMode
                    )
                )
                    return

                if (value === -1) {
                    StatusManager.show({
                        mode: "volume",
                        icon: AudioService.iconForVolume(0, true),
                        title: "Muted",
                        value: -1,
                        statusWidth: 280,
                        statusHeight: 33
                    })

                    return
                }

                StatusManager.show({
                    mode: "volume",
                    icon: AudioService.iconForVolume(value, false),
                    title: value + "%",
                    value: value,
                    statusWidth: 280,
                    statusHeight: 33
                })
            }

            else if (type === "brightness") {
                // Sync ControlCenter slider without polling.
                BrightnessService.update()

                // Bar layout only: no OSD while the control center
                // pane or the clock dropdown is open.
                if (
                    IslandState.layoutIsBar &&
                    (
                        IslandState.mode === IslandState.controlCenterMode ||
                        IslandState.mode === IslandState.expandedMode
                    )
                )
                    return

                StatusManager.show({
                    mode: "brightness",
                    icon: BrightnessService.iconForBrightness(value),
                    title: value + "%",
                    value: value,
                    statusWidth: 280,
                    statusHeight: 33
                })
            }
        }
    }
}
