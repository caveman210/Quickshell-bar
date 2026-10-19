import QtQuick
import "../../core"
import "../compositor/hyprland"
import "../compositor/niri"
import "../shell"

// Thin facade: routes compositor-specific workspace/focus/overview
// events to the platform-agnostic consumers (StatusManager for the
// workspace toast, AutoHideService for focus state and overview).
Item {
    id: root

    NiriWorkspaceMonitor {
        active: CompositorService.isNiri

        onWorkspaceActivated: function(label, index) {
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
