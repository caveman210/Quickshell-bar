pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

import "../core"

Singleton {
    id: root

    // Grouped per chat. Row fields are scalars (ListModel-safe);
    // messages live in the JS map and are read through
    // messagesFor(key), re-evaluated when `revision` bumps.
    property ListModel conversations: ListModel {}
    property var groups: ({})
    property var msgIndex: ({})
    property var lastMsgByNid: ({})
    property var nidKey: ({})

    // Delegates watch this to re-read messagesFor/group contents.
    property int revision: 0

    // Groups with more than this many messages start collapsed.
    property int collapseThreshold: 3

    readonly property real retentionMs: NotificationStore.retentionMs

    property int unreadCount: 0
    property url defaultIcon: "../assets/icons/bell.svg"

    // Notifications suppressed while Focus was on. In-memory only
    // (like FocusService) — resets on reload.
    property int missedWhileFocus: 0

    // ---- runtime plumbing ----------------------------------------
    property bool loadDone: false
    property var pendingLive: []
    property var seenSeq: ({})
    property var lastWritten: ({})
    property var liveNotifs: ({})
    property var pendingUpdates: []
    property int localNidCounter: 0

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

        root.applyRecord(rec)

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

        root.applyRecord(rec)
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
            root.applyRecord(rec)

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
            urgency: root.urgencyName(n.urgency),
            suppressed: FocusService.enabled,
            transient: !!n.transient,
            resident: !!n.resident,
            image: String(n.image || ""),
            actions: actions,
            hints: root.jsonHints(n.hints)
        }
    }

    function urgencyName(u) {
        if (u === 0)
            return "low"

        if (u === 2)
            return "critical"

        return "normal"
    }

    // Store only JSON-safe primitives (image-data hinth already gone:
    // Quickshell strips it after decoding into the qsimage URL).
    function jsonHints(map) {
        var out = ({})

        if (!map)
            return out

        for (var k in map) {
            var v = map[k]
            var t = typeof v

            if (t === "string" || t === "number" || t === "boolean") {
                out[k] = v
            } else if (v instanceof Array) {
                var arr = []
                var ok = true

                for (var j = 0; j < v.length; j++) {
                    var vt = typeof v[j]

                    if (vt === "string" || vt === "number" || vt === "boolean")
                        arr.push(v[j])
                    else {
                        ok = false
                        break
                    }
                }

                if (ok)
                    out[k] = arr
            }
        }

        return out
    }

    // ---- record application --------------------------------------

    function applyRecord(rec) {
        if (!root.loadDone) {
            root.pendingLive.push(rec)
            return
        }

        if (rec.seq && root.seenSeq[rec.seq])
            return

        if (rec.seq)
            root.seenSeq[rec.seq] = true

        root.applyRecordNow(rec)
    }

    function applyRecordNow(rec) {
        if (!rec || !rec.type)
            return

        if (rec.type === "media") {
            root.applyMedia(rec)
            return
        }

        if (rec.type === "rename") {
            root.applyRename(rec.from, rec.to)
            return
        }

        if (rec.type === "close") {
            root.applyClose(rec)
            return
        }

        if (rec.type !== "new" && rec.type !== "update")
            return

        var key = root.nidKey[rec.id]

        if (!key)
            key = root.startGroup(rec)

        if (!root.groups[key])
            return

        if (rec.type === "new") {
            root.appendMessage(key, rec)
        } else {
            var last = root.lastMsgByNid[rec.id]
            var raw = String(rec.body || "")

            if (
                last &&
                (String(last.raw !== undefined ? last.raw : last.body) !== raw ||
                 String(last.summary) !== String(rec.summary || ""))
            ) {
                root.appendMessage(key, rec)
            } else if (last) {
                // Same message, changed metadata (e.g. image added):
                // patch in place, keep its original time.
                var parsed = root.parseSender(raw)

                last.raw = raw
                last.sender = parsed.sender
                last.body = parsed.text
                last.summary = String(rec.summary || "")
                last.urgency = String(rec.urgency || "normal")
            }
        }

        root.syncRow(key)
        root.revision++
    }

    function startGroup(rec) {
        var key = root.groupKey(rec)

        root.nidKey[rec.id] = key

        if (!root.groups[key]) {
            var g = {
                key: key,
                app: String(rec.app || ""),
                title: root.groupTitle(rec),
                desktopEntry: String(rec.desktopEntry || ""),
                appIcon: String(rec.appIcon || ""),
                preview: "",
                msgCount: 0,
                ts: rec.ts || Date.now(),
                collapsed: false,
                highPriority: root.looksLikeCall(rec),
                avatarAsset: "",
                messages: []
            }

            root.groups[key] = g
            root.ensureRow(g)
        }

        return key
    }

    function appendMessage(key, rec) {
        var g = root.groups[key]

        if (!g)
            return null

        var last = root.lastMsgByNid[rec.id]
        var raw = String(rec.body || "")
        var parsed = root.parseSender(raw)

        var msg = {
            seq: rec.seq,
            nid: rec.id,
            ts: rec.ts || Date.now(),
            summary: String(rec.summary || ""),
            raw: raw,
            sender: parsed.sender,
            body: parsed.text,
            urgency: String(rec.urgency || "normal"),
            asset: last ? last.asset : "",
            hasAsset: last ? last.hasAsset : false,
            closed: false,
            suppressed: !!rec.suppressed
        }

        g.messages.push(msg)
        g.ts = msg.ts

        root.msgIndex[rec.seq] = { key: key, msg: msg }
        root.lastMsgByNid[rec.id] = msg

        return msg
    }

    function applyMedia(rec) {
        var asset = rec.resolvedAsset || rec.asset || ""

        // Small square images are chat profile pictures: they
        // belong on the section avatar, not in the message list.
        if (root.isAvatarImage(rec.w, rec.h)) {
            var akey = root.nidKey[rec.id]

            if (akey && root.groups[akey]) {
                root.groups[akey].avatarAsset = asset
                root.syncRow(akey)
            }

            root.revision++
            return
        }

        var slot = root.msgIndex[rec.ref]
        var msg = slot ? slot.msg : root.lastMsgByNid[rec.id]

        if (!msg)
            return

        msg.asset = asset
        msg.hasAsset = msg.asset !== ""

        root.revision++
    }

    function applyRename(from, to) {
        if (!from || !to)
            return

        for (var key in root.groups) {
            var g = root.groups[key]

            if (g.avatarAsset === from) {
                g.avatarAsset = to
                root.syncRow(key)
            }

            var msgs = g.messages

            for (var i = 0; i < msgs.length; i++) {
                if (msgs[i].asset === from)
                    msgs[i].asset = to
            }
        }

        root.revision++
    }

    function applyClose(rec) {
        var key = root.nidKey[rec.id]

        if (!key || !root.groups[key])
            return

        var msgs = root.groups[key].messages

        for (var i = 0; i < msgs.length; i++)
            msgs[i].closed = true

        root.revision++
    }

    // ---- replay --------------------------------------------------

    Connections {
        target: NotificationStore

        function onHistoryLoaded(records) {
            root.replay(records)
        }

        function onMediaReady(info) {
            var asset = info.resolvedAsset || info.asset || ""

            if (root.isAvatarImage(info.w, info.h)) {
                var akey = root.nidKey[info.id]

                if (akey && root.groups[akey]) {
                    root.groups[akey].avatarAsset = asset
                    root.syncRow(akey)
                }

                root.revision++
                return
            }

            var slot = root.msgIndex[info.ref]
            var msg = slot ? slot.msg : root.lastMsgByNid[info.id]

            if (!msg)
                return

            msg.asset = asset
            msg.hasAsset = msg.asset !== ""

            root.revision++
        }

        function onAssetRenamed(from, to) {
            root.applyRename(from, to)
        }
    }

    function replay(records) {
        // Idempotent: rebuild view state from the full record list.
        root.conversations.clear()
        root.groups = ({})
        root.msgIndex = ({})
        root.lastMsgByNid = ({})
        root.nidKey = ({})
        root.seenSeq = ({})

        var cutoff = Date.now() - root.retentionMs

        for (var i = 0; i < records.length; i++) {
            var rec = records[i]

            if (!rec || !rec.type)
                continue

            if (rec.ts && rec.ts < cutoff)
                continue

            if (rec.seq)
                root.seenSeq[rec.seq] = true

            root.applyRecordNow(rec)
        }

        root.loadDone = true

        // Live records that raced the load.
        var pending = root.pendingLive

        root.pendingLive = []

        for (i = 0; i < pending.length; i++) {
            var p = pending[i]

            if (p.seq && root.seenSeq[p.seq])
                continue

            if (p.seq)
                root.seenSeq[p.seq] = true

            root.applyRecordNow(p)
        }

        for (var key in root.groups)
            root.groups[key].collapsed =
                root.groups[key].messages.length > root.collapseThreshold

        for (key in root.groups)
            root.syncRow(key)

        root.revision++

        NotificationStore.prune()
    }

    // ---- view model helpers --------------------------------------

    function ensureRow(g) {
        root.conversations.insert(0, {
            key: g.key,
            app: g.app,
            title: g.title,
            desktopEntry: g.desktopEntry,
            appIcon: g.appIcon,
            preview: g.preview,
            msgCount: g.msgCount,
            ts: g.ts,
            collapsed: g.collapsed,
            highPriority: !!g.highPriority,
            avatarAsset: g.avatarAsset || ""
        })
    }

    function rowIndex(key) {
        for (var i = 0; i < root.conversations.count; i++) {
            if (root.conversations.get(i).key === key)
                return i
        }

        return -1
    }

    function syncRow(key) {
        var g = root.groups[key]

        if (!g)
            return

        var idx = root.rowIndex(key)

        if (idx < 0) {
            root.ensureRow(g)
            idx = root.rowIndex(key)
        }

        if (idx < 0)
            return

        var last = g.messages.length > 0
            ? g.messages[g.messages.length - 1]
            : null

        g.msgCount = g.messages.length
        g.preview = last
            ? root.previewText(
                  last.sender
                      ? last.sender + ": " + last.body
                      : (last.body || last.summary)
              )
            : ""

        root.conversations.setProperty(idx, "app", g.app)
        root.conversations.setProperty(idx, "title", g.title)
        root.conversations.setProperty(idx, "desktopEntry", g.desktopEntry)
        root.conversations.setProperty(idx, "appIcon", g.appIcon)
        root.conversations.setProperty(idx, "preview", g.preview)
        root.conversations.setProperty(idx, "msgCount", g.msgCount)
        root.conversations.setProperty(idx, "ts", g.ts)
        root.conversations.setProperty(idx, "collapsed", g.collapsed)
        root.conversations.setProperty(idx, "highPriority", !!g.highPriority)
        root.conversations.setProperty(idx, "avatarAsset", g.avatarAsset || "")

        if (idx > 0)
            root.conversations.move(idx, 0, 1)
    }

    function messagesFor(key) {
        var g = root.groups[key]

        return g ? g.messages : []
    }

    function toggleGroup(key) {
        var g = root.groups[key]

        if (!g)
            return

        g.collapsed = !g.collapsed

        var idx = root.rowIndex(key)

        if (idx >= 0)
            root.conversations.setProperty(idx, "collapsed", g.collapsed)
    }

    // View-only removal: the disk log keeps everything.
    function removeGroup(key) {
        var g = root.groups[key]

        if (g) {
            for (var i = 0; i < g.messages.length; i++) {
                var m = g.messages[i]

                delete root.msgIndex[m.seq]

                if (root.lastMsgByNid[m.nid] === m)
                    delete root.lastMsgByNid[m.nid]

                if (root.nidKey[m.nid] === key)
                    delete root.nidKey[m.nid]
            }

            delete root.groups[key]
        }

        var idx = root.rowIndex(key)

        if (idx >= 0)
            root.conversations.remove(idx, 1)

        root.revision++
    }

    function clear() {
        root.conversations.clear()
        root.groups = ({})
        root.msgIndex = ({})
        root.lastMsgByNid = ({})
        root.nidKey = ({})
        root.unreadCount = 0
        root.revision++
    }

    function markRead() {
        root.unreadCount = 0
    }

    // ---- text helpers --------------------------------------------

    function stripTags(s) {
        return String(s || "").replace(/<[^>]*>/g, "")
    }

    function previewText(s) {
        var t = root.stripTags(s).replace(/\s+/g, " ").trim()

        return t.length > 140 ? t.substring(0, 140) + "…" : t
    }

    function normalizeTitle(s) {
        return String(s || "")
            .replace(/\s*[\(\[]\d+[\)\]]\s*$/, "")
            .trim()
    }

    function groupTitle(rec) {
        var t = root.normalizeTitle(rec.summary)

        if (t !== "")
            return t

        return String(rec.app || "") || "Notification"
    }

    function groupKey(rec) {
        // Calls get their own section so they never mix with the
        // chat's message bundle.
        if (root.looksLikeCall(rec))
            return "call:" + rec.id

        var norm = root.normalizeTitle(rec.summary)

        if (norm !== "")
            return "g:" + String(rec.app || "") + "|" + norm

        return "nid:" + rec.id
    }

    // ---- message classification ----------------------------------

    function looksLikeCall(rec) {
        var combined = String(rec.summary || "") + " " + String(rec.body || "")

        if (!/\b(call|calling)\b/i.test(combined))
            return false

        if (/\b(incoming|missed|outgoing|declined|voice|video)\b/i.test(combined))
            return true

        return String(rec.urgency || "") === "critical"
    }

    // Group messages arrive as "Name: message" — split so the
    // sender can be highlighted in the message list.
    function parseSender(body) {
        var m = String(body || "").match(/^([^:\n]{1,40}):\s+([\s\S]+)$/)

        if (m)
            return { sender: m[1].trim(), text: m[2].trim() }

        return { sender: "", text: String(body || "") }
    }

    function escapeHtml(s) {
        return String(s || "")
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
    }

    // Small square images (e.g. 96x96 from WhatsApp Web via
    // Firefox) are chat profile pictures, not message media.
    function isAvatarImage(w, h) {
        var ww = Number(w)
        var hh = Number(h)

        if (!(ww > 0) || !(hh > 0))
            return false

        return Math.abs(ww - hh) <= 8 && Math.max(ww, hh) <= 256
    }

    function messageText(msg) {
        if (!msg)
            return ""

        if (msg.sender)
            return "<b>" + root.escapeHtml(msg.sender) + "</b>: " + msg.body

        return msg.body !== "" ? msg.body : msg.summary
    }

    function formatTime(ts) {
        var d = new Date(ts)
        var now = new Date()
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

        var hh = ("0" + d.getHours()).slice(-2)
        var mm = ("0" + d.getMinutes()).slice(-2)

        if (
            d.getDate() === now.getDate() &&
            d.getMonth() === now.getMonth() &&
            d.getFullYear() === now.getFullYear()
        )
            return hh + ":" + mm

        var label = d.getDate() + " " + months[d.getMonth()]

        if (d.getFullYear() !== now.getFullYear())
            label += " " + d.getFullYear()

        return label
    }

    function iconSource(desktopEntry, appIcon) {
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

    // ---- local sends ---------------------------------------------

    // Pending send() args, used for local fallback (below).
    property string pendingApp: ""
    property string pendingSummary: ""
    property string pendingBody: ""

    // Shared insert + toast path for locally generated notifications
    // (fallback when notify-send is missing, and direct callers).
    function insertLocal(app, summary, body) {
        root.localNidCounter++

        var nid = -root.localNidCounter

        var snap = {
            type: "new",
            id: nid,
            app: String(app || ""),
            appIcon: "",
            desktopEntry: "",
            summary: String(summary || ""),
            body: String(body || ""),
            urgency: "normal",
            suppressed: FocusService.enabled,
            transient: false,
            resident: false,
            image: "",
            actions: [],
            hints: ({})
        }

        root.lastWritten[nid] = snap

        var rec = NotificationStore.append(snap)

        root.applyRecord(rec)

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

        sendProcess.running = true
    }

    Component.onCompleted: {
        console.log("NotificationService loaded")
    }
}
