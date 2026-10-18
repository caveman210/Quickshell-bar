pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // "niri" | "hyprland"
    // Unknown compositors fall back to "hyprland" to preserve legacy behavior.
    property string name: {
        var niriSocket = Quickshell.env("NIRI_SOCKET") || ""
        var hyprSig = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || ""
        var desktop = (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase()

        if (niriSocket !== "" || desktop.indexOf("niri") !== -1)
            return "niri"

        if (hyprSig !== "" || desktop.indexOf("hyprland") !== -1)
            return "hyprland"

        return "hyprland"
    }

    property bool isNiri: name === "niri"
    property bool isHyprland: name === "hyprland"
}
