import QtQuick
import ".."

// Compositor-specific session actions. Only logout differs between
// compositors; lock/suspend/reboot/poweroff are platform-agnostic
// and live in PowerService.
QtObject {
    // Returns the logout argv, or null when the compositor is
    // unknown (callers should warn and skip).
    function logoutCommand() {
        if (CompositorService.isNiri)
            return ["niri", "msg", "action", "quit", "--skip-confirmation"]

        if (CompositorService.isHyprland)
            return ["hyprctl", "dispatch", "exit"]

        return null
    }
}
