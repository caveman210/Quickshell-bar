pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

import "../core"

Singleton {
    id: root
    property ListModel history: ListModel {}
    property int unreadCount: 0
    property url defaultIcon: "../assets/icons/bell.svg"

    // Notifications suppressed while Focus was on. In-memory only
    // (like FocusService) — resets on reload.
    property int missedWhileFocus: 0

    // Shared notification toast path. Focus gates the OSD: the
    // notification still lands in history with its unread bump,
    // it just never pops up. The tally is reported in one toast
    // when Focus turns off (Connections below).
    function osdToast(title) {
        if (FocusService.enabled) {
            root.missedWhileFocus++
            console.log("TEST suppressed:", title, "tally:", root.missedWhileFocus)
            return
        }

        console.log("TEST shown:", title)
        StatusManager.showQueued({
            mode: "notification",
            icon: "󰂚",
            title: String(title || "Notification"),
            value: 0,
            statusWidth: 280,
            statusHeight: 33
        })
    }

    function getAppIcon(notification) {
        let icon = notification.appIcon

        if (icon && icon !== "")
            return icon

        return root.defaultIcon
    }

    NotificationServer {
        id: server
        keepOnReload: true

        // Advertise full capabilities so clients (Firefox, portals,
        // notify-send) send rich content instead of degrading it.
        // inlineReplySupported stays false: no reply UI handles it.
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true
        persistenceSupported: true

        onNotification: function(notification) {
            notification.tracked = true

            // keepOnReload re-emits old notifications with
            // lastGeneration set — skip so reloads don't duplicate
            // history entries, unread counts, or toasts.
            if (notification.lastGeneration)
                return

            // WHATWG §2.8 close steps: drop the history entry when the
            // notification is dismissed or retracted by the app (tag
            // replacement closes the old notification this way).
            // Expired entries stay as a log — the center keeps them
            // (spec §2.1). Empirically CloseNotification arrives as
            // reason 3, i.e. FDO numbering: 1 Expired, 2 Dismissed,
            // 3 CloseRequested — so only 1 is kept.
            notification.closed.connect(function(reason) {
                if (reason !== 1)
                    root.removeByNid(notification.id)
            })

            // WHATWG §2.6 tag replacement: replaces_id updates the
            // tracked object in place (no new signal), so sync the
            // history entry content. Silent by default (renotify
            // defaults false) — no re-toast, no unread bump.
            notification.summaryChanged.connect(function() {
                root.syncBody(notification)
            })
            notification.bodyChanged.connect(function() {
                root.syncBody(notification)
            })

            let icon = root.getAppIcon(notification)

            let image = notification.image

            // ListModel only supports basic types — coerce everything
            // to strings so image-data objects can't fail the insert.
            // nid keys the entry for close-step removal (above).
            root.history.insert(0, {
                nid: notification.id,
                app: String(notification.appName || ""),
                summary: String(notification.summary || ""),
                body: String(notification.body || ""),
                icon: String(icon || ""),
                image: String(image || ""),
                time: new Date().toLocaleTimeString()
            })

            root.unreadCount++

            // Transient island popup: compact view swaps clock for the
            // notification (OverlayView), expanded view shows it as a
            // StatusChip (RightSection), other modes via Island's
            // floating chip. Queued so bursts never overwrite each
            // other. Auto-hides via StatusManager. Suppressed while
            // Focus is on (counted for the focus-off summary).
            root.osdToast(
                String(
                    notification.summary ||
                    notification.appName ||
                    "Notification"
                )
            )

            console.log(
                "Notification:",
                notification.summary
            )

            console.log(
                "App:",
                notification.appName
            )

            console.log(
                "App icon:",
                icon
            )

            console.log(
                "Notification image:",
                image
            )

            console.log(
                "Desktop entry:",
                notification.desktopEntry
            )

            console.log(
                "Last generation:",
                notification.lastGeneration
            )
        }
    }

    // Focus off: report everything that was suppressed as a single
    // toast. Shown directly (never via osdToast) so it can't be
    // gated or tallied against itself, and it creates no history
    // entry — the notifications themselves are already in the center.
    Connections {
        target: FocusService

        function onEnabledChanged() {
            if (FocusService.enabled)
                return

            let missed = root.missedWhileFocus

            root.missedWhileFocus = 0

            if (missed === 0)
                return

            console.log("TEST summary toast:", missed)
            StatusManager.showQueued({
                mode: "notification",
                icon: "󰂚",
                title: missed === 1
                    ? "1 notification has been missed"
                    : missed + " notifications have been missed",
                value: 0,
                statusWidth: 280,
                statusHeight: 33
            })
        }
    }

    // Pending send() args, used for local fallback (below).
    property string pendingApp: ""
    property string pendingSummary: ""
    property string pendingBody: ""

    // Shared insert + toast path for locally generated notifications
    // (fallback when notify-send is missing, and direct callers).
    function insertLocal(app, summary, body) {
        root.history.insert(0, {
            app: String(app || ""),
            summary: String(summary || ""),
            body: String(body || ""),
            icon: String(root.defaultIcon),
            image: "",
            time: new Date().toLocaleTimeString()
        })

        root.unreadCount++

        root.osdToast(String(summary || app || "Notification"))
    }

    Process {
        id: sendProcess

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.pendingApp = ""
                root.pendingSummary = ""
                root.pendingBody = ""

                return
            }

            console.log(
                "notify-send failed, storing locally. Exit code:",
                exitCode
            )

            // notify-send missing/failed (e.g. not installed): the
            // NotificationServer echo will never arrive, so insert
            // directly instead of silently dropping (WifiService
            // connect/disconnect notices hit this path).
            if (root.pendingSummary !== "") {
                root.insertLocal(
                    root.pendingApp,
                    root.pendingSummary,
                    root.pendingBody
                )

                root.pendingApp = ""
                root.pendingSummary = ""
                root.pendingBody = ""
            }
        }
    }

    function send(app, summary, body) {
        root.pendingApp = app
        root.pendingSummary = summary
        root.pendingBody = body

        sendProcess.running = false

        sendProcess.command = [
            "notify-send",
            "--app-name", app,
            summary,
            body
        ]

        console.log(
            "Sending notification:",
            app,
            summary,
            body
        )

        sendProcess.running = true
    }

    function clear() {
        history.clear()

        unreadCount = 0
    }

    function remove(index) {
        if (
            index >= 0 &&
            index < history.count
        ) {
            history.remove(index, 1)
        }
    }

    // Close-step removal by server id (WHATWG §2.8). Entries
    // predating nid tracking have no nid and are skipped.
    function removeByNid(nid) {
        for (let i = 0; i < history.count; ++i) {
            if (history.get(i).nid === nid) {
                history.remove(i, 1)
                return
            }
        }
    }

    // Tag-replacement content sync (WHATWG §2.6): refresh the entry
    // in place, preserving its position and timestamp.
    function syncBody(notification) {
        for (let i = 0; i < history.count; ++i) {
            if (history.get(i).nid === notification.id) {
                let old = history.get(i)

                history.set(i, {
                    nid: notification.id,
                    app: String(notification.appName || ""),
                    summary: String(notification.summary || ""),
                    body: String(notification.body || ""),
                    icon: String(old.icon || ""),
                    image: String(notification.image || old.image || ""),
                    time: String(old.time || "")
                })
                return
            }
        }
    }

    function markRead() {
        unreadCount = 0
    }

    Component.onCompleted: {
        console.log(
            "NotificationService loaded"
        )
    }
}
