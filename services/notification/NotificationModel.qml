import QtQuick

import "NotifUtils.js" as NotifUtils

// View state for notification sections: the conversations ListModel
// plus the in-memory group/message maps rebuilt by replay().
// Plain component — instantiated once by the NotificationService
// facade, which owns the server and the disk store.
Item {
    id: model

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

    property bool loadDone: false
    property var pendingLive: []
    property var seenSeq: ({})

    // Replay batching: while true, row syncs and revision bumps are
    // deferred so rebuilding state from history does not churn the
    // ListModel once per record. replay() applies one sweep at the end.
    property bool batchMode: false

    // ---- record application --------------------------------------

    function applyRecord(rec) {
        if (!model.loadDone) {
            model.pendingLive.push(rec)
            return
        }

        if (rec.seq && model.seenSeq[rec.seq])
            return

        if (rec.seq)
            model.seenSeq[rec.seq] = true

        model.applyRecordNow(rec)
    }

    function applyRecordNow(rec) {
        if (!rec || !rec.type)
            return

        if (rec.type === "media") {
            model.applyMedia(rec)
            return
        }

        if (rec.type === "rename") {
            model.applyRename(rec.from, rec.to)
            return
        }

        if (rec.type === "close") {
            model.applyClose(rec)
            return
        }

        if (rec.type !== "new" && rec.type !== "update")
            return

        var key = model.nidKey[rec.id]

        // Notification ids restart at 1 with every shell session while
        // nidKey rebuilds from on-disk history, so a `new` record for an
        // already-mapped id can only mean the id was reused by a newer
        // generation. Drop the stale mapping so the message starts its
        // own section instead of mixing into the old notification's
        // group (e.g. a fresh qBittorrent toast landing inside an old
        // Firefox chat).
        if (rec.type === "new" && key) {
            delete model.nidKey[rec.id]
            delete model.lastMsgByNid[rec.id]
            key = ""
        }

        if (!key)
            key = model.startGroup(rec)

        if (!model.groups[key])
            return

        if (rec.type === "new") {
            model.appendMessage(key, rec)
        } else {
            var last = model.lastMsgByNid[rec.id]
            var raw = String(rec.body || "")

            if (
                last &&
                (String(last.raw !== undefined ? last.raw : last.body) !== raw ||
                 String(last.summary) !== String(rec.summary || ""))
            ) {
                model.appendMessage(key, rec)
            } else if (last) {
                // Same message, changed metadata (e.g. image added):
                // patch in place, keep its original time.
                var parsed = NotifUtils.parseSender(raw)

                last.raw = raw
                last.sender = parsed.sender
                last.body = parsed.text
                last.summary = String(rec.summary || "")
                last.urgency = String(rec.urgency || "normal")
            }
        }

        if (!model.batchMode) {
            model.syncRow(key)
            model.revision++
        }
    }

    function startGroup(rec) {
        var key = NotifUtils.groupKey(rec)

        model.nidKey[rec.id] = key

        if (!model.groups[key]) {
            var g = {
                key: key,
                app: String(rec.app || ""),
                title: NotifUtils.groupTitle(rec),
                desktopEntry: String(rec.desktopEntry || ""),
                appIcon: String(rec.appIcon || ""),
                preview: "",
                msgCount: 0,
                ts: rec.ts || Date.now(),
                collapsed: false,
                highPriority: NotifUtils.looksLikeCall(rec),
                avatarAsset: "",
                messages: []
            }

            model.groups[key] = g
            model.ensureRow(g)
        }

        return key
    }

    function appendMessage(key, rec) {
        var g = model.groups[key]

        if (!g)
            return null

        var last = model.lastMsgByNid[rec.id]
        var raw = String(rec.body || "")
        var parsed = NotifUtils.parseSender(raw)

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

        model.msgIndex[rec.seq] = { key: key, msg: msg }
        model.lastMsgByNid[rec.id] = msg

        return msg
    }

    function applyMedia(rec) {
        var asset = rec.resolvedAsset || rec.asset || ""

        // Small square images are chat profile pictures: they
        // belong on the section avatar, not in the message list.
        if (NotifUtils.isAvatarImage(rec.w, rec.h)) {
            var akey = model.nidKey[rec.id]

            if (akey && model.groups[akey]) {
                model.groups[akey].avatarAsset = asset

                if (!model.batchMode)
                    model.syncRow(akey)
            }

            if (!model.batchMode)
                model.revision++

            return
        }

        var slot = model.msgIndex[rec.ref]
        var msg = slot ? slot.msg : model.lastMsgByNid[rec.id]

        if (!msg)
            return

        msg.asset = asset
        msg.hasAsset = msg.asset !== ""

        if (!model.batchMode)
            model.revision++
    }

    function applyRename(from, to) {
        if (!from || !to)
            return

        for (var key in model.groups) {
            var g = model.groups[key]

            if (g.avatarAsset === from) {
                g.avatarAsset = to

                if (!model.batchMode)
                    model.syncRow(key)
            }

            var msgs = g.messages

            for (var i = 0; i < msgs.length; i++) {
                if (msgs[i].asset === from)
                    msgs[i].asset = to
            }
        }

        if (!model.batchMode)
            model.revision++
    }

    function applyClose(rec) {
        var key = model.nidKey[rec.id]

        if (!key || !model.groups[key])
            return

        var msgs = model.groups[key].messages

        for (var i = 0; i < msgs.length; i++)
            msgs[i].closed = true

        if (!model.batchMode)
            model.revision++
    }

    // ---- replay --------------------------------------------------

    function replay(records, cutoff) {
        // Idempotent: rebuild view state from the full record list.
        model.conversations.clear()
        model.groups = ({})
        model.msgIndex = ({})
        model.lastMsgByNid = ({})
        model.nidKey = ({})
        model.seenSeq = ({})

        model.batchMode = true

        for (var i = 0; i < records.length; i++) {
            var rec = records[i]

            if (!rec || !rec.type)
                continue

            if (rec.ts && rec.ts < cutoff)
                continue

            if (rec.seq)
                model.seenSeq[rec.seq] = true

            model.applyRecordNow(rec)
        }

        model.loadDone = true

        // Live records that raced the load.
        var pending = model.pendingLive

        model.pendingLive = []

        for (i = 0; i < pending.length; i++) {
            var p = pending[i]

            if (p.seq && model.seenSeq[p.seq])
                continue

            if (p.seq)
                model.seenSeq[p.seq] = true

            model.applyRecordNow(p)
        }

        model.batchMode = false

        for (var key in model.groups)
            model.groups[key].collapsed =
                model.groups[key].messages.length > model.collapseThreshold

        for (key in model.groups)
            model.syncRow(key)

        model.revision++
    }

    // ---- view model helpers --------------------------------------

    function ensureRow(g) {
        model.conversations.insert(0, {
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
        for (var i = 0; i < model.conversations.count; i++) {
            if (model.conversations.get(i).key === key)
                return i
        }

        return -1
    }

    function syncRow(key) {
        var g = model.groups[key]

        if (!g)
            return

        var idx = model.rowIndex(key)

        if (idx < 0) {
            model.ensureRow(g)
            idx = model.rowIndex(key)
        }

        if (idx < 0)
            return

        var last = g.messages.length > 0
            ? g.messages[g.messages.length - 1]
            : null

        g.msgCount = g.messages.length
        g.preview = last
            ? NotifUtils.previewText(
                  last.sender
                      ? last.sender + ": " + last.body
                      : (last.body || last.summary)
              )
            : ""

        model.conversations.setProperty(idx, "app", g.app)
        model.conversations.setProperty(idx, "title", g.title)
        model.conversations.setProperty(idx, "desktopEntry", g.desktopEntry)
        model.conversations.setProperty(idx, "appIcon", g.appIcon)
        model.conversations.setProperty(idx, "preview", g.preview)
        model.conversations.setProperty(idx, "msgCount", g.msgCount)
        model.conversations.setProperty(idx, "ts", g.ts)
        model.conversations.setProperty(idx, "collapsed", g.collapsed)
        model.conversations.setProperty(idx, "highPriority", !!g.highPriority)
        model.conversations.setProperty(idx, "avatarAsset", g.avatarAsset || "")

        if (idx > 0)
            model.conversations.move(idx, 0, 1)
    }

    function messagesFor(key) {
        var g = model.groups[key]

        return g ? g.messages : []
    }

    function toggleGroup(key) {
        var g = model.groups[key]

        if (!g)
            return

        g.collapsed = !g.collapsed

        var idx = model.rowIndex(key)

        if (idx >= 0)
            model.conversations.setProperty(idx, "collapsed", g.collapsed)
    }

    // View-only removal: the disk log keeps everything.
    function removeGroup(key) {
        var g = model.groups[key]

        if (g) {
            for (var i = 0; i < g.messages.length; i++) {
                var m = g.messages[i]

                delete model.msgIndex[m.seq]

                if (model.lastMsgByNid[m.nid] === m)
                    delete model.lastMsgByNid[m.nid]

                if (model.nidKey[m.nid] === key)
                    delete model.nidKey[m.nid]
            }

            delete model.groups[key]
        }

        var idx = model.rowIndex(key)

        if (idx >= 0)
            model.conversations.remove(idx, 1)

        model.revision++
    }

    function clear() {
        model.conversations.clear()
        model.groups = ({})
        model.msgIndex = ({})
        model.lastMsgByNid = ({})
        model.nidKey = ({})
        model.revision++
    }
}
