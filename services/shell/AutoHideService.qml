pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import ".."
import "../../core"
import "../../island"
import "../compositor/hyprland"
import "../appearance"
import "../compositor"

Singleton {
    id: root

    // =========================================================
    // SETTING
    // In-memory only (like FocusService) — resets on reload.
    // =========================================================

    property bool enabled: false
    property string subtitle: enabled ? "On" : "Off"
    property string icon: enabled
        ? "󰈈"
        : "󰈉"

    function toggle() {
        enabled = !enabled
    }

    // =========================================================
    // COMPOSITOR STATE
    // =========================================================

    // niri reports focus authoritatively through its event stream
    // (WindowFocusChanged / WindowsChanged.is_focused) — handled by
    // NiriWorkspaceMonitor, which calls setCompositorFocus(). Hyprland
    // (and niri 26.04+ as a fallback) uses
    // zwlr-foreign-toplevel-management via ToplevelManager.
    property bool compositorFocusKnown: false
    property bool compositorWindowFocused: false
    property string compositorFocusedAppId: ""
    property bool toplevelActive: ToplevelManager.activeToplevel !== null

    readonly property bool windowFocused: {
        if (CompositorService.isNiri && compositorFocusKnown)
            return compositorWindowFocused

        return toplevelActive
    }

    // App id of the focused window — drives the per-app edge dwell
    // from assets/app-behavior.json. niri's event stream is the
    // authoritative source when available; zwlr-foreign-toplevel
    // (ToplevelManager) covers the rest.
    readonly property string focusedAppId: {
        if (CompositorService.isNiri && compositorFocusKnown)
            return compositorFocusedAppId

        if (ToplevelManager.activeToplevel)
            return ToplevelManager.activeToplevel.appId || ""

        return ""
    }

    function setCompositorFocus(focused, appId) {
        compositorFocusKnown = true
        compositorWindowFocused = focused
        compositorFocusedAppId = appId || ""
    }

    // Fullscreen windows own the whole output. The island renders on
    // the Overlay layer (it must, to animate over windows), so unless
    // it was opened deliberately or pinned it stays hidden and never
    // reveals while fullscreen is focused. zwlr-foreign-toplevel is
    // the only fullscreen source niri exposes.
    readonly property bool fullscreenFocused: ToplevelManager.activeToplevel !== null
        && ToplevelManager.activeToplevel.fullscreen

    onFullscreenFocusedChanged: {
        if (!fullscreenFocused)
            return

        edgeDwellTimer.stop()
        edgeHoverRaw = false
        edgeHovered = false

        if (!mustShow) {
            hideTimer.stop()
            showTimer.stop()
            hidden = true
        }
    }

    // niri overview keeps the island on screen (noctalia does this too).
    property bool overviewOpen: false

    // =========================================================
    // REVEAL / HIDE STATE
    // =========================================================

    property bool hidden: false

    // Edge hover sources: the 1px trigger window on niri, and the
    // HyprlandEdgeHoverMonitor on Hyprland (no input region at all there).
    // Raw input lands in edgeHoverRaw; the dwell timer turns it into
    // edgeHovered, the value the state machine below reads.
    property bool edgeHoverRaw: false
    property bool edgeHovered: false

    readonly property bool revealHovered: edgeHovered

    // The island is showing anything other than the idle clock.
    readonly property bool islandOpen: IslandState.mode !== IslandState.defaultMode

    // While any of these hold, the island must stay on screen.
    readonly property bool mustShow: !enabled
        || !windowFocused
        || islandOpen
        || IslandState.islandPinned
        || overviewOpen

    // Reveal sources only run while auto-hide is actually in play.
    readonly property bool revealSourceActive: ThemeService.ready
        && enabled
        && windowFocused
        && !islandOpen
        && !fullscreenFocused

    readonly property bool triggerActive: revealSourceActive
        && CompositorService.isNiri

    // =========================================================
    // STATE MACHINE
    // =========================================================

    onMustShowChanged: {
        if (mustShow) {
            hideTimer.stop()
            showTimer.stop()
            hidden = false
        } else if (enabled && windowFocused) {
            hideTimer.restart()
        }
    }

    onRevealHoveredChanged: {
        if (revealHovered) {
            hideTimer.stop()

            if (hidden)
                showTimer.restart()
        } else {
            showTimer.stop()

            if (!hidden && !mustShow && !IslandState.islandHovered)
                hideTimer.restart()
        }
    }

    onEnabledChanged: {
        if (!enabled) {
            hideTimer.stop()
            showTimer.stop()
            hidden = false
            edgeHoverRaw = false
            edgeHovered = false
        } else if (!mustShow) {
            // Don't slam shut instantly — start the countdown instead.
            hideTimer.restart()
        }
    }

    // Island capsule hover (fed by IslandInteraction via IslandState).
    Connections {
        target: IslandState

        function onIslandHoveredChanged() {
            if (IslandState.islandHovered) {
                hideTimer.stop()
            } else if (!root.hidden && !root.mustShow && !root.revealHovered) {
                hideTimer.restart()
            }
        }
    }

    // Fed by EdgeTriggerWindow (niri) and the cursor poll (Hyprland).
    // Raw; the dwell timer decides when it becomes edgeHovered.
    function setEdgeHovered(hovered) {
        edgeHoverRaw = hovered
    }

    onEdgeHoverRawChanged: {
        if (!edgeHoverRaw) {
            edgeDwellTimer.stop()
            edgeHovered = false

            return
        }

        var delay = edgeDelayForApp(focusedAppId)

        if (delay <= 0) {
            edgeHovered = true
        } else {
            edgeDwellTimer.interval = delay
            edgeDwellTimer.restart()
        }
    }

    // Holds raw edge hover back for the focused app's dwell time so a
    // cursor merely passing over the top edge (e.g. Firefox vertical
    // tabs) doesn't reveal the island.
    Timer {
        id: edgeDwellTimer
        repeat: false

        onTriggered: {
            if (root.edgeHoverRaw)
                root.edgeHovered = true
        }
    }

    // =========================================================
    // PER-APP EDGE DWELL (assets/app-behavior.json)
    // "apps" maps a window's app_id to a dwell delay in ms;
    // unlisted apps fall back to "defaultDelayMs" (0 = instant).
    // =========================================================

    property var edgeRevealConfig: ({"defaultDelayMs": 0, "apps": {}})

    function parseBehaviorConfig(raw) {
        try {
            var parsed = JSON.parse(raw)

            if (parsed && parsed.edgeReveal)
                root.edgeRevealConfig = parsed.edgeReveal
        } catch (err) {
            console.log("Failed to parse app-behavior.json:", err)
        }
    }

    function edgeDelayForApp(appId) {
        var apps = root.edgeRevealConfig.apps || {}

        if (appId) {
            if (apps[appId] !== undefined)
                return Math.max(0, Number(apps[appId]) || 0)

            var lower = String(appId).toLowerCase()

            if (apps[lower] !== undefined)
                return Math.max(0, Number(apps[lower]) || 0)
        }

        return Math.max(0, Number(root.edgeRevealConfig.defaultDelayMs) || 0)
    }

    FileView {
        id: behaviorFile
        path: Quickshell.env("HOME") + "/.config/quickshell/assets/app-behavior.json"
        watchChanges: true

        // watchChanges only emits fileChanged; reload() is what
        // actually re-reads the file, so edits apply live.
        onFileChanged: {
            reload()
        }

        onLoaded: {
            root.parseBehaviorConfig(text())
        }
    }

    // Temporarily reveal the island; slides back after hideDelay unless
    // something else keeps it up (hover, open view, pin, overview).
    function peek() {
        if (!enabled || !windowFocused)
            return

        hidden = false
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 2500
        repeat: false

        onTriggered: {
            if (root.mustShow || IslandState.islandHovered || root.revealHovered)
                return

            root.hidden = true
        }
    }

    Timer {
        id: showTimer
        interval: 100
        repeat: false

        onTriggered: {
            if (root.revealHovered && root.hidden && !root.mustShow)
                root.hidden = false
        }
    }

    // =========================================================
    // HYPRLAND EDGE HOVER
    // See compositor/hyprland/HyprlandEdgeHoverMonitor.qml — the
    // comment there explains why polling is needed on Hyprland.
    // =========================================================

    HyprlandEdgeHoverMonitor {
        active: ThemeService.ready
            && root.enabled
            && root.revealSourceActive
            && CompositorService.isHyprland

        onHoverChanged: function(hovered) {
            root.setEdgeHovered(hovered)
        }
    }

    // =========================================================
    // STATUS TOASTS
    // A toast must never be invisible while the island is retracted.
    // =========================================================

    Connections {
        target: StatusManager

        function onVisibleChanged() {
            if (StatusManager.visible)
                root.peek()
        }
    }
}
