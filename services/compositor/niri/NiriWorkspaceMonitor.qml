import QtQuick

// Translates niri's event stream into compositor-agnostic signals.
// Niri workspace ids are stable but opaque; idx is the per-output
// position shown to the user. The stream sends the full workspace
// list up-front (and on every change), so keep a map to resolve
// WorkspaceActivated ids to idx/name.
Item {
    id: root

    property bool active: false

    property var workspacesById: ({})
    property var windowAppIds: ({})

    // label, idx (per-output position)
    signal workspaceActivated(string label, int index)

    // Fired when focus is authoritative (WindowsChanged with
    // is_focused present, or a bare WindowFocusChanged).
    signal windowFocusChanged(bool focused, string appId)

    signal overviewChanged(bool open)

    function appIdForWindow(id) {
        if (id === null || id === undefined)
            return ""

        return root.windowAppIds[id] || ""
    }

    function showWorkspace(id) {
        var info = root.workspacesById[id]

        if (!info)
            return

        root.workspaceActivated(info.name || String(info.idx), info.idx)
    }

    function handleLine(line) {
        var text = line.trim()

        if (text.length === 0)
            return

        var event = null

        try {
            event = JSON.parse(text)
        } catch (err) {
            return
        }

        if (event.WorkspacesChanged) {
            var workspaces = event.WorkspacesChanged.workspaces || []
            var map = {}

            for (var i = 0; i < workspaces.length; ++i) {
                var ws = workspaces[i]
                map[ws.id] = {
                    idx: ws.idx,
                    name: ws.name
                }
            }

            root.workspacesById = map
        } else if (event.WorkspaceActivated) {
            // Only announce the newly focused workspace, not the
            // one that just lost focus.
            if (event.WorkspaceActivated.focused)
                root.showWorkspace(event.WorkspaceActivated.id)
        } else if (event.WindowsChanged) {
            // Full window list (also sent up-front on stream start).
            var wins = event.WindowsChanged.windows || []
            var focused = false
            var focusKnown = false
            var appIds = {}
            var focusedApp = ""

            for (var k = 0; k < wins.length; ++k) {
                var win = wins[k]

                if (win.app_id !== undefined)
                    appIds[win.id] = win.app_id

                if (typeof win.is_focused === "boolean") {
                    focusKnown = true

                    if (win.is_focused) {
                        focused = true
                        focusedApp = win.app_id || ""
                    }
                }
            }

            root.windowAppIds = appIds

            // Zero windows is authoritative ("no window focused");
            // otherwise require the is_focused field to be present.
            if (focusKnown || wins.length === 0)
                root.windowFocusChanged(focused, focusedApp)
        } else if (event.WindowFocusChanged) {
            // None when no window is focused (e.g. empty workspace).
            var focusedId = event.WindowFocusChanged.id

            root.windowFocusChanged(
                focusedId !== null && focusedId !== undefined,
                root.appIdForWindow(focusedId)
            )
        } else if (event.OverviewOpenedOrClosed) {
            root.overviewChanged(!!event.OverviewOpenedOrClosed.is_open)
        }
    }

    NiriEventStream {
        active: root.active

        onLineRead: function(line) {
            root.handleLine(line)
        }
    }
}
