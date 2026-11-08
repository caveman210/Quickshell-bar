pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configPath: Quickshell.env("HOME") + "/.config/quickshell/luci-config.json"

    // Location override (empty string means auto-detect via IP)
    property string weatherLocation: ""
    // Weather provider API key (optional for services like OpenWeatherMap, WeatherAPI)
    property string weatherApiKey: ""
    // Bar left slot mode: "cycle" (every 30 mins), "weather", or "motivation"
    property string barInfoMode: "cycle"

    property bool loaded: false

    function save() {
        var data = {
            "weatherLocation": root.weatherLocation,
            "weatherApiKey": root.weatherApiKey,
            "barInfoMode": root.barInfoMode
        }
        configFile.write(JSON.stringify(data, null, 2))
    }

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true

        onLoaded: {
            try {
                var json = JSON.parse(text())
                if (json.weatherLocation !== undefined)
                    root.weatherLocation = json.weatherLocation
                if (json.weatherApiKey !== undefined)
                    root.weatherApiKey = json.weatherApiKey
                if (json.barInfoMode !== undefined)
                    root.barInfoMode = json.barInfoMode
                root.loaded = true
            } catch (e) {
                root.save()
                root.loaded = true
            }
        }

        onLoadFailed: {
            root.save()
            root.loaded = true
        }
    }
}
