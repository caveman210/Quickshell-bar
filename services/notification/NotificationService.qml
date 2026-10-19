pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

import "../../core"
import ".."
import "../notification/NotifUtils.js" as NotifUtils
import "../notification"

// Notification harbor: owns the NotificationServer, the durable
// store write path, and the Focus/OSD behavior. View state
// (sections, messages, replay) lives in NotificationModel; pure
// text helpers live in NotifUtils.js.
Singleton {
    id: root

    NotificationModel {
        id: model
    }

    // ---- public view API (delegated) ------------------------------
    readonly property alias conversations: model.conversations

    // Delegates watch this to re-read messagesFor/group contents.
    readonly property alias revision: model.revision

    property int unreadCount: 0

    // The pane only ever shows the current local day. `viewDay`
    // lets the rollover timer notice midnight without re-reading the
    // disk store.
    property string viewDay: NotificationStore.dayOf(Date.now())
    property url defaultIcon: "../../assets/icons/bell.svg"

    // Notifications suppressed while Focus was on. In-memory only
    // (like FocusService) — resets on reload.
    property int missedWhileFocus: 0

    // ---- runtime plumbing -----------------------------------------
    property var liveNotifs: ({})
    property var lastWritten: ({})
    property var pendingUpdates: []

    Timer {
        id: updateTimer
        interval: 150
        repeat: false
        onTriggered: root.flushUpdates()
    }

    // Shared notification toast path. Focus gates the OSD: the
    // notification still lands in history with its unread bump,
    // it just never pops up. The tally is reported in one toast
    // when Focus turns off (Connections below).
    function osdToast(title) {
        if (FocusService.enabled) {
            root.missedWhileFocus++
            return
        }

        StatusManager.showQueued({
            mode: "notification",
            icon: "󰂚",
            title: String(title || "Notification"),
            value: 0,
            statusWidth: 280,
            statusHeight: 33
        })
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
            root.handleNotification(notification)
        }
    }

    function handleNotification(notification) {
        notification.tracked = true

        // keepOnReload re-emits old notifications with
        // lastGeneration set — skip so reloads don't duplicate
        // records, unread counts, or toasts.
        if (notification.lastGeneration)
            return

        root.liveNotifs[notification.id] = notification

        notification.closed.connect(function(reason) {
            root.onClosed(notification, reason)
        })

        notification.summaryChanged.connect(function() {
            root.scheduleUpdate(notification.id)
        })

        notification.bodyChanged.connect(function() {
            root.scheduleUpdate(notification.id)
        })

        notification.imageChanged.connect(function() {
            root.scheduleUpdate(notification.id)
        })

        var snap = root.buildSnapshot(notification, "new")

        root.lastWritten[notification.id] = snap

        var rec = NotificationStore.append(snap)

        model.applyRecord(rec)

        if (snap.image !== "")
            NotificationStore.enqueueMedia(notification.id, rec.seq, snap.image)

        root.unreadCount++

        root.osdToast(
            String(
                notification.summary ||
                notification.appName ||
                "Notification"
            )
        )

        console.log("Notification:", notification.appName, "|", notification.summary)
    }

    // WHATWG §2.8 close steps. Recorded + entries stay visible
    // (dimmed); the disk log is the point of this service.
    function onClosed(notification, reason) {
        delete root.liveNotifs[notification.id]

        var reasonName = reason === 1
            ? "expired"
            : (reason === 2 ? "dismissed" : "closeRequested")

        var rec = NotificationStore.append({
            type: "close",
            id: notification.id,
            reason: reasonName
        })

        model.applyRecord(rec)
    }

    // WHATWG §2.6 tag replacement: replaces_id updates the tracked
    // object in place (no new signal). Coalesce bursts, then append
    // one update record with the latest state.
    function scheduleUpdate(nid) {
        if (!root.liveNotifs[nid])
            return

        if (root.pendingUpdates.indexOf(nid) < 0)
            root.pendingUpdates.push(nid)

        updateTimer.restart()
    }

    function flushUpdates() {
        var nids = root.pendingUpdates

        root.pendingUpdates = []

        for (var i = 0; i < nids.length; i++) {
            var nid = nids[i]
            var n = root.liveNotifs[nid]

            if (!n)
                continue

            var snap = root.buildSnapshot(n, "update")
            var lw = root.lastWritten[nid]

            if (
                lw &&
                lw.summary === snap.summary &&
                lw.body === snap.body &&
                lw.image === snap.image &&
                lw.urgency === snap.urgency
            )
                continue

            var rec = NotificationStore.append(snap)

            root.lastWritten[nid] = snap
            model.applyRecord(rec)

            if (!lw || lw.image !== snap.image)
                NotificationStore.enqueueMedia(nid, rec.seq, snap.image)
        }
    }

    function buildSnapshot(n, type) {
        var actions = []

        if (n.actions) {
            for (var i = 0; i < n.actions.length; i++) {
                var a = n.actions[i]

                if (a && a.text !== undefined && a.text !== "")
                    actions.push({
                        identifier: String(a.identifier || ""),
                        text: String(a.text)
                    })
            }
        }

        return {
            type: type,
            id: n.id,
            app: String(n.appName || ""),
            appIcon: String(n.appIcon || ""),
            desktopEntry: String(n.desktopEntry || ""),
            summary: String(n.summary || ""),
            body: String(n.body || ""),
            urgency: NotifUtils.urgencyName(n.urgency),
            suppressed: FocusService.enabled,
            transient: !!n.transient,
            resident: !!n.resident,
            image: String(n.image || ""),
            actions: actions,
            hints: NotifUtils.jsonHints(n.hints)
        }
    }

    // ---- day rollover ---------------------------------------------

    // The pane is per-day: once the local date changes it drops the
    // previous day's notifications instead of carrying them over.
    // The disk store keeps the month of history on its own.
    Timer {
        interval: 30 * 1000
        running: true
        repeat: true

        onTriggered: root.checkDayRollover()
    }

    function checkDayRollover() {
        var today = NotificationStore.dayOf(Date.now())

        if (today === root.viewDay)
            return

        root.viewDay = today

        if (!NotificationStore.loaded)
            return

        model.replay(NotificationStore.records,
                     NotificationStore.startOfToday())
        root.unreadCount = 0
    }

    // ---- durable store events -------------------------------------

    Connections {
        target: NotificationStore

        function onHistoryLoaded(records) {
            model.replay(records, NotificationStore.startOfToday())
            NotificationStore.prune()
        }

        function onMediaReady(info) {
            model.applyMedia(info)
        }
    }

    // ---- view API ---------------------------------------------------

    function messagesFor(key) {
        return model.messagesFor(key)
    }

    function toggleGroup(key) {
        model.toggleGroup(key)
    }

    function removeGroup(key) {
        model.removeGroup(key)
    }

    function clear() {
        model.clear()
        root.unreadCount = 0
    }

    function markRead() {
        root.unreadCount = 0
    }

    function messageText(msg) {
        return NotifUtils.messageText(msg)
    }

    function formatTime(ts) {
        return NotifUtils.formatTime(ts)
    }

    // Icon resolution is pure for a given input but the notification
    // delegates re-evaluate it on every revision bump — cache the
    // resolved path per (desktopEntry, appIcon) pair.
    property var _iconCache: ({})

    function iconSource(desktopEntry, appIcon) {
        var cacheKey = String(desktopEntry || "") + "|" + String(appIcon || "")
        var cached = root._iconCache[cacheKey]

        if (cached !== undefined)
            return cached

        var result = root._resolveIcon(desktopEntry, appIcon)

        root._iconCache[cacheKey] = result

        return result
    }

    function _resolveIcon(desktopEntry, appIcon) {
        var e = String(desktopEntry || "")

        if (e !== "") {
            var entry = DesktopEntries.byId(e)

            if (entry && entry.icon && entry.icon !== "") {
                var p = Quickshell.iconPath(entry.icon, true)

                if (p)
                    return p
            }
        }

        var a = String(appIcon || "")

        if (a === "")
            return ""

        if (a.indexOf("file://") === 0 || a.indexOf("image://") === 0)
            return a

        if (a.charAt(0) === "/")
            return "file://" + a

        var ip = Quickshell.iconPath(a, true)

        return ip || ""
    }

    function assetUrl(rel) {
        if (!rel)
            return ""

        return "file://" + NotificationStore.filePath(rel)
    }

    // ---- Focus tally (kept from the old service) -----------------

    Connections {
        target: FocusService

        function onEnabledChanged() {
            if (FocusService.enabled)
                return

            var missed = root.missedWhileFocus

            root.missedWhileFocus = 0

            if (missed === 0)
                return

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

    Component.onCompleted: {
        console.log("NotificationService loaded")
    }
}
