pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    property string temp: "--"
    property string condition: "Loading..."
    property string icon: "󰖐"
    property string humidity: "--"
    property string wind: "--"
    property string city: ""
    property bool loading: false
    property bool loaded: false

    function refresh() {
        if (loading) return
        loading = true

        var loc = ConfigStore.weatherLocation ? ConfigStore.weatherLocation.trim() : ""
        var url = "https://wttr.in/" + encodeURIComponent(loc) + "?format=j1"

        fetchProc.command = ["curl", "-s", "--max-time", "10", url]
        fetchProc.running = false
        fetchProc.running = true
    }

    Timer {
        interval: 1800000 // 30 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Connections {
        target: ConfigStore
        function onWeatherLocationChanged() {
            root.refresh()
        }
    }

    Process {
        id: fetchProc
        stdout: StdioCollector {
            id: outCollector
            waitForEnd: true
            onStreamFinished: {
                root.loading = false
                try {
                    var data = JSON.parse(outCollector.text)
                    var curr = data.current_condition[0]
                    root.temp = curr.temp_C + "°C"
                    root.humidity = curr.humidity + "%"
                    root.wind = curr.windspeedKmph + " km/h"
                    root.condition = curr.weatherDesc[0].value

                    if (ConfigStore.weatherLocation && ConfigStore.weatherLocation.trim() !== "") {
                        root.city = ConfigStore.weatherLocation.trim()
                    } else if (data.nearest_area && data.nearest_area.length > 0) {
                        var area = data.nearest_area[0]
                        root.city = area.areaName[0].value
                    }

                    var code = parseInt(curr.weatherCode)
                    root.icon = root.getWeatherIcon(code)
                    root.loaded = true
                } catch (e) {
                    console.log("WeatherService parse error:", e)
                }
            }
        }
    }

    function getWeatherIcon(code) {
        if (code === 113) return "󰖙"
        if (code === 116) return "󰖕"
        if (code === 119 || code === 122) return "󰖐"
        if (code >= 200 && code <= 230) return "󰖓"
        if (code >= 260 && code <= 284) return "󰖗"
        if (code >= 293 && code <= 314) return "󰖖"
        if (code >= 317 && code <= 338) return "󰖘"
        if (code >= 350 && code <= 377) return "󰖒"
        return "󰖐"
    }
}
