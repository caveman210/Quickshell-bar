import Quickshell.Hyprland

import "../../services"
import "../../services/compositor"

// Hyprland-only: Niri does not implement hyprland_focus_grab_v1,
// so click-outside-to-dismiss is unavailable there (Esc / IPC reset still work).
HyprlandFocusGrab {
    id: root

    property bool enabled: false
    property var targetWindow: null

    signal dismissed()

    active: root.enabled && CompositorService.isHyprland
    windows: root.targetWindow ? [root.targetWindow] : []

    onCleared: root.dismissed()
}
