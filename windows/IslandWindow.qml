import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import "../island"
import "../core"
import "../services"
import "../styles"

PanelWindow {
    id: root
    visible: ThemeService.ready

    // Hyprland-only: Niri does not implement hyprland_focus_grab_v1,
    // so click-outside-to-dismiss is unavailable there (Esc / IPC reset still work).
    HyprlandFocusGrab {
        id: focusGrab
        active: CompositorService.isHyprland && ThemeService.ready && IslandState.modal
        windows: [ root ]

        onCleared: {
            IslandController.reset()
        }
    }

    // Focusable whenever a modal view is open so keyboard navigation
    // (hjkl / arrows / Enter / Esc) works on all compositors.
    focusable: ThemeService.ready && IslandState.modal

    anchors {
        top: true
        left: true
        right: true
    }

    // Auto-hide overlays the desktop instead of reserving a gap, so
    // windows don't reflow every time focus changes. With the feature
    // off, reserve the usual 33px like before.
    exclusiveZone: ThemeService.ready && !AutoHideService.enabled ? 33 : 0

    // Top renders under fullscreen windows; Overlay renders above
    // them. Use Overlay whenever auto-hide is on so the revealed
    // island sits over everything, per the feature's contract.
    WlrLayershell.layer: AutoHideService.enabled ? WlrLayer.Overlay : WlrLayer.Top

    // Auto-hide reserves no exclusive zone, so the revealed island
    // sits a little further from the top edge; with the feature off
    // keep the original 10px inset.
    readonly property int revealedTop: AutoHideService.enabled ? 24 : 10

    // Tallest view is ControlCenterView (530). Keep the surface
    // height fixed so island size animations never resize the layer
    // surface every frame (configure/ack roundtrips = stutter).
    // Math.max falls back to the animated height if a view ever
    // grows past this instead of clipping it.
    readonly property int maxIslandHeight: 530

    implicitHeight: Math.max(maxIslandHeight, capsule.implicitHeight) + revealedTop + 10
    color: "transparent"

    // The notch hangs flush from the screen's top edge (that is
    // what makes it read as a notch); the pill keeps its inset.
    readonly property bool notchShape: IslandState.shape === IslandState.shapeNotch

    Island {
        id: capsule
        anchors.horizontalCenter: parent.horizontalCenter

        // Auto-hide slide: retract above the window's top edge (the
        // surface clips it away), same easing the expansion uses.
        y: AutoHideService.hidden ? -(height + 10) : (notchShape ? 0 : revealedTop)

        Behavior on y {
            NumberAnimation {
                duration: Theme.animationNormal
                easing.type: Theme.animationVertical
            }
        }
    }

    Region {
        id: capsuleMask
        item: capsule
    }

    mask: capsuleMask
}
