import QtQuick
import Quickshell.Services.UPower

Item {
    id: root

    // =========================================================
    // D-BUS SOURCE (UPower via Quickshell.Services.UPower)
    // =========================================================
    // Event-driven. No polling, no sysfs Processes.
    // UPower's display device aggregates all internal batteries.

    readonly property var device: UPower.displayDevice

    // UPower.devices also lists the AC adapter and peripherals;
    // a laptop battery is the device that is a power supply.
    readonly property bool available: UPower.devices.values.some(function(dev) {
        return dev && dev.isLaptopBattery
    })

    // Quickshell exposes UPower's 0-100 wire value as a 0-1
    // fraction, so scale it back for display.
    readonly property int percentage: available && device.ready
        ? Math.round(device.percentage * 100)
        : 0

    readonly property bool charging: device.ready
        && device.state === UPowerDeviceState.Charging

    readonly property bool pluggedIn: available && device.ready
        && !UPower.onBattery

    readonly property string status: device.ready
        ? UPowerDeviceState.toString(device.state)
        : ""

    readonly property string icon: available
        ? _iconFor(percentage, pluggedIn)
        : "󰁺"

    function _iconFor(pct, plugged) {
        if (plugged)
            return "󰂄"

        if (pct >= 95) {
            return "󰁹"
        } else if (pct >= 90) {
            return "󰂂"
        } else if (pct >= 80) {
            return "󰂁"
        } else if (pct >= 70) {
            return "󰂀"
        } else if (pct >= 60) {
            return "󰁿"
        } else if (pct >= 50) {
            return "󰁾"
        } else if (pct >= 40) {
            return "󰁽"
        } else if (pct >= 30) {
            return "󰁼"
        } else if (pct >= 20) {
            return "󰁻"
        } else if (pct >= 10) {
            return "󰁺"
        } else if (pct >= 5) {
            return "󱃍"
        } else {
            return "󱟩"
        }
    }
}
