pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root
    property bool enabled: false
    property string subtitle: enabled ? "Enabled" : "Off"
    property string icon: enabled
        ? "󰂚"
        : "󰂛"

    function toggle() {
        enabled = !enabled
    }
}
