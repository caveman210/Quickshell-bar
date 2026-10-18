import QtQuick
import Quickshell
import Quickshell.Wayland

import "../services"

// Thin invisible screen-edge trigger that reveals the island while
// auto-hide is engaged (niri only — Hyprland polls the cursor
// position instead, so it never needs an input region at all).
//
// Modeled on noctalia's BarTriggerZone: a dedicated 1px window that
// exists only while auto-hide is in play, keeping the island
// window's own mask untouched. The 1px row is the unavoidable
// Wayland tradeoff for hover-without-cursor-IPC: any input region
// consumes the clicks that land in it, so it is kept to the bare
// minimum the niri maintainer recommends.
PanelWindow {
    id: root

    visible: AutoHideService.triggerActive

    color: "transparent"
    focusable: false

    anchors {
        top: true
        left: true
        right: true
    }

    // Never reserve space — this is a trigger, not a bar.
    exclusiveZone: 0
    implicitHeight: 1

    // Match the island's overlay layer so hover still reaches the
    // strip when a fullscreen window covers Top-layer surfaces.
    WlrLayershell.layer: WlrLayer.Overlay

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: AutoHideService.setEdgeHovered(true)
        onExited: AutoHideService.setEdgeHovered(false)
    }

    // Unmapping (feature disengaged) may not deliver onExited —
    // clear the hover state explicitly so hiding isn't blocked
    // forever by a stale edge hover.
    onVisibleChanged: {
        if (!visible)
            AutoHideService.setEdgeHovered(false)
    }
}
