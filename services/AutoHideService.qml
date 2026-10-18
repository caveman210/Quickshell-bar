pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "."
import "../core"
import "../island"

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
    // WorkspaceService, which calls setNiriWindowFocused(). Hyprland
    // (and niri 26.04+ as a fallback) uses
    // zwlr-foreign-toplevel-management via ToplevelManager.
    property bool niriFocusKnown: false
    property bool niriWindowFocused: false
    property bool toplevelActive: ToplevelManager.activeToplevel !== null

    readonly property bool windowFocused: {
        if (CompositorService.isNiri && niriFocusKnown)
            return niriWindowFocused

        return toplevelActive
    }

    function setNiriWindowFocused(focused) {
        niriFocusKnown = true
        niriWindowFocused = focused
    }

    // niri overview keeps the island on screen (noctalia does this too).
    property bool overviewOpen: false

    // =========================================================
    // REVEAL / HIDE STATE
    // =========================================================

    property bool hidden: false

    // Edge hover sources: the 1px trigger window on niri, and the
    // hyprctl cursorpos poll on Hyprland (no input region at all there).
    property bool edgeHovered: false
    property bool cursorAtEdge: false

    readonly property bool revealHovered: edgeHovered || cursorAtEdge

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
            cursorAtEdge = false
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

    function setEdgeHovered(hovered) {
        edgeHovered = hovered
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
    // HYPRLAND CURSOR POLL
    // Niri has no cursor-position IPC, but Hyprland does — polling
    // means the island window needs no input region on Hyprland at
    // all: while hidden its mask maps the off-screen capsule, so
    // every click passes straight through to the windows below.
    // =========================================================

    Timer {
        id: cursorPoll
        interval: 150
        repeat: true
        running: ThemeService.ready
            && root.enabled
            && root.revealSourceActive
            && CompositorService.isHyprland

        onTriggered: {
            cursorProc.running = false
            cursorProc.running = true
        }
    }

    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos"]

        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.split(",")

                if (parts.length < 2)
                    return

                var y = parseInt(parts[1])

                if (isNaN(y))
                    return

                root.cursorAtEdge = y <= 1
            }
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
