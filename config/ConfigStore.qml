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
    // Night Light schedule options
    property bool nightLightSchedule: true
    property string nightLightStart: "20:00"
    property string nightLightEnd: "07:00"
    property int nightLightTransitionMins: 15
    property string nightLightCurveType: "scurve" // "scurve", "linear", "ease_in", "ease_out", "custom"
    property var nightLightControlPoints: [
        {"x": 0.0, "y": 0.0},
        {"x": 0.35, "y": 0.08},
        {"x": 0.65, "y": 0.92},
        {"x": 1.0, "y": 1.0}
    ]
    property int nightLightTargetTemp: 4500

    property bool loaded: false

    function save() {
        var data = {
            "weatherLocation": root.weatherLocation,
            "weatherApiKey": root.weatherApiKey,
            "barInfoMode": root.barInfoMode,
            "nightLightSchedule": root.nightLightSchedule,
            "nightLightStart": root.nightLightStart,
            "nightLightEnd": root.nightLightEnd,
            "nightLightTransitionMins": root.nightLightTransitionMins,
            "nightLightCurveType": root.nightLightCurveType,
            "nightLightControlPoints": root.nightLightControlPoints,
            "nightLightTargetTemp": root.nightLightTargetTemp
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
                if (json.nightLightSchedule !== undefined)
                    root.nightLightSchedule = json.nightLightSchedule
                if (json.nightLightStart !== undefined)
                    root.nightLightStart = json.nightLightStart
                if (json.nightLightEnd !== undefined)
                    root.nightLightEnd = json.nightLightEnd
                if (json.nightLightTransitionMins !== undefined)
                    root.nightLightTransitionMins = json.nightLightTransitionMins
                if (json.nightLightCurveType !== undefined)
                    root.nightLightCurveType = json.nightLightCurveType
                if (json.nightLightControlPoints !== undefined)
                    root.nightLightControlPoints = json.nightLightControlPoints
                if (json.nightLightTargetTemp !== undefined)
                    root.nightLightTargetTemp = json.nightLightTargetTemp
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
