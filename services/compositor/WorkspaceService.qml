import QtQuick
import "../../core"
import "../../island"
import "../audio"
import "../notification"
import "../compositor/hyprland"
import "../compositor/niri"
import "../shell"

// Thin facade: routes compositor-specific workspace/focus/overview
// events to the platform-agnostic consumers (StatusManager for the
// workspace toast, AutoHideService for focus state and overview).
Item {
    id: root

    // Check if the pill is idle (only clock visible, no media, calls, or privacy sensors)
    function canShowWorkspace() {
        // If not in default mode, or bar layout, don't show
        if (IslandState.mode !== IslandState.defaultMode)
            return false

        // Check active activities
        var hasMedia = MediaService.hasPlayer && MediaService.isPlaying
        var hasCall = NotificationService.activeCall !== null
        var hasPrivacy = PrivacyService.micActive || PrivacyService.cameraActive || PrivacyService.screenSharingActive

        return !hasMedia && !hasCall && !hasPrivacy
    }

    NiriWorkspaceMonitor {
        active: CompositorService.isNiri

        onWorkspaceActivated: function(label, index) {
            if (!root.canShowWorkspace())
                return

            StatusManager.show({
                mode: "workspace",
                icon: "󰍹",
                title: label,
                value: index,
                statusWidth: 200,
                statusHeight: 33
            })
        }

        onWindowFocusChanged: function(focused, appId) {
            AutoHideService.setCompositorFocus(focused, appId)
        }

        onOverviewChanged: function(open) {
            AutoHideService.overviewOpen = open
        }
    }

    HyprlandWorkspaceMonitor {
        active: CompositorService.isHyprland

        onWorkspaceActivated: function(name) {
            if (!root.canShowWorkspace())
                return

            StatusManager.show({
                mode: "workspace",
                icon: "󰍹",
                title: name,
                value: Number(name),
                statusWidth: 200,
                statusHeight: 33
            })
        }
    }
}
