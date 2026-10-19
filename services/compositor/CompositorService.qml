pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // "niri" | "hyprland" | "unknown"
    // Unknown compositors stay "unknown" so compositor-specific
    // branches are never taken blindly.
    property string name: {
        var niriSocket = Quickshell.env("NIRI_SOCKET") || ""
        var hyprSig = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || ""
        var desktop = (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase()

        if (niriSocket !== "" || desktop.indexOf("niri") !== -1)
            return "niri"

        if (hyprSig !== "" || desktop.indexOf("hyprland") !== -1)
            return "hyprland"

        return "unknown"
    }

    property bool isNiri: name === "niri"
    property bool isHyprland: name === "hyprland"
    property bool isKnown: name !== "unknown"
}
