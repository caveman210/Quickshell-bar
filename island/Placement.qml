pragma Singleton

import QtQuick
import Quickshell

// Which screen edge the island docks to. The preference itself is
// edge-agnostic; layouts opt in to bottom docking through
// IslandState.dockBottom. In-memory only (like AutoHideService) —
// resets on reload.
Singleton {
    id: root

    readonly property int top: 0
    readonly property int bottomEdge: 1

    property int edge: top

    readonly property bool bottom: edge === bottomEdge
    readonly property string subtitle: bottom ? "Bottom" : "Top"
    readonly property string icon: bottom ? "󰁅" : "󰁝"

    function toggle() {
        edge = bottom ? top : bottomEdge
    }

    Component.onCompleted: console.log("Placement debug:", edge, bottom, subtitle)
}
